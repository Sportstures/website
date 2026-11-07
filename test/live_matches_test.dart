import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:website/ai/ai_provider.dart';
import 'package:website/ai/local_ai_service.dart';
import 'package:website/api/api_client.dart';
import 'package:website/api/session.dart';
import 'package:website/data/api_matches.dart';
import 'package:website/data/match_store.dart';
import 'package:website/data/models.dart';
import 'package:website/main.dart';
import 'package:website/pages/fixtures/fixtures_page.dart';
import 'package:website/pages/results/results_page.dart';

// ---------------------------------------------------------------- fake backend data

const _schoolIds = {'Northview High': 1, 'Riverside College': 2, 'Greenwood Academy': 3, 'Oakridge High': 4};
const _provinces = {'Northview High': 'Gauteng', 'Riverside College': 'Gauteng', 'Greenwood Academy': null, 'Oakridge High': 'Western Cape'};

Map<String, dynamic> _team(String school, {String level = 'u16', String sport = 'Football'}) => {
      'id': _schoolIds[school]! * 10,
      'name': '$school $sport',
      'level': level,
      'sport': {'id': 1, 'name': sport},
      'school': {'id': _schoolIds[school], 'name': school, 'province': _provinces[school], 'town': null},
    };

Map<String, dynamic> _fixture(
  int id,
  String home,
  String away, {
  required DateTime at,
  int? homeScore,
  int? awayScore,
  String sport = 'Football',
  String level = 'u16',
  String? competition = 'Schools League',
  String matchType = 'league',
  String? venue,
}) =>
    {
      'id': id,
      'matchDate': at.toUtc().toIso8601String(),
      'status': homeScore == null ? 'scheduled' : 'finished',
      'venue': venue,
      'matchType': matchType,
      'competition': competition == null ? null : {'id': 1, 'name': competition},
      'sport': {'id': 1, 'name': sport},
      'homeTeam': _team(home, level: level, sport: sport),
      'awayTeam': _team(away, level: level, sport: sport),
      'score': homeScore == null ? null : {'home': homeScore, 'away': awayScore},
    };

final _now = DateTime.now();
DateTime _days(int n) => DateTime(_now.year, _now.month, _now.day + n, 15);

List<Map<String, dynamic>> _upcoming() => [
      _fixture(1, 'Northview High', 'Riverside College', at: _days(2), venue: 'Northview Main Field'),
      _fixture(2, 'Oakridge High', 'Greenwood Academy', at: _days(3), level: '1st_team', matchType: 'friendly', competition: null),
    ];

List<Map<String, dynamic>> _past() => [
      _fixture(10, 'Northview High', 'Oakridge High', at: _days(-3), homeScore: 3, awayScore: 1),
      _fixture(11, 'Riverside College', 'Northview High', at: _days(-10), homeScore: 2, awayScore: 2),
      _fixture(12, 'Oakridge High', 'Riverside College', at: _days(-17), homeScore: 0, awayScore: 1),
    ];

http.Response _json(int status, Object body) =>
    http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json'});

/// A fake backend serving the fixtures list the way the real one does (when, limit, offset).
class _Backend {
  _Backend({List<Map<String, dynamic>>? upcoming, List<Map<String, dynamic>>? past, this.failing = false})
      : upcoming = upcoming ?? _upcoming(),
        past = past ?? _past();

  List<Map<String, dynamic>> upcoming;
  List<Map<String, dynamic>> past;
  bool failing;
  final requests = <http.Request>[];

  http.Response handle(http.Request r) {
    requests.add(r);
    if (failing) return _json(500, {'error': {'code': 'INTERNAL', 'message': 'boom'}});
    final q = r.url.queryParameters;
    final all = q['when'] == 'past' ? past : upcoming;
    final offset = int.parse(q['offset'] ?? '0');
    final limit = int.parse(q['limit'] ?? '50');
    final page = all.skip(offset).take(limit).toList();
    return _json(200, {'fixtures': page, 'limit': limit, 'offset': offset});
  }

  ApiClient client() => ApiClient(
        baseUrl: 'http://api.test',
        httpClient: MockClient((r) async => handle(r)),
      );
}

Future<void> _pumpApp(WidgetTester tester, _Backend backend) async {
  tester.view.physicalSize = const Size(1400, 1100);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final api = backend.client();
  await tester.pumpWidget(TobunApp(session: Session(api), matches: MatchStore.api(api)));
  await tester.pumpAndSettle();
}

Future<void> _goTo(WidgetTester tester, String nav) async {
  await tester.tap(find.text(nav).first);
  await tester.pumpAndSettle();
}

void main() {
  tearDown(() => aiService = const LocalAiService());

  group('mapping backend fixtures', () {
    final data = ApiMatchSource.parse(_upcoming(), _past());

    test('upcoming fixtures and finished results are separated and ordered', () {
      expect(data.fixtures.map((f) => f.id), [1, 2], reason: 'soonest first');
      expect(data.results.map((r) => r.fixture.id), [10, 11, 12], reason: 'newest first');
      expect(data.isSample, isFalse);
    });

    test('a fixture carries sport, age group, league, venue and the schools', () {
      final f = data.fixtures.first;
      expect(f.sport, Sport.football);
      expect(f.ageGroup, 'U/16');
      expect(f.league, 'Schools League');
      expect(f.venue, 'Northview Main Field');
      expect(f.home.name, 'Northview High');
      expect(f.away.name, 'Riverside College');
      expect(f.startsAt, _days(2));
    });

    test('with no venue the old "<school> Sports Ground" is used', () {
      expect(data.results.first.fixture.venue, 'Northview High Sports Ground');
    });

    test('level and match type become the age group and league labels', () {
      final friendly = data.fixtures.last;
      expect(friendly.ageGroup, '1st Team');
      expect(friendly.league, 'Friendlies');
      expect(ApiMatchSource.ageGroupLabel('u19'), 'U/19');
      expect(ApiMatchSource.ageGroupLabel('2nd_team'), '2nd Team');
      expect(ApiMatchSource.ageGroupLabel(null), 'Open');
    });

    test('scores come through', () {
      final r = data.results.first;
      expect([r.homeScore, r.awayScore], [3, 1]);
      expect(r.homeWon, isTrue);
      expect(data.results[1].isDraw, isTrue);
    });

    test('province is used as the region; a school with none has an empty region and is not offered as a filter', () {
      expect(data.regionOptions, ['Gauteng', 'Western Cape']);
      expect(data.fixtures.last.home.region, 'Western Cape');
      expect(data.fixtures.last.away.region, '');
    });

    test('the same school is the same object everywhere, so tables add up', () {
      final northview = {data.fixtures.first.home, data.results.first.fixture.home, data.results[1].fixture.away};
      expect(northview.length, 1);
    });

    test('filter lists are built from the data', () {
      expect(data.ageGroupOptions, ['1st Team', 'U/16']);
      expect(data.leagueOptions, ['Friendlies', 'Schools League']);
      expect(data.seasonOptions, [_now.year, if (_days(-17).year != _now.year) _days(-17).year]..sort((a, b) => b.compareTo(a)));
    });

    test('a crest colour is stable for the same name', () {
      expect(ApiMatchSource.colorFor('Northview High'), ApiMatchSource.colorFor('northview high'));
    });

    test('sports the site has no page for, and unfinished or unscored matches, are left out', () {
      final cricketLike = _fixture(20, 'Northview High', 'Oakridge High', at: _days(-1), homeScore: 1, awayScore: 0, sport: 'Underwater Hockey');
      final noScore = _fixture(21, 'Northview High', 'Oakridge High', at: _days(-2))..['status'] = 'finished';
      final soccer = _fixture(22, 'Northview High', 'Oakridge High', at: _days(-4), homeScore: 1, awayScore: 0, sport: 'Soccer');
      final d = ApiMatchSource.parse([], [cricketLike, noScore, soccer]);
      expect(d.results.map((r) => r.fixture.id), [22], reason: 'soccer is football; the others are skipped');
      expect(d.results.single.fixture.sport, Sport.football);
    });

    test('no matches at all still gives a usable season list', () {
      final empty = ApiMatchSource.parse([], []);
      expect(empty.fixtures, isEmpty);
      expect(empty.seasonOptions, [DateTime.now().year]);
    });

    test('Sport.fromName', () {
      expect(Sport.fromName('Football'), Sport.football);
      expect(Sport.fromName(' SOCCER '), Sport.football);
      expect(Sport.fromName('Athletics'), isNull);
      expect(Sport.fromName(null), isNull);
    });
  });

  group('MatchStore', () {
    test('loads upcoming and past from the public API, with no login sent', () async {
      final backend = _Backend();
      final store = MatchStore.api(backend.client());
      expect(store.state, MatchLoad.idle);
      await store.ensureLoaded();
      expect(store.state, MatchLoad.loaded);
      expect(store.data!.fixtures.length, 2);
      expect(store.data!.results.length, 3);
      expect(backend.requests.map((r) => r.url.queryParameters['when']).toSet(), {'upcoming', 'past'});
      expect(backend.requests.every((r) => !r.headers.containsKey('Authorization')), isTrue);
    });

    test('reads every page of a long list', () async {
      final many = [for (var i = 0; i < 230; i++) _fixture(100 + i, 'Northview High', 'Oakridge High', at: _days(5 + i % 30))];
      final backend = _Backend(upcoming: many, past: []);
      final store = MatchStore.api(backend.client());
      await store.ensureLoaded();
      expect(store.data!.fixtures.length, 230);
      expect(backend.requests.where((r) => r.url.queryParameters['when'] == 'upcoming').length, 3, reason: '100 + 100 + 30');
    });

    test('a failure is reported, and Try again can recover', () async {
      final backend = _Backend(failing: true);
      final store = MatchStore.api(backend.client());
      await store.ensureLoaded();
      expect(store.state, MatchLoad.failed);
      expect(store.data, isNull);
      expect(store.error, isNotEmpty);

      backend.failing = false;
      await store.reload();
      expect(store.state, MatchLoad.loaded);
      expect(store.error, isNull);
    });

    test('a failed refresh keeps the data already loaded', () async {
      final backend = _Backend();
      final store = MatchStore.api(backend.client());
      await store.ensureLoaded();
      backend.failing = true;
      await store.reload();
      expect(store.state, MatchLoad.loaded);
      expect(store.data!.results.length, 3);
      expect(store.error, isNotNull);
    });

    test('fresh data is not fetched again', () async {
      final backend = _Backend();
      final store = MatchStore.api(backend.client());
      await store.ensureLoaded();
      final calls = backend.requests.length;
      await store.ensureLoaded();
      expect(backend.requests.length, calls);
    });

    test('the sample store has data at once and never calls out', () async {
      final store = MatchStore.sample();
      expect(store.state, MatchLoad.loaded);
      expect(store.data!.isSample, isTrue);
      await store.ensureLoaded();
      await store.reload();
      expect(store.data!.isSample, isTrue);
    });
  });

  group('the pages on live data', () {
    testWidgets('Fixtures lists the upcoming matches from the backend', (tester) async {
      await _pumpApp(tester, _Backend());
      await _goTo(tester, 'Fixtures');
      expect(find.text('Search fixtures'), findsOneWidget);
      expect(find.text('Northview High'), findsWidgets);
      expect(find.text('Riverside College'), findsWidgets);
      expect(find.text('Northview Main Field'), findsWidgets);
    });

    testWidgets('Results shows the real scores', (tester) async {
      await _pumpApp(tester, _Backend());
      await _goTo(tester, 'Results');
      expect(find.text('Search results'), findsOneWidget);
      expect(find.text('Northview High'), findsWidgets);
      expect(find.text('Oakridge High'), findsWidgets);
      expect(find.text('3'), findsWidgets);
    });

    testWidgets('Standings builds a table from the results, on the sport with the most results', (tester) async {
      await _pumpApp(tester, _Backend());
      await _goTo(tester, 'Standings');
      expect(find.text('LEAGUE TABLE'), findsWidgets);
      expect(find.text('FOOTBALL ALL AGES - ALL COMPETITIONS'), findsOneWidget);
      expect(find.text('Northview High'), findsWidgets);
      expect(find.text('Riverside College'), findsWidgets);
      expect(find.textContaining('No results for this table yet'), findsNothing);
    });

    testWidgets('the region filter offers the provinces that exist in the data', (tester) async {
      await _pumpApp(tester, _Backend());
      await _goTo(tester, 'Results');
      await tester.tap(find.text('All Regions').first);
      await tester.pumpAndSettle();
      expect(find.text('Gauteng'), findsWidgets);
      expect(find.text('Western Cape'), findsWidgets);
      expect(find.text('KwaZulu-Natal'), findsNothing, reason: 'no school there in this data');
    });

    testWidgets('an empty database shows friendly empty states, not sample data', (tester) async {
      final backend = _Backend(upcoming: [], past: []);
      await _pumpApp(tester, backend);
      await _goTo(tester, 'Fixtures');
      expect(find.textContaining('No fixtures have been scheduled yet'), findsOneWidget);
      expect(find.text('Northview High'), findsNothing);
      await _goTo(tester, 'Results');
      expect(find.textContaining('No results have been recorded yet'), findsOneWidget);
      await _goTo(tester, 'Standings');
      expect(find.textContaining('No results for this table yet'), findsWidgets);
    });

    testWidgets('when the backend is down the page says so and Try again recovers', (tester) async {
      final backend = _Backend(failing: true);
      await _pumpApp(tester, backend);
      await _goTo(tester, 'Results');
      expect(find.text("COULDN'T LOAD RESULTS"), findsOneWidget);
      expect(find.text('TRY AGAIN'), findsOneWidget);

      backend.failing = false;
      await tester.tap(find.text('TRY AGAIN'));
      await tester.pumpAndSettle();
      expect(find.text("COULDN'T LOAD RESULTS"), findsNothing);
      expect(find.text('Search results'), findsOneWidget);
    });

    testWidgets('pages built on their own (no scope) still use the sample data', (tester) async {
      tester.view.physicalSize = const Size(1400, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const MaterialApp(home: FixturesPage()));
      await tester.pumpAndSettle();
      expect(find.text('Search fixtures'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      await tester.pumpWidget(const MaterialApp(home: ResultsPage()));
      await tester.pumpAndSettle();
      expect(find.text('Search results'), findsOneWidget);
    });

    testWidgets('loading live data points the AI cards at the live results', (tester) async {
      final before = aiService;
      await _pumpApp(tester, _Backend());
      await _goTo(tester, 'Fixtures');
      expect(identical(aiService, before), isFalse, reason: 'the AI history was swapped for the live results');
      expect(aiService, isA<LocalAiService>());
    });
  });
}

