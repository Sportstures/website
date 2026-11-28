import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:website/api/api_client.dart';
import 'package:website/api/session.dart';
import 'package:website/data/match_store.dart';
import 'package:website/main.dart';
import 'package:website/pages/competitions/competition_page.dart';
import 'package:website/pages/competitions/competitions_page.dart';
import 'package:website/widgets/site/filter_controls.dart';

http.Response _json(int status, Object? body) =>
    http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json'});

Map<String, dynamic> _competition(int id, String name, String status, {String sport = 'Netball', String? leader}) => {
      'id': id,
      'name': name,
      'season': '2026',
      'sport': {'id': 1, 'name': sport},
      'status': status,
      'region': 'Gauteng',
      'ageGroup': 'U/16',
      'teams': 4,
      'roundsPlayed': 3,
      'totalRounds': 6,
      'leader': leader == null ? null : {'name': leader},
      'rules': {'pointsWin': 3, 'pointsDraw': 1, 'pointsLoss': 0, 'tiebreakers': ['difference'], 'custom': false},
    };

Map<String, dynamic> _fixture(int id, int days, {int? home, int? away}) => {
      'id': id,
      'matchDate': DateTime.now().add(Duration(days: days)).toUtc().toIso8601String(),
      'status': home == null ? 'scheduled' : 'finished',
      'homeTeam': {'id': 1, 'name': 'A', 'school': {'name': 'Alpha High $id'}},
      'awayTeam': {'id': 2, 'name': 'B', 'school': {'name': 'Bravo High'}},
      'score': home == null ? null : {'home': home, 'away': away},
    };

class _Backend {
  bool down = false;
  final seen = <http.Request>[];

  http.Response handle(http.Request r) {
    seen.add(r);
    if (down) return _json(500, {'error': {'code': 'INTERNAL', 'message': 'boom'}});
    final path = r.url.path;
    if (path == '/api/competitions') {
      return _json(200, {
        'competitions': [
          _competition(1, 'Netball League', 'ongoing', leader: 'Eastgate College'),
          _competition(2, 'Football Cup', 'completed', sport: 'Football', leader: 'Protea Glen'),
          _competition(3, 'Summer Series', 'upcoming'),
        ],
      });
    }
    if (path == '/api/competitions/1/standings') {
      return _json(200, {'competition': _competition(1, 'Netball League', 'ongoing'), 'standings': []});
    }
    if (path == '/api/fixtures') {
      return _json(200, {'fixtures': [_fixture(1, 4), _fixture(2, -3, home: 30, away: 20), _fixture(3, -6)]});
    }
    return _json(404, {'error': {'code': 'NOT_FOUND', 'message': 'no'}});
  }

  ApiClient client() => ApiClient(baseUrl: 'http://api.test', httpClient: MockClient((r) async => handle(r)));
}

Future<_Backend> _pump(WidgetTester tester, Widget page, {_Backend? backend, String? route}) async {
  tester.view.physicalSize = const Size(1400, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final b = backend ?? _Backend();
  await tester.pumpWidget(SessionScope(
    session: Session(b.client()),
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

void main() {
  testWidgets('lists every competition without logging in', (tester) async {
    final b = await _pump(tester, const CompetitionsPage());
    expect(find.text('Netball League'), findsOneWidget);
    expect(find.text('Leader: Eastgate College'), findsOneWidget);
    expect(find.text('Champion: Protea Glen'), findsOneWidget);
    expect(find.text('No results yet'), findsOneWidget);
    expect(b.seen.every((r) => !r.headers.containsKey('Authorization')), isTrue);
  });

  testWidgets('the tabs and the search narrow the list', (tester) async {
    await _pump(tester, const CompetitionsPage());
    await _tap(tester, find.textContaining(RegExp(r'completed \(1\)', caseSensitive: false)));
    expect(find.text('Football Cup'), findsOneWidget);
    expect(find.text('Netball League'), findsNothing);
    await tester.enterText(find.descendant(of: find.byType(FilterSearchField), matching: find.byType(EditableText)), 'netball');
    await _tap(tester, find.text('FILTER'));
    expect(find.text('No competitions match your filters.'), findsOneWidget);
    await _tap(tester, find.text('RESET FILTERS'));
    expect(find.text('Summer Series'), findsOneWidget);
  });

  testWidgets('a failure can be retried', (tester) async {
    final b = _Backend()..down = true;
    await _pump(tester, const CompetitionsPage(), backend: b);
    b.down = false;
    await _tap(tester, find.text('TRY AGAIN'));
    expect(find.text('Netball League'), findsOneWidget);
  });

  testWidgets('a competition page lists upcoming matches and results, leaving out unplayed past ones', (tester) async {
    final b = await _pump(tester, const CompetitionPage(), route: '/competition?id=1');
    expect(find.text('Alpha High 1 vs Bravo High'), findsOneWidget);
    expect(find.text('30 - 20'), findsOneWidget);
    expect(find.text('Alpha High 3 vs Bravo High'), findsNothing);
    expect(b.seen.singleWhere((r) => r.url.path == '/api/fixtures').url.queryParameters['competitionId'], '1');
  });

  testWidgets('the footer leads to the competitions page', (tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final api = _Backend().client();
    await tester.pumpWidget(TobunApp(session: Session(api), matches: MatchStore.sample()));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Competitions'), 400, scrollable: find.byType(Scrollable).first);
    await _tap(tester, find.text('Competitions'));
    expect(find.byType(CompetitionsPage), findsOneWidget);
  });
}
