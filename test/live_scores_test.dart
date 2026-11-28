import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:website/api/api_client.dart';
import 'package:website/data/match_store.dart';
import 'package:website/pages/fixtures/widgets/live_now_section.dart';

http.Response _json(Object? body) => http.Response(jsonEncode(body), 200, headers: {'content-type': 'application/json'});

Map<String, dynamic> _fixture(String status) => {
      'id': 5,
      'matchDate': '2026-11-28T13:00:00.000Z',
      'status': status,
      'homeTeam': {'id': 8, 'name': 'PG Football', 'school': {'id': 1, 'name': 'Protea Glen'}},
      'awayTeam': {'id': 21, 'name': 'EG Football', 'school': {'id': 2, 'name': 'Eastgate'}},
    };

Map<String, dynamic> _goal(int id, String status, String player) => {
      'id': id,
      'team': {'id': 8, 'name': 'Protea Glen'},
      'player': {'id': id, 'name': player},
      'minute': 10 * id,
      'status': status,
    };

class _Backend {
  bool live = true;
  int home = 1;
  bool down = false;
  final seen = <http.Request>[];

  http.Response handle(http.Request r) {
    seen.add(r);
    if (down) return http.Response('oops', 500);
    final path = r.url.path;
    if (path == '/api/fixtures' && r.url.queryParameters['status'] == 'live') {
      return _json({'fixtures': live ? [_fixture('live')] : []});
    }
    if (path == '/api/fixtures') return _json({'fixtures': []});
    if (path == '/api/fixtures/5/goals') {
      return _json({
        'fixture': _fixture('live'),
        'goals': [_goal(1, 'confirmed', 'Pat Player'), _goal(2, 'pending', 'Not Yet')],
        'score': {'home': home, 'away': 0},
        'pending': {'home': 1, 'away': 0},
      });
    }
    return http.Response('{}', 404);
  }
}

Future<_Backend> _pump(WidgetTester tester, {_Backend? backend, MatchStore? store}) async {
  final b = backend ?? _Backend();
  final matches = store ?? MatchStore.api(ApiClient(baseUrl: 'http://api.test', httpClient: MockClient((r) async => b.handle(r))));
  await tester.pumpWidget(MatchScope(
    store: matches,
    child: const MaterialApp(home: Scaffold(body: SingleChildScrollView(child: LiveNowSection()))),
  ));
  await tester.pumpAndSettle();
  return b;
}

Future<void> _next(WidgetTester tester) async {
  await tester.pump(liveScoresInterval);
  await tester.pumpAndSettle();
}

Future<void> _close(WidgetTester tester) => tester.pumpWidget(const SizedBox());

void main() {
  testWidgets('shows a match in progress with only confirmed scorers, without logging in', (tester) async {
    final b = await _pump(tester);
    expect(find.text('LIVE NOW'), findsOneWidget);
    expect(find.text('1 - 0'), findsOneWidget);
    expect(find.text("10' Pat Player"), findsOneWidget);
    expect(find.textContaining('Not Yet'), findsNothing);
    expect(b.seen.every((r) => !r.headers.containsKey('Authorization')), isTrue);
    await _close(tester);
  });

  testWidgets('the score updates by itself, and a failed check keeps the last one', (tester) async {
    final b = await _pump(tester);
    b.home = 2;
    await _next(tester);
    expect(find.text('2 - 0'), findsOneWidget);
    b.down = true;
    await _next(tester);
    expect(find.text('2 - 0'), findsOneWidget);
    await _close(tester);
  });

  testWidgets('when a match ends it leaves the list and the results are fetched again', (tester) async {
    final b = await _pump(tester);
    b.live = false;
    b.seen.clear();
    await _next(tester);
    expect(find.text('LIVE NOW'), findsNothing);
    expect(b.seen.any((r) => r.url.queryParameters['when'] == 'past'), isTrue);
    await _close(tester);
  });

  testWidgets('takes no space when nothing is being played', (tester) async {
    await _pump(tester, backend: _Backend()..live = false);
    expect(find.text('LIVE NOW'), findsNothing);
    expect(tester.getSize(find.byType(LiveNowSection)).height, 0);
    await _close(tester);
  });

  testWidgets('does nothing with sample data', (tester) async {
    final b = await _pump(tester, store: MatchStore.sample());
    await _next(tester);
    expect(b.seen, isEmpty);
    expect(find.text('LIVE NOW'), findsNothing);
  });
}
