import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:website/api/api_client.dart';
import 'package:website/api/session.dart';
import 'package:website/pages/coach/coach_live_page.dart';
import 'package:website/pages/coach/coach_matches_page.dart';

http.Response _json(int status, Object? body) =>
    http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json'});

Map<String, dynamic> _goal(int id, {String team = 'Eastgate', String status = 'pending', bool mine = false}) => {
      'id': id,
      'team': {'id': mine ? 8 : 21, 'name': team},
      'points': 1,
      'minute': 10 + id,
      'player': null,
      'status': status,
      'addedBy': {'id': 1, 'name': mine ? 'Thabo' : 'Other Coach'},
      'canConfirm': !mine && status != 'confirmed',
      'canDispute': !mine && status == 'pending',
      'canDelete': mine,
    };

class _Backend {
  String status = 'live';
  List<Map<String, dynamic>> goals = [_goal(1)];
  http.Response? startError;
  final seen = <http.Request>[];

  Map<String, dynamic> get fixture => {
        'id': 5,
        'matchDate': DateTime.now().add(const Duration(minutes: 20)).toUtc().toIso8601String(),
        'status': status,
        'matchType': 'friendly',
        'homeTeam': {'id': 8, 'name': 'PG Football', 'school': {'id': 1, 'name': 'Protea Glen'}},
        'awayTeam': {'id': 21, 'name': 'EG Football', 'school': {'id': 2, 'name': 'Eastgate'}},
      };

  Map<String, dynamic> get match {
    int count(int team, String s) => goals.where((g) => g['team']['id'] == team && g['status'] == s).length;
    return {
      'fixture': fixture,
      'goals': goals,
      'score': {'home': count(8, 'confirmed'), 'away': count(21, 'confirmed')},
      'pending': {'home': count(8, 'pending'), 'away': count(21, 'pending')},
    };
  }

  http.Response handle(http.Request r) {
    seen.add(r);
    final path = r.url.path;
    if (path == '/api/auth/login') {
      return _json(200, {
        'accessToken': 'A',
        'refreshToken': 'R',
        'user': {'id': 7, 'role': 'coach', 'firstName': 'Thabo', 'team': {'id': 8, 'name': 'PG Football'}},
      });
    }
    if (path == '/api/teams/8/roster') {
      return _json(200, {'roster': [{'userId': 11, 'name': 'Pat Player', 'status': 'active'}]});
    }
    if (path == '/api/fixtures') {
      return _json(200, {'fixtures': r.url.queryParameters['status'] == 'cancelled' ? [] : [fixture]});
    }
    if (path == '/api/fixtures/5/goals' && r.method == 'GET') return _json(200, match);
    if (path == '/api/fixtures/5/start') {
      if (startError != null) return startError!;
      status = 'live';
      return _json(200, match);
    }
    if (path == '/api/fixtures/5/goals' && r.method == 'POST') {
      goals = [...goals, _goal(goals.length + 1, team: 'Protea Glen', mine: true)];
      return _json(201, match);
    }
    final action = RegExp(r'^/api/fixtures/5/goals/(\d+)/(confirm|dispute)$').firstMatch(path);
    if (action != null) {
      final i = goals.indexWhere((g) => g['id'] == int.parse(action.group(1)!));
      goals[i] = _goal(goals[i]['id'] as int, status: action.group(2) == 'confirm' ? 'confirmed' : 'disputed');
      return _json(200, match);
    }
    if (path == '/api/fixtures/5/finish') {
      status = 'finished';
      return _json(200, match);
    }
    return _json(404, {'error': {'code': 'NOT_FOUND', 'message': 'no'}});
  }

  Iterable<http.Request> sent(String method, String path) => seen.where((r) => r.method == method && r.url.path == path);
}

Future<_Backend> _pump(WidgetTester tester, {_Backend? backend, bool matchesPage = false}) async {
  tester.view.physicalSize = const Size(1400, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final b = backend ?? _Backend();
  final session = Session(ApiClient(baseUrl: 'http://api.test', httpClient: MockClient((r) async => b.handle(r))));
  await session.login('coach@x.com', 'Passw0rdOK');
  await tester.pumpWidget(SessionScope(
    session: session,
    child: MaterialApp(
      onGenerateRoute: (settings) => MaterialPageRoute<void>(
        settings: matchesPage ? settings : const RouteSettings(name: '/coach/live?fixture=5'),
        builder: (_) => matchesPage && settings.name == '/' ? const CoachMatchesPage() : const CoachLivePage(),
      ),
    ),
  ));
  await tester.pumpAndSettle();
  return b;
}

/// Takes the page down so its polling timer stops before the test ends.
Future<void> _close(WidgetTester tester) => tester.pumpWidget(const SizedBox());

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

String _score(WidgetTester tester) => tester.widget<Text>(find.byKey(const ValueKey('score'))).data!;

void main() {
  testWidgets('a pending score shows but does not count until confirmed', (tester) async {
    final b = await _pump(tester);
    expect(_score(tester), '0 - 0');
    expect(find.text('1 waiting'), findsOneWidget);
    await _tap(tester, find.text('Confirm'));
    expect(b.sent('POST', '/api/fixtures/5/goals/1/confirm'), hasLength(1));
    expect(_score(tester), '0 - 1');
    expect(find.text('CONFIRMED'), findsOneWidget);
    await _close(tester);
  });

  testWidgets('disputing sends the reason', (tester) async {
    final b = await _pump(tester);
    await _tap(tester, find.text('Dispute'));
    await tester.enterText(find.widgetWithText(TextField, 'Why? (optional)'), 'Offside');
    await _tap(tester, find.text('Dispute score'));
    expect(jsonDecode(b.sent('POST', '/api/fixtures/5/goals/1/dispute').single.body), {'reason': 'Offside'});
    expect(find.text('DISPUTED'), findsOneWidget);
    await _close(tester);
  });

  testWidgets('adding a score sends the team, minute and points', (tester) async {
    final b = await _pump(tester);
    await tester.enterText(find.widgetWithText(TextField, 'Minute'), '23');
    await _tap(tester, find.text('ADD SCORE'));
    expect(jsonDecode(b.sent('POST', '/api/fixtures/5/goals').single.body), {'teamId': 8, 'points': 1, 'minute': 23});
    expect(find.text('Remove'), findsOneWidget);
    await _close(tester);
  });

  testWidgets('a minute over 200 is refused', (tester) async {
    final b = await _pump(tester);
    await tester.enterText(find.widgetWithText(TextField, 'Minute'), '300');
    await _tap(tester, find.text('ADD SCORE'));
    expect(find.text('The minute must be between 0 and 200.'), findsOneWidget);
    expect(b.sent('POST', '/api/fixtures/5/goals'), isEmpty);
    await _close(tester);
  });

  testWidgets('the page picks up the other coach\'s changes by itself', (tester) async {
    final b = await _pump(tester);
    b.goals = [_goal(1, status: 'confirmed'), _goal(2, status: 'confirmed')];
    await tester.pump(livePollInterval);
    await tester.pumpAndSettle();
    expect(_score(tester), '0 - 2');
    await _close(tester);
  });

  testWidgets('full time asks first and warns about pending scores', (tester) async {
    final b = await _pump(tester);
    await _tap(tester, find.text('FULL TIME'));
    expect(find.textContaining('waiting for confirmation (1)'), findsOneWidget);
    await _tap(tester, find.text('Keep playing'));
    expect(b.sent('POST', '/api/fixtures/5/finish'), isEmpty);

    await _tap(tester, find.widgetWithText(InkWell, 'FULL TIME').first);
    await _tap(tester, find.text('End match'));
    expect(b.sent('POST', '/api/fixtures/5/finish'), hasLength(1));
    expect(find.text('ADD A SCORE'), findsNothing);
    await _close(tester);
  });

  testWidgets('a match is started from the page, and too early is explained', (tester) async {
    final b = _Backend()
      ..status = 'scheduled'
      ..goals = []
      ..startError = _json(409, {'error': {'code': 'TOO_EARLY', 'message': 'x'}});
    await _pump(tester, backend: b);
    await _tap(tester, find.text('START MATCH'));
    expect(find.text('You can start the match from 60 minutes before kick-off.'), findsOneWidget);
    b.startError = null;
    await _tap(tester, find.text('START MATCH'));
    expect(find.text('LIVE'), findsOneWidget);
    expect(find.text('ADD A SCORE'), findsOneWidget);
    await _close(tester);
  });

  testWidgets('My Matches opens scoring for a match about to start', (tester) async {
    final b = _Backend()..status = 'scheduled';
    await _pump(tester, backend: b, matchesPage: true);
    await _tap(tester, find.text('Start scoring'));
    expect(find.byType(CoachLivePage), findsOneWidget);
    await _close(tester);
  });
}
