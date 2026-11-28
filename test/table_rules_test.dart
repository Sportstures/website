import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:website/api/api_client.dart';
import 'package:website/api/session.dart';
import 'package:website/pages/coach/coach_competitions_page.dart';
import 'package:website/pages/coach/coach_match_invites_page.dart';
import 'package:website/pages/competitions/competition_page.dart';

http.Response _json(int status, Object? body) =>
    http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json'});

Map<String, dynamic> _competition(int id, String name, {bool canEdit = true, int win = 3, List<String>? order, String status = 'ongoing'}) => {
      'id': id,
      'name': name,
      'season': '2026',
      'sport': {'id': 6, 'name': 'Netball'},
      'status': status,
      'teams': 4,
      'canEdit': canEdit,
      'rules': {
        'pointsWin': win,
        'pointsDraw': 1,
        'pointsLoss': 0,
        'tiebreakers': order ?? ['difference', 'for', 'head_to_head'],
        'custom': win != 3 || order != null,
      },
    };

class _Backend {
  List<Map<String, dynamic>> competitions = [_competition(1, 'My Netball League'), _competition(2, 'Someone Else Cup', canEdit: false)];
  http.Response? createError;
  final seen = <http.Request>[];

  http.Response handle(http.Request r) {
    seen.add(r);
    final path = r.url.path;
    if (path == '/api/auth/login') {
      return _json(200, {
        'accessToken': 'A',
        'refreshToken': 'R',
        'user': {'id': 7, 'role': 'coach', 'firstName': 'Thabo', 'team': {'id': 8, 'name': 'PG Netball'}},
      });
    }
    if (path == '/api/competitions' && r.method == 'GET') return _json(200, {'competitions': competitions});
    if (path == '/api/competitions' && r.method == 'POST') return createError ?? _json(201, {'competition': _competition(3, 'New')});
    if (path == '/api/competitions/1' && r.method == 'PATCH') return _json(200, {'competition': competitions.first});
    if (path == '/api/competitions/1/standings') {
      return _json(200, {
        'competition': {'id': 1, 'name': 'My Netball League', 'season': '2026', 'rules': _competition(1, 'x', win: 2, order: ['head_to_head'])['rules']},
        'standings': [
          {'position': 1, 'team': {'id': 8, 'name': 'PG Netball', 'school': {'name': 'Protea Glen'}}, 'played': 2, 'won': 1, 'drawn': 0, 'lost': 1, 'pointsFor': 50, 'pointsAgainst': 40, 'difference': 10, 'points': 2, 'tiebreaker': 'head_to_head'},
        ],
      });
    }
    if (path == '/api/teams/8') return _json(200, {'team': {'id': 8, 'name': 'PG Netball', 'sport': {'id': 6, 'name': 'Netball'}}});
    if (path == '/api/teams') {
      return _json(200, {'teams': [{'id': 30, 'name': 'Greenwood Netball', 'school': {'name': 'Greenwood'}, 'coach': {'id': 2}}]});
    }
    if (path == '/api/match-invitations') {
      return r.method == 'GET' ? _json(200, {'invitations': [], 'total': 0}) : _json(201, {'invitation': {}});
    }
    return _json(404, {'error': {'code': 'NOT_FOUND', 'message': 'no'}});
  }

  Map<String, dynamic> body(String method, String path) =>
      jsonDecode(seen.singleWhere((r) => r.method == method && r.url.path == path).body) as Map<String, dynamic>;
}

Future<_Backend> _pump(WidgetTester tester, Widget page, {_Backend? backend, String? route}) async {
  tester.view.physicalSize = const Size(1400, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final b = backend ?? _Backend();
  final session = Session(ApiClient(baseUrl: 'http://api.test', httpClient: MockClient((r) async => b.handle(r))));
  await session.login('coach@x.com', 'Passw0rdOK');
  await tester.pumpWidget(SessionScope(
    session: session,
    child: MaterialApp(
      home: route == null ? page : null,
      onGenerateRoute: route == null ? null : (_) => MaterialPageRoute<void>(settings: RouteSettings(name: route), builder: (_) => page),
    ),
  ));
  await tester.pumpAndSettle();
  return b;
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Finder _inDialog(Finder f) => find.descendant(of: find.byType(AlertDialog), matching: f);
Finder _action(String tiebreaker, String tooltip) =>
    _inDialog(find.descendant(of: find.byKey(ValueKey('tiebreaker-$tiebreaker')), matching: find.byTooltip(tooltip)));

void main() {
  testWidgets('lists only the competitions I may edit, with their rules in words', (tester) async {
    await _pump(tester, const CoachCompetitionsPage());
    expect(find.text('My Netball League'), findsOneWidget);
    expect(find.text('Someone Else Cup'), findsNothing);
    expect(find.text('Win 3, draw 1, loss 0. Level on points: score difference, then most scored, then head-to-head.'), findsOneWidget);
  });

  testWidgets('changing points and the tiebreaker order saves them', (tester) async {
    final b = await _pump(tester, const CoachCompetitionsPage());
    await _tap(tester, find.text('Edit rules'));
    await _tap(tester, _inDialog(find.byKey(const ValueKey('Win-3'))));
    await _tap(tester, find.text('2').last);
    await _tap(tester, _action('head_to_head', 'Move up'));
    await _tap(tester, _action('for', 'Remove'));
    await _tap(tester, _inDialog(find.text('Most wins')));
    await _tap(tester, find.text('Save rules'));
    expect(b.body('PATCH', '/api/competitions/1'), {
      'pointsWin': 2,
      'pointsDraw': 1,
      'pointsLoss': 0,
      'tiebreakers': ['difference', 'head_to_head', 'wins'],
    });
    expect(find.textContaining('Rules saved for My Netball League'), findsOneWidget);
  });

  testWidgets('going back to the standard rules sends a null order', (tester) async {
    final b = _Backend()..competitions = [_competition(1, 'My Netball League', win: 5, order: ['wins'])];
    await _pump(tester, const CoachCompetitionsPage(), backend: b);
    await _tap(tester, find.text('Edit rules'));
    expect(tester.widget<IconButton>(find.ancestor(of: _action('wins', 'Remove'), matching: find.byType(IconButton)).first).onPressed, isNull,
        reason: 'the last tiebreaker cannot be removed');
    await _tap(tester, _inDialog(find.text('Use the standard rules')));
    await _tap(tester, find.text('Save rules'));
    expect(b.body('PATCH', '/api/competitions/1'), {'pointsWin': 3, 'pointsDraw': 1, 'pointsLoss': 0, 'tiebreakers': null});
  });

  testWidgets('a new competition is created for my sport', (tester) async {
    final b = await _pump(tester, const CoachCompetitionsPage());
    await _tap(tester, find.text('CREATE COMPETITION'));
    expect(find.text('Give the competition a name.'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Competition name'), 'Soweto Netball Cup');
    await _tap(tester, find.text('CREATE COMPETITION'));
    final body = b.body('POST', '/api/competitions');
    expect(body['name'], 'Soweto Netball Cup');
    expect(body['sportId'], 6);
    expect(body['season'], '${DateTime.now().year}');
    expect(body['tiebreakers'], isNull);
  });

  testWidgets('a name already in use is explained', (tester) async {
    final b = _Backend()..createError = _json(409, {'error': {'code': 'COMPETITION_EXISTS', 'message': 'x'}});
    await _pump(tester, const CoachCompetitionsPage(), backend: b);
    await tester.enterText(find.widgetWithText(TextField, 'Competition name'), 'Taken');
    await _tap(tester, find.text('CREATE COMPETITION'));
    expect(find.text('A competition with that name already exists.'), findsOneWidget);
  });

  testWidgets('the public table shows what separated teams, and the rules', (tester) async {
    await _pump(tester, const CompetitionPage(), route: '/competition?id=1');
    expect(find.text('Protea Glen'), findsOneWidget);
    expect(find.text('Decided on head-to-head'), findsOneWidget);
    expect(find.text('Win 2, draw 1, loss 0. Level on points: head-to-head.'), findsOneWidget);
  });

  testWidgets('a match invitation can count towards a competition', (tester) async {
    final b = _Backend()..competitions = [_competition(1, 'My Netball League'), _competition(4, 'Old League', status: 'completed')];
    await _pump(tester, const CoachMatchInvitesPage(), backend: b);
    await _tap(tester, find.text('Choose'));
    await _tap(tester, find.text('Choose date'));
    await _tap(tester, find.text('OK'));
    await _tap(tester, find.text('None'));
    expect(find.text('Old League'), findsNothing);
    await _tap(tester, find.text('My Netball League').last);
    await _tap(tester, find.text('SEND MATCH INVITATION'));
    expect(b.body('POST', '/api/match-invitations')['competitionId'], 1);
  });
}
