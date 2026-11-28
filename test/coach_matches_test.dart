import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:website/api/api_client.dart';
import 'package:website/api/session.dart';
import 'package:website/pages/coach/coach_matches_page.dart';

http.Response _json(int status, Object? body) =>
    http.Response(body == null ? '' : jsonEncode(body), status, headers: {'content-type': 'application/json'});

Map<String, dynamic> _fixture(int id, String opponent, {String status = 'scheduled', int days = 5, bool lineup = false}) => {
      'id': id,
      'matchDate': DateTime.now().add(Duration(days: days)).toUtc().toIso8601String(),
      'status': status,
      'venue': 'Main Field',
      'matchType': 'friendly',
      'competition': null,
      'homeTeam': {'id': 8, 'name': 'PG Football', 'school': {'id': 1, 'name': 'Protea Glen'}},
      'awayTeam': {'id': 20 + id, 'name': '$opponent Football', 'school': {'id': 20 + id, 'name': opponent}},
      'lineupSubmitted': {'home': lineup, 'away': false},
    };

class _Backend {
  List<Map<String, dynamic>> fixtures = [
    _fixture(1, 'Eastgate College'),
    _fixture(2, 'Northview High', status: 'postponed', days: 9),
    _fixture(3, 'Westbury High', status: 'cancelled', days: 12),
  ];
  Map<String, dynamic>? lineup;
  http.Response? patchError;
  final seen = <http.Request>[];

  http.Response handle(http.Request r) {
    seen.add(r);
    final path = r.url.path;
    final q = r.url.queryParameters;
    if (path == '/api/auth/login') {
      return _json(200, {
        'accessToken': 'A',
        'refreshToken': 'R',
        'user': {'id': 7, 'role': 'coach', 'firstName': 'Thabo', 'team': {'id': 8, 'name': 'PG Football'}},
      });
    }
    if (path == '/api/fixtures') {
      final cancelled = q['status'] == 'cancelled';
      return _json(200, {'fixtures': [for (final f in fixtures) if ((f['status'] == 'cancelled') == cancelled) f]});
    }
    final one = RegExp(r'^/api/fixtures/(\d+)$').firstMatch(path);
    if (one != null && r.method == 'PATCH') {
      if (patchError != null) return patchError!;
      final f = fixtures.firstWhere((x) => x['id'] == int.parse(one.group(1)!));
      f.addAll(jsonDecode(r.body) as Map<String, dynamic>);
      return _json(200, {'fixture': f});
    }
    if (path == '/api/teams/8/roster') {
      return _json(200, {
        'roster': [
          {'userId': 11, 'name': 'Pat Player', 'status': 'active', 'jerseyNumber': 4, 'position': 'Defender'},
          {'userId': 12, 'name': 'Quinn Player', 'status': 'active', 'jerseyNumber': 9},
        ],
      });
    }
    if (path == '/api/fixtures/1/lineups') {
      return _json(200, {'fixtureId': 1, 'home': {'teamId': 8, 'lineup': lineup}, 'away': {'teamId': 21, 'lineup': null}});
    }
    if (path == '/api/fixtures/1/lineups/8') {
      if (r.method == 'DELETE') {
        lineup = null;
        return http.Response('', 204);
      }
      return _json(200, {'lineup': {}});
    }
    return _json(404, {'error': {'code': 'NOT_FOUND', 'message': 'no'}});
  }

  Iterable<http.Request> sent(String method, String path) => seen.where((r) => r.method == method && r.url.path == path);
}

Future<_Backend> _pump(WidgetTester tester, {_Backend? backend}) async {
  tester.view.physicalSize = const Size(1400, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final b = backend ?? _Backend();
  final session = Session(ApiClient(baseUrl: 'http://api.test', httpClient: MockClient((r) async => b.handle(r))));
  await session.login('coach@x.com', 'Passw0rdOK');
  await tester.pumpWidget(SessionScope(session: session, child: const MaterialApp(home: CoachMatchesPage())));
  await tester.pumpAndSettle();
  return b;
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Finder _inRow(int id, String text) => find.descendant(of: find.byKey(ValueKey('fixture-$id')), matching: find.text(text));

Finder _inPlayer(int id, String text) => find.descendant(of: find.byKey(ValueKey('player-$id')), matching: find.text(text));

void main() {
  testWidgets('lists my team\'s matches with the actions each status allows', (tester) async {
    final b = await _pump(tester);
    expect(b.sent('GET', '/api/fixtures').first.url.queryParameters['teamId'], '8');
    expect(find.text('vs Eastgate College'), findsOneWidget);
    expect(_inRow(1, 'Postpone'), findsOneWidget);
    expect(_inRow(1, 'Set lineup'), findsOneWidget);
    expect(_inRow(2, 'Set new date'), findsOneWidget);
    expect(_inRow(2, 'Postpone'), findsNothing);
    expect(_inRow(3, 'Put back on'), findsOneWidget);
    expect(_inRow(3, 'Set lineup'), findsNothing);
    expect(_inRow(3, 'Cancel match'), findsNothing);
  });

  testWidgets('cancelling asks first', (tester) async {
    final b = await _pump(tester);
    await _tap(tester, _inRow(1, 'Cancel match'));
    await _tap(tester, find.text('Keep it'));
    expect(b.sent('PATCH', '/api/fixtures/1'), isEmpty);

    await _tap(tester, _inRow(1, 'Cancel match'));
    await _tap(tester, find.widgetWithText(FilledButton, 'Cancel match'));
    expect(jsonDecode(b.sent('PATCH', '/api/fixtures/1').single.body), {'status': 'cancelled'});
    expect(find.text('Match against Eastgate College cancelled.'), findsOneWidget);
  });

  testWidgets('postponing sends only the status', (tester) async {
    final b = await _pump(tester);
    await _tap(tester, _inRow(1, 'Postpone'));
    await _tap(tester, find.text('Postpone match'));
    expect(jsonDecode(b.sent('PATCH', '/api/fixtures/1').single.body), {'status': 'postponed'});
    expect(_inRow(1, 'Set new date'), findsOneWidget);
  });

  testWidgets('editing sends only what changed', (tester) async {
    final b = await _pump(tester);
    await _tap(tester, _inRow(1, 'Edit'));
    await tester.enterText(find.widgetWithText(TextField, 'Venue'), 'New Ground');
    await _tap(tester, find.text('Save changes'));
    expect(jsonDecode(b.sent('PATCH', '/api/fixtures/1').single.body), {'venue': 'New Ground'});
  });

  testWidgets('putting a cancelled match back on makes it scheduled', (tester) async {
    final b = await _pump(tester);
    await _tap(tester, _inRow(3, 'Put back on'));
    await _tap(tester, find.text('Save changes'));
    expect(jsonDecode(b.sent('PATCH', '/api/fixtures/3').single.body), {'status': 'scheduled'});
    expect(find.text('Match is back on.'), findsOneWidget);
  });

  testWidgets('a locked match is explained', (tester) async {
    final b = _Backend()..patchError = _json(409, {'error': {'code': 'FIXTURE_LOCKED', 'message': 'x'}});
    await _pump(tester, backend: b);
    await _tap(tester, _inRow(1, 'Postpone'));
    await _tap(tester, find.text('Postpone match'));
    expect(find.text('That match has started or finished, so it can no longer be changed.'), findsOneWidget);
  });

  testWidgets('choosing a lineup sends starters, bench and formation', (tester) async {
    final b = await _pump(tester);
    await _tap(tester, _inRow(1, 'Set lineup'));
    await _tap(tester, find.text('Save lineup'));
    expect(find.text('Pick at least one starter.'), findsOneWidget);

    await _tap(tester, _inPlayer(11, 'Start'));
    await _tap(tester, _inPlayer(12, 'Bench'));
    expect(find.text('1 starting · 1 on the bench'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Formation (optional)'), '4-4-2');
    await _tap(tester, find.text('Save lineup'));

    expect(jsonDecode(b.sent('PUT', '/api/fixtures/1/lineups/8').single.body), {
      'formation': '4-4-2',
      'starters': [{'userId': 11}],
      'bench': [{'userId': 12}],
    });
    expect(find.text('Lineup saved.'), findsOneWidget);
  });

  testWidgets('a submitted lineup is shown again and can be withdrawn', (tester) async {
    final b = _Backend()
      ..fixtures = [_fixture(1, 'Eastgate College', lineup: true)]
      ..lineup = {'formation': '4-3-3', 'starters': [{'userId': 12}], 'bench': []};
    await _pump(tester, backend: b);
    await _tap(tester, _inRow(1, 'Edit lineup'));
    expect(find.text('1 starting · 0 on the bench'), findsOneWidget);
    expect(find.text('4-3-3'), findsOneWidget);
    await _tap(tester, find.text('Withdraw lineup'));
    expect(b.sent('DELETE', '/api/fixtures/1/lineups/8'), hasLength(1));
    expect(find.text('Lineup withdrawn.'), findsOneWidget);
  });
}
