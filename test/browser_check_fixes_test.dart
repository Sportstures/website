import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:website/data/api_matches.dart';
import 'package:website/pages/standings/standings_page.dart';
import 'package:website/data/match_store.dart';
import 'package:website/api/api_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'dart:convert';
import 'package:website/widgets/site/match_rows.dart';
import 'package:website/widgets/site/ui_kit.dart';

/// Problems found by looking at the pages in a browser against the live backend.
Map<String, dynamic> _team(int id, String school) => {
      'id': id,
      'name': school,
      'level': '1st_team',
      'sport': {'id': 1, 'name': 'Football'},
      'school': {'id': id, 'name': school, 'province': 'Gauteng'},
    };

Map<String, dynamic> _fixture(int id, int days, {String status = 'scheduled'}) => {
      'id': id,
      'matchDate': DateTime.now().add(Duration(days: days)).toUtc().toIso8601String(),
      'status': status,
      'sport': {'id': 1, 'name': 'Football'},
      'homeTeam': _team(1, 'Greenwood Academy'),
      'awayTeam': _team(2, 'Westbury High'),
      'score': null,
    };

void main() {
  test('a match whose day has passed without a result is not upcoming', () {
    final data = ApiMatchSource.parse(
      [_fixture(1, -7), _fixture(2, 0), _fixture(3, 5), _fixture(4, -1, status: 'live')],
      [],
    );
    expect(data.fixtures.map((f) => f.id), unorderedEquals([2, 3, 4]));
  });

  testWidgets('team names get their own lines on a narrow screen', (tester) async {
    final data = ApiMatchSource.parse([_fixture(1, 3)], []);
    final fixture = data.fixtures.single;
    Future<(Offset, Offset)> places(double width) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(width: width, child: TeamsLine(home: fixture.home, away: fixture.away, center: const Text('VS'))),
          ),
        ),
      ));
      expect(tester.takeException(), isNull);
      return (tester.getTopLeft(find.text('Greenwood Academy')), tester.getTopLeft(find.text('Westbury High')));
    }

    final (wideHome, wideAway) = await places(600);
    expect(wideHome.dy, wideAway.dy);
    final (narrowHome, narrowAway) = await places(200);
    expect(narrowAway.dy, greaterThan(narrowHome.dy));
  });

  testWidgets('standings do not open on an empty age group', (tester) async {
    tester.view.physicalSize = const Size(1400, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    // Football is played at 1st team only; another sport has the only U/19 results.
    final finished = {..._fixture(1, -3, status: 'finished'), 'score': {'home': 2, 'away': 1}};
    final also = {..._fixture(2, -4, status: 'finished'), 'score': {'home': 0, 'away': 0}};
    final basketball = {
      ..._fixture(3, -5, status: 'finished'),
      'sport': {'id': 2, 'name': 'Basketball'},
      'homeTeam': {..._team(3, 'Meadowbrook College'), 'level': 'u19'},
      'awayTeam': {..._team(4, 'Seaview Academy'), 'level': 'u19'},
      'score': {'home': 40, 'away': 30},
    };
    final api = ApiClient(
      baseUrl: 'http://api.test',
      httpClient: MockClient((r) async => http.Response(
          jsonEncode({'fixtures': r.url.queryParameters['when'] == 'past' ? [finished, also, basketball] : []}), 200)),
    );
    await tester.pumpWidget(MatchScope(store: MatchStore.api(api), child: const MaterialApp(home: StandingsPage())));
    await tester.pumpAndSettle();
    expect(find.text('Greenwood Academy'), findsWidgets);
    expect(find.textContaining('No results for this table yet'), findsNothing);
  });

  testWidgets('counts of matches are spelled correctly', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Column(children: [CountLabel(count: 5, noun: 'match'), CountLabel(count: 2, noun: 'player')])));
    expect(find.text('5 MATCHES'), findsOneWidget);
    expect(find.text('2 PLAYERS'), findsOneWidget);
  });

}
