import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:website/api/api_client.dart';
import 'package:website/api/session.dart';
import 'package:website/pages/account/account_page.dart';
import 'package:website/pages/coach/coach_matches_page.dart';
import 'package:website/pages/coach/coach_team_details_page.dart';

http.Response _json(int status, Object? body) =>
    http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json'});

http.Response _error(int status, String code) => _json(status, {'error': {'code': code, 'message': code}});

class _Backend {
  Map<String, dynamic> user = {
    'id': 7,
    'role': 'coach',
    'firstName': 'Thabo',
    'lastName': 'Mokoena',
    'email': 'thabo@school.co.za',
    'phone': null,
    'dateOfBirth': '1986-07-21',
    'gender': 'male',
    'profile': {'team': {'id': 8, 'name': 'PG Football'}},
  };
  http.Response? passwordError;
  final seen = <http.Request>[];

  http.Response handle(http.Request r) {
    seen.add(r);
    final path = r.url.path;
    if (path == '/api/auth/login') return _json(200, {'accessToken': 'A', 'refreshToken': 'R', 'user': user});
    if (path == '/api/auth/me') return _json(200, {'user': user});
    if (path == '/api/me/profile') {
      user = {...user, ...jsonDecode(r.body) as Map<String, dynamic>};
      return _json(200, {'user': user});
    }
    if (path == '/api/me/password') return passwordError ?? _json(200, {'accessToken': 'A2', 'refreshToken': 'R2', 'user': user});
    if (path == '/api/me/email') return _json(200, {'email': 'new@school.co.za'});
    if (path == '/api/me/email/verify') {
      user = {...user, 'email': 'new@school.co.za'};
      return _json(200, {'user': user});
    }
    if (path == '/api/teams/8' && r.method == 'GET') {
      return _json(200, {
        'team': {
          'id': 8,
          'name': 'PG Football',
          'genderCategory': 'boys',
          'description': 'Old words',
          'location': null,
          'foundedYear': 1999,
          'sport': {'id': 4, 'name': 'Football'},
          'school': {'id': 3, 'name': 'Protea Glen', 'province': 'Gauteng', 'town': 'Soweto'},
        },
      });
    }
    if (r.method == 'PATCH' && (path == '/api/teams/8' || path == '/api/schools/3')) return _json(200, {});
    if (path == '/api/teams') return _json(200, {'teams': [{'id': 30, 'name': 'Greenwood Football', 'school': {'name': 'Greenwood'}}]});
    if (path == '/api/competitions') return _json(200, {'competitions': []});
    if (path == '/api/fixtures' && r.method == 'POST') return _json(201, {'fixture': {}});
    if (path == '/api/fixtures') return _json(200, {'fixtures': []});
    return _error(404, 'NOT_FOUND');
  }

  Map<String, dynamic> body(String method, String path) =>
      jsonDecode(seen.singleWhere((r) => r.method == method && r.url.path == path).body) as Map<String, dynamic>;
  Iterable<http.Request> sent(String path) => seen.where((r) => r.url.path == path);
}

Future<(_Backend, Session)> _pump(WidgetTester tester, Widget page, {_Backend? backend}) async {
  tester.view.physicalSize = const Size(1400, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final b = backend ?? _Backend();
  final session = Session(ApiClient(baseUrl: 'http://api.test', httpClient: MockClient((r) async => b.handle(r))));
  await session.login('thabo@school.co.za', 'Passw0rdOK');
  await tester.pumpWidget(SessionScope(session: session, child: MaterialApp(home: page)));
  await tester.pumpAndSettle();
  return (b, session);
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Finder _field(String key) => find.byKey(ValueKey(key));

void main() {
  group('account', () {
    testWidgets('saves only what changed and updates the name everywhere', (tester) async {
      final (b, session) = await _pump(tester, const AccountPage());
      await _tap(tester, find.text('SAVE DETAILS'));
      expect(find.text('Nothing has changed.'), findsOneWidget);
      await tester.enterText(find.widgetWithText(TextFormField, 'Thabo'), 'Tebogo');
      await _tap(tester, find.text('SAVE DETAILS'));
      expect(b.body('PATCH', '/api/me/profile'), {'firstName': 'Tebogo'});
      expect(session.user!.firstName, 'Tebogo');
      expect(session.user!.team!['id'], 8);
    });

    testWidgets('changing the password keeps this device signed in with the new tokens', (tester) async {
      final (b, session) = await _pump(tester, const AccountPage());
      await tester.enterText(_field('Current password'), 'Passw0rdOK');
      await tester.enterText(_field('New password'), 'Sipho2026');
      await tester.enterText(_field('Repeat new password'), 'Sipho2027');
      await _tap(tester, find.text('CHANGE PASSWORD').last);
      expect(find.text('The passwords do not match'), findsOneWidget);
      expect(b.sent('/api/me/password'), isEmpty);
      await tester.enterText(_field('Repeat new password'), 'Sipho2026');
      await _tap(tester, find.text('CHANGE PASSWORD').last);
      expect(b.body('PUT', '/api/me/password'), {'currentPassword': 'Passw0rdOK', 'newPassword': 'Sipho2026'});
      expect((await session.api.tokens.read())!.refreshToken, 'R2');
      expect(find.textContaining('Password changed'), findsOneWidget);
    });

    testWidgets('a wrong current password is explained', (tester) async {
      final b = _Backend()..passwordError = _error(400, 'WRONG_PASSWORD');
      await _pump(tester, const AccountPage(), backend: b);
      await tester.enterText(_field('Current password'), 'nope');
      await tester.enterText(_field('New password'), 'Sipho2026');
      await tester.enterText(_field('Repeat new password'), 'Sipho2026');
      await _tap(tester, find.text('CHANGE PASSWORD').last);
      expect(find.text('That password is not right.'), findsOneWidget);
    });

    testWidgets('the email changes only after the code', (tester) async {
      final (b, session) = await _pump(tester, const AccountPage());
      await tester.enterText(_field('New email address'), 'new@school.co.za');
      await tester.enterText(_field('Your password'), 'Passw0rdOK');
      await _tap(tester, find.text('SEND CODE'));
      expect(find.text('Current: thabo@school.co.za'), findsOneWidget);
      await tester.enterText(_field('6-digit code'), '123456');
      await _tap(tester, find.text('CONFIRM'));
      expect(b.body('POST', '/api/me/email/verify'), {'code': '123456'});
      expect(find.text('Current: new@school.co.za'), findsOneWidget);
      expect(session.user!.email, 'new@school.co.za');
    });
  });

  group('team details', () {
    testWidgets('saves only changed team fields, clearing emptied ones', (tester) async {
      final (b, _) = await _pump(tester, const CoachTeamDetailsPage());
      await tester.enterText(_field('About the team'), '');
      await tester.enterText(_field('Home ground'), 'Main Field');
      await _tap(tester, find.text('SAVE TEAM'));
      expect(b.body('PATCH', '/api/teams/8'), {'description': null, 'location': 'Main Field'});
      expect(find.text('Team details saved.'), findsOneWidget);
    });

    testWidgets('saves the school location', (tester) async {
      final (b, _) = await _pump(tester, const CoachTeamDetailsPage());
      await tester.enterText(_field('Town'), 'Protea Glen');
      await _tap(tester, find.text('SAVE LOCATION'));
      expect(b.body('PATCH', '/api/schools/3'), {'town': 'Protea Glen'});
    });

    testWidgets('an impossible year is refused', (tester) async {
      final (b, _) = await _pump(tester, const CoachTeamDetailsPage());
      await tester.enterText(_field('Year founded'), '1500');
      await _tap(tester, find.text('SAVE TEAM'));
      expect(find.text('The year must be between 1800 and 2100.'), findsOneWidget);
      expect(b.seen.where((r) => r.method == 'PATCH'), isEmpty);
    });
  });

  testWidgets('a home match can be added directly', (tester) async {
    final (b, _) = await _pump(tester, const CoachMatchesPage());
    await _tap(tester, find.text('Add a match'));
    await _tap(tester, find.text('Add match'));
    expect(find.text('Choose the team you are playing.'), findsOneWidget);
    await _tap(tester, find.text('Pick'));
    await _tap(tester, find.text('Match date'));
    await _tap(tester, find.text('OK'));
    await _tap(tester, find.text('Add match'));
    final body = b.body('POST', '/api/fixtures');
    expect(body['homeTeamId'], 8);
    expect(body['awayTeamId'], 30);
    expect(body['matchType'], 'friendly');
    expect(body.containsKey('competitionId'), isFalse);
    expect(find.text('Match against Greenwood added.'), findsOneWidget);
  });
}
