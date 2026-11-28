import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:website/api/api_client.dart';
import 'package:website/api/session.dart';
import 'package:website/pages/coach/coach_home_page.dart';
import 'package:website/pages/coach/coach_matches_page.dart';

http.Response _json(int status, Object? body) =>
    http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json'});

http.Response _error(int status, String code) => _json(status, {'error': {'code': code, 'message': code}});

Map<String, dynamic> _fixture(int id, String opponent, {bool home = true, int days = -1, int? mine, int? theirs}) {
  final me = {'id': 8, 'name': 'PG Football', 'school': {'id': 1, 'name': 'Protea Glen'}};
  final them = {'id': 20 + id, 'name': '$opponent Football', 'school': {'id': 20 + id, 'name': opponent}};
  return {
    'id': id,
    'matchDate': DateTime.now().add(Duration(days: days)).toUtc().toIso8601String(),
    'status': mine == null ? 'scheduled' : 'finished',
    'matchType': 'friendly',
    'homeTeam': home ? me : them,
    'awayTeam': home ? them : me,
    'score': mine == null ? null : {'home': home ? mine : theirs, 'away': home ? theirs : mine},
  };
}

class _Backend {
  Map<String, dynamic>? report;
  http.Response? resultError;
  http.Response? reportReadError;
  int dashboardLoads = 0;
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
    if (path == '/api/coach/dashboard') {
      dashboardLoads++;
      return _json(200, {
        'team': {'id': 8, 'name': 'PG Football'},
        'squadSize': 2,
        'pendingRequests': 0,
        'record': {'played': 0, 'won': 0, 'drawn': 0, 'lost': 0, 'form': []},
        'nextMatch': null,
        'upcoming': [],
        'recentResults': [],
        'actionItems': [
          {'type': 'record_result', 'fixture': _fixture(1, 'Northview High')},
          {'type': 'record_result', 'fixture': _fixture(2, 'Westbury High', home: false)},
          {'type': 'submit_lineup', 'fixture': _fixture(3, 'Lakeside', days: 3)},
          {'type': 'file_report', 'fixture': _fixture(4, 'Riverside College', days: -9, mine: 2, theirs: 1)},
        ],
      });
    }
    if (path == '/api/fixtures') {
      if (q['when'] == 'past') {
        return _json(200, {'fixtures': [
          _fixture(4, 'Riverside College', days: -9, mine: 2, theirs: 1),
          _fixture(5, 'Eastgate College', home: false, days: -12, mine: 0, theirs: 3),
        ]});
      }
      return _json(200, {'fixtures': q['status'] == 'cancelled' ? [] : [_fixture(1, 'Northview High'), _fixture(6, 'Greenwood', days: 4)]});
    }
    if (path.endsWith('/result')) return resultError ?? _json(200, {'fixture': {}});
    if (path.endsWith('/report')) {
      if (r.method == 'GET') {
        if (reportReadError != null) return reportReadError!;
        return report == null ? _error(404, 'REPORT_NOT_FOUND') : _json(200, {'report': report});
      }
      return _json(200, {'report': {'summary': 'ok'}});
    }
    if (path == '/api/teams/8/roster') return _json(200, {'roster': []});
    if (path.endsWith('/lineups')) return _json(200, {'home': {'teamId': 8, 'lineup': null}});
    return _error(404, 'NOT_FOUND');
  }

  Iterable<http.Request> puts(String path) => seen.where((r) => r.method == 'PUT' && r.url.path == path);
}

Future<_Backend> _pump(WidgetTester tester, Widget page, {_Backend? backend}) async {
  tester.view.physicalSize = const Size(1400, 2200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final b = backend ?? _Backend();
  final session = Session(ApiClient(baseUrl: 'http://api.test', httpClient: MockClient((r) async => b.handle(r))));
  await session.login('coach@x.com', 'Passw0rdOK');
  await tester.pumpWidget(SessionScope(session: session, child: MaterialApp(home: page)));
  await tester.pumpAndSettle();
  return b;
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Finder _score(String team) => find.byKey(ValueKey('score-$team'));
Finder _in(String key, String text) => find.descendant(of: find.byKey(ValueKey(key)), matching: find.text(text));

void main() {
  group('from the dashboard', () {
    testWidgets('the home coach records a result and the dashboard reloads', (tester) async {
      final b = await _pump(tester, const CoachHomePage());
      await _tap(tester, find.text('Record the result vs Northview High'));
      await _tap(tester, find.text('Save result'));
      expect(find.text('Enter both scores.'), findsOneWidget);
      await tester.enterText(_score('Protea Glen'), '3');
      await tester.enterText(_score('Northview High'), '1');
      await _tap(tester, find.text('Save result'));
      expect(jsonDecode(b.puts('/api/fixtures/1/result').single.body), {'homeScore': 3, 'awayScore': 1});
      expect(find.text('Result recorded.'), findsOneWidget);
      expect(b.dashboardLoads, 2);
    });

    testWidgets('the away coach cannot open score entry', (tester) async {
      await _pump(tester, const CoachHomePage());
      await _tap(tester, find.text('Record the result vs Westbury High'));
      expect(find.text('Save result'), findsNothing);
    });

    testWidgets('a report is filed from its to-do', (tester) async {
      final b = await _pump(tester, const CoachHomePage());
      await _tap(tester, find.text('File the match report vs Riverside College'));
      await _tap(tester, find.text('Save report'));
      expect(find.text('Write a few words about the match.'), findsOneWidget);
      await tester.enterText(find.widgetWithText(TextField, 'What happened?'), '  A close game.  ');
      await _tap(tester, find.text('Save report'));
      expect(jsonDecode(b.puts('/api/fixtures/4/report').single.body), {'summary': 'A close game.'});
      expect(find.text('Match report saved.'), findsOneWidget);
    });

    testWidgets('the lineup to-do opens the lineup', (tester) async {
      await _pump(tester, const CoachHomePage());
      await _tap(tester, find.text('Submit your lineup vs Lakeside'));
      expect(find.text('Lineup vs Lakeside'), findsOneWidget);
    });
  });

  group('from My Matches', () {
    testWidgets('only a home match whose time has come offers Record result', (tester) async {
      await _pump(tester, const CoachMatchesPage());
      expect(_in('fixture-1', 'Record result'), findsOneWidget);
      expect(_in('fixture-6', 'Record result'), findsNothing);
    });

    testWidgets('played matches can have their score corrected by the home coach', (tester) async {
      final b = await _pump(tester, const CoachMatchesPage());
      expect(_in('played-5', 'Correct score'), findsNothing, reason: 'an away match');
      await _tap(tester, _in('played-4', 'Correct score'));
      expect(find.text('Correct the score'), findsOneWidget);
      await tester.enterText(_score('Riverside College'), '2');
      await _tap(tester, find.text('Save result'));
      expect(jsonDecode(b.puts('/api/fixtures/4/result').single.body), {'homeScore': 2, 'awayScore': 2});
      expect(find.text('Score corrected.'), findsOneWidget);
    });

    testWidgets('an existing report is shown with who saved it', (tester) async {
      final b = _Backend()..report = {'summary': 'Good game.', 'author': {'name': 'Sipho Nkosi'}};
      await _pump(tester, const CoachMatchesPage(), backend: b);
      await _tap(tester, _in('played-5', 'Match report'));
      expect(find.text('Good game.'), findsOneWidget);
      expect(find.textContaining('Last saved by Sipho Nkosi'), findsOneWidget);
    });

    testWidgets('if the report cannot be read, nothing can be saved over it', (tester) async {
      final b = _Backend()..reportReadError = _error(500, 'INTERNAL');
      await _pump(tester, const CoachMatchesPage(), backend: b);
      await _tap(tester, _in('played-4', 'Match report'));
      expect(find.text('Try again'), findsOneWidget);
      expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Save report')).onPressed, isNull);
    });

    testWidgets('a refused result is explained', (tester) async {
      final b = _Backend()..resultError = _error(409, 'FIXTURE_NOT_PLAYABLE');
      await _pump(tester, const CoachMatchesPage(), backend: b);
      await _tap(tester, _in('fixture-1', 'Record result'));
      await tester.enterText(_score('Protea Glen'), '1');
      await tester.enterText(_score('Northview High'), '0');
      await _tap(tester, find.text('Save result'));
      expect(find.text('This match is postponed or cancelled.'), findsOneWidget);
    });
  });
}
