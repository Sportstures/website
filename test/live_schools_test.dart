import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:website/api/api_client.dart';
import 'package:website/api/session.dart';
import 'package:website/data/match_store.dart';
import 'package:website/data/models.dart';
import 'package:website/main.dart';
import 'package:website/pages/schools/school_profile_page.dart';
import 'package:website/pages/schools/schools_page.dart';
import 'package:website/widgets/site/filter_controls.dart';

http.Response _json(int status, Object? body) =>
    http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json'});

Map<String, dynamic> _school(int id, String name, {int played = 4}) => {
      'id': id,
      'name': name,
      'province': 'Gauteng',
      'town': 'Soweto',
      'teamCount': 1,
      'sports': ['Football'],
      'record': {'played': played, 'won': 2, 'drawn': 1, 'lost': 1, 'winRate': played == 0 ? null : 50},
    };

Map<String, dynamic> _fixture(int id, {int? home, int? away}) => {
      'id': id,
      'matchDate': '2026-11-20T13:00:00.000Z',
      'status': home == null ? 'scheduled' : 'finished',
      'venue': 'Main Field',
      'homeTeam': {'id': 8, 'name': 'PG Football', 'school': {'id': 3, 'name': 'Protea Glen'}},
      'awayTeam': {'id': 9, 'name': 'EG Football', 'school': {'id': 4, 'name': 'Eastgate'}},
      'score': home == null ? null : {'home': home, 'away': away},
    };

class _Backend {
  bool down = false;
  final seen = <http.Request>[];

  http.Response handle(http.Request r) {
    seen.add(r);
    if (down) return _json(500, {'error': {'code': 'INTERNAL', 'message': 'boom'}});
    final path = r.url.path;
    final q = r.url.queryParameters;
    if (path == '/api/schools/filters') {
      return _json(200, {
        'provinces': [{'name': 'Gauteng', 'schoolCount': 2}, {'name': 'Limpopo', 'schoolCount': 0}],
        'sports': [{'id': 4, 'name': 'Football', 'schoolCount': 2}],
      });
    }
    if (path == '/api/schools') {
      final offset = int.parse(q['offset'] ?? '0');
      final all = [_school(3, 'Protea Glen'), _school(4, 'Eastgate', played: 0)];
      final found = [for (final s in all) if ('${s['name']}'.toLowerCase().contains((q['q'] ?? '').toLowerCase())) s];
      return _json(200, {'schools': found.skip(offset).take(1).toList(), 'total': found.length, 'hasMore': offset + 1 < found.length});
    }
    if (path == '/api/schools/3') {
      return _json(200, {
        'school': _school(3, 'Protea Glen'),
        'teams': [{'name': 'PG Football 1st Team', 'sport': {'name': 'Football'}, 'ageGroup': 'Open', 'coach': {'name': 'Thabo'}, 'playerCount': 14}],
        'recentResults': [_fixture(1, home: 3, away: 1)],
        'upcoming': [_fixture(2)],
      });
    }
    if (path == '/api/rankings') return _json(200, {'rankings': [{'position': 1, 'name': 'Protea Glen', 'points': 961}], 'total': 1});
    if (path == '/api/fixtures') return _json(200, {'fixtures': []});
    return _json(404, {'error': {'code': 'NOT_FOUND', 'message': 'School not found'}});
  }

  Iterable<Map<String, String>> get listed => seen.where((r) => r.url.path == '/api/schools').map((r) => r.url.queryParameters);

  ApiClient client() => ApiClient(baseUrl: 'http://api.test', httpClient: MockClient((r) async => handle(r)));
}

void _size(WidgetTester tester) {
  tester.view.physicalSize = const Size(1400, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<_Backend> _pump(WidgetTester tester, Widget page, {_Backend? backend}) async {
  _size(tester);
  final b = backend ?? _Backend();
  final api = b.client();
  await tester.pumpWidget(SessionScope(
    session: Session(api),
    child: MatchScope(store: MatchStore.api(api), child: MaterialApp(home: page)),
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
  testWidgets('lists the registered schools and loads more', (tester) async {
    final b = await _pump(tester, const SchoolsPage());
    expect(find.text('Showing 1 of 2 schools'), findsOneWidget);
    expect(find.text('4 played · 50% won'), findsOneWidget);
    await _tap(tester, find.text('LOAD MORE SCHOOLS'));
    expect(b.listed.last['offset'], '1');
    expect(find.text('Showing 2 of 2 schools'), findsOneWidget);
    expect(find.text('No matches yet'), findsOneWidget);
    expect(find.text('LOAD MORE SCHOOLS'), findsNothing);
    expect(b.seen.every((r) => !r.headers.containsKey('Authorization')), isTrue);
  });

  testWidgets('searching and choosing a province ask the server', (tester) async {
    final b = await _pump(tester, const SchoolsPage());
    await tester.enterText(find.descendant(of: find.byType(FilterSearchField), matching: find.byType(EditableText)), 'east');
    await _tap(tester, find.text('FILTER'));
    expect(b.listed.last['q'], 'east');
    expect(find.text('Showing 1 of 1 schools'), findsOneWidget);

    expect(find.text('Limpopo'), findsNothing, reason: 'provinces without schools are not offered to browse');
    await _tap(tester, find.widgetWithText(InkWell, 'Gauteng').first);
    expect(b.listed.last['province'], 'Gauteng');
  });

  testWidgets('a school page shows its teams, matches and record', (tester) async {
    await _pump(tester, const SchoolProfilePageWithName('Protea Glen'));
    expect(find.text('PG Football 1st Team'), findsOneWidget);
    expect(find.text('Football · Open · Coach Thabo'), findsOneWidget);
    expect(find.text('3 - 1'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
  });

  testWidgets('an unknown school says so', (tester) async {
    await _pump(tester, const SchoolProfilePageWithName('Nowhere High'));
    expect(find.text('We could not find that school.'), findsOneWidget);
    expect(find.text('TRY AGAIN'), findsNothing);
  });

  testWidgets('a failed list can be retried', (tester) async {
    final b = _Backend()..down = true;
    await _pump(tester, const SchoolsPage(), backend: b);
    expect(find.text("Schools couldn't be loaded."), findsOneWidget);
    b.down = false;
    await _tap(tester, find.text('TRY AGAIN'));
    expect(find.text('Protea Glen'), findsWidgets);
  });

  testWidgets('a shared school address opens that school', (tester) async {
    _size(tester);
    tester.platformDispatcher.defaultRouteNameTestValue = '/school?id=3';
    addTearDown(tester.platformDispatcher.clearDefaultRouteNameTestValue);
    final api = _Backend().client();
    await tester.pumpWidget(TobunApp(session: Session(api), matches: MatchStore.api(api)));
    await tester.pumpAndSettle();
    expect(find.text('PG Football 1st Team'), findsOneWidget);
  });
}

/// The profile page reached with only a school's name.
class SchoolProfilePageWithName extends StatelessWidget {
  const SchoolProfilePageWithName(this.name, {super.key});

  final String name;

  @override
  Widget build(BuildContext context) => SchoolProfilePage(
        school: School(
          name: name,
          town: '',
          region: '',
          province: '',
          type: SchoolType.public,
          color: Colors.green,
          sports: const [],
          athletes: 0,
          joinedDaysAgo: 0,
        ),
      );
}
