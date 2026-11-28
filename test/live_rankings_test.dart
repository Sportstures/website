import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:website/api/api_client.dart';
import 'package:website/api/session.dart';
import 'package:website/data/match_store.dart';
import 'package:website/pages/rankings/rankings_page.dart';

http.Response _json(Object? body) => http.Response(jsonEncode(body), 200, headers: {'content-type': 'application/json'});

Map<String, dynamic> _row(int position, String name, {int points = 500, int? trend = 0, String type = 'schools'}) => {
      'position': position,
      'name': name,
      'detail': type == 'teams' ? 'Rugby 1st Team' : '3 sports played',
      'province': 'Gauteng',
      'points': points,
      'played': 16,
      'sportsPlayed': 3,
      'schoolsRanked': 2,
      'trend': trend,
    };

class _Backend {
  bool down = false;
  final seen = <http.Request>[];

  http.Response handle(http.Request r) {
    seen.add(r);
    if (down) return http.Response('oops', 500);
    final q = r.url.queryParameters;
    switch (r.url.path) {
      case '/api/rankings':
        final type = q['type']!;
        return _json({
          'rankings': type == 'athletes'
              ? []
              : [_row(1, 'Protea Glen', points: 1961, type: type), _row(2, 'Riverside College', trend: null)],
          'total': 14,
          'updatedAt': '2026-11-17T19:47:10.000Z',
        });
      case '/api/rankings/overview':
        return _json({
          'breakdown': [{'key': 'wins', 'label': 'Match Wins', 'weight': 0.4, 'description': 'A win earns 40 points.'}],
          'topSports': [{'label': 'Rugby 1st Team', 'school': {'name': 'Bayside High'}, 'points': 302}],
          'topRisers': [{'name': 'Lakeside Collegiate', 'trend': 2}],
          'regionLeaders': [{'province': 'Western Cape', 'leader': {'name': 'Bayside High', 'points': 640}}],
        });
      case '/api/rankings/filters':
        return _json({'seasons': [2026], 'sports': [{'id': 7, 'name': 'Rugby'}], 'ageGroups': ['U/16'], 'provinces': ['Gauteng', 'Western Cape']});
    }
    return http.Response('{}', 404);
  }

  Iterable<Map<String, String>> get asked => seen.where((r) => r.url.path == '/api/rankings').map((r) => r.url.queryParameters);
}

Future<_Backend> _pump(WidgetTester tester, {_Backend? backend}) async {
  tester.view.physicalSize = const Size(1400, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final b = backend ?? _Backend();
  final api = ApiClient(baseUrl: 'http://api.test', httpClient: MockClient((r) async => b.handle(r)));
  await tester.pumpWidget(SessionScope(
    session: Session(api),
    child: MatchScope(store: MatchStore.api(api), child: const MaterialApp(home: RankingsPage())),
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

void main() {
  testWidgets('shows the server rankings and the cards around them', (tester) async {
    final b = await _pump(tester);
    expect(b.asked.single, {'type': 'schools', 'limit': '10'});
    expect(find.text('Protea Glen'), findsOneWidget);
    expect(find.text('NEW'), findsOneWidget);
    expect(find.text('40%'), findsOneWidget);
    expect(find.text('Rugby 1st Team · Bayside High'), findsOneWidget);
    expect(find.text('Lakeside Collegiate'), findsOneWidget);
    expect(find.text('WESTERN CAPE'), findsOneWidget);
    expect(b.seen.every((r) => !r.headers.containsKey('Authorization')), isTrue);
  });

  testWidgets('the tabs ask for that kind of ranking', (tester) async {
    final b = await _pump(tester);
    await _tap(tester, find.textContaining(RegExp('teams ranking', caseSensitive: false)).first);
    expect(b.asked.last['type'], 'teams');
    expect(find.text('Rugby 1st Team'), findsWidgets);
    await _tap(tester, find.textContaining(RegExp('athletes ranking', caseSensitive: false)).first);
    expect(find.textContaining('Athlete rankings appear once'), findsOneWidget);
  });

  testWidgets('a region card shows that region\'s schools', (tester) async {
    final b = await _pump(tester);
    await _tap(tester, find.text('VIEW TOP 10'));
    expect(b.asked.last['province'], 'Western Cape');
    expect(b.asked.last['type'], 'schools');
  });

  testWidgets('full rankings asks for more rows', (tester) async {
    final b = await _pump(tester);
    await _tap(tester, find.text('VIEW FULL RANKINGS'));
    expect(b.asked.last['limit'], '100');
    expect(find.text('SHOW TOP 10'), findsOneWidget);
  });

  testWidgets('a failure is shown and can be retried', (tester) async {
    final b = _Backend()..down = true;
    await _pump(tester, backend: b);
    expect(find.text("Rankings couldn't be loaded."), findsOneWidget);
    b.down = false;
    await _tap(tester, find.text('TRY AGAIN'));
    expect(find.text('Protea Glen'), findsOneWidget);
    expect(find.text('40%'), findsOneWidget, reason: 'the side cards come back too');
  });
}
