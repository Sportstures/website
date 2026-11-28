import 'package:flutter/material.dart';

import '../api/api_client.dart';
import 'models.dart';
import 'sports_data.dart';

/// Turns backend fixtures (`GET /api/fixtures`) into the models the pages draw.
///
/// The backend knows less about a school than the sample data did: no crest
/// colour, no athlete count, and only a province (used as the region). Those get
/// neutral stand-ins; the pages never relied on them for match lists.
class ApiMatchSource {
  ApiMatchSource(this.api);

  final ApiClient api;

  static const _pageSize = 100;

  /// Most matches read per list. Keeps one page load bounded until the lists are paged in the UI.
  static const maxPerList = 500;

  /// Loads the upcoming fixtures and the finished results.
  Future<SportsData> load() async {
    final upcoming = await _readAll({'when': 'upcoming', 'order': 'asc'});
    final past = await _readAll({'when': 'past', 'order': 'desc'});
    return parse(upcoming, past);
  }

  Future<List<Map<String, dynamic>>> _readAll(Map<String, Object?> query) async {
    final rows = <Map<String, dynamic>>[];
    while (rows.length < maxPerList) {
      final body = await api.get('/api/fixtures',
          query: {...query, 'limit': _pageSize, 'offset': rows.length}, auth: false) as Map<String, dynamic>;
      final page = [for (final f in body['fixtures'] as List) Map<String, dynamic>.from(f as Map)];
      rows.addAll(page);
      if (page.length < _pageSize) break;
    }
    return rows;
  }

  /// Builds the data from already-fetched fixture JSON. Public so tests can run it without a server.
  static SportsData parse(List<Map<String, dynamic>> upcoming, List<Map<String, dynamic>> past) {
    final all = [...upcoming, ...past];

    // Which sports each school plays, so a School knows its sports.
    final sportsBySchool = <int, Set<Sport>>{};
    for (final f in all) {
      final sport = Sport.fromName(_name(f['sport']));
      if (sport == null) continue;
      for (final side in ['homeTeam', 'awayTeam']) {
        final id = _schoolId(f[side]);
        if (id != null) (sportsBySchool[id] ??= {}).add(sport);
      }
    }

    final schools = <int, School>{};
    School? schoolOf(Object? team) {
      final school = team is Map ? team['school'] : null;
      if (school is! Map || school['id'] is! int) return null;
      return schools.putIfAbsent(school['id'] as int, () {
        final province = (school['province'] as String?) ?? '';
        final name = '${school['name']}';
        return School(
          name: name,
          town: (school['town'] as String?) ?? '',
          region: province,
          province: province,
          type: SchoolType.public,
          color: colorFor(name),
          sports: sportsBySchool[school['id']]?.toList() ?? const [],
          athletes: 0,
          joinedDaysAgo: 0,
        );
      });
    }

    Fixture? toFixture(Map<String, dynamic> f) {
      final sport = Sport.fromName(_name(f['sport']));
      final home = schoolOf(f['homeTeam']);
      final away = schoolOf(f['awayTeam']);
      final when = DateTime.tryParse('${f['matchDate']}');
      // Matches the site has no page for (a sport it does not list) or without both schools are left out.
      if (sport == null || home == null || away == null || when == null) return null;
      final level = (f['homeTeam'] as Map)['level'] as String?;
      return Fixture(
        id: f['id'] as int?,
        sport: sport,
        ageGroup: ageGroupLabel(level),
        league: leagueLabel(f),
        home: home,
        away: away,
        startsAt: when.toLocal(),
        venueName: f['venue'] as String?,
      );
    }

    final fixtures = <Fixture>[];
    // The backend lists every match without a result, including ones whose day has gone by.
    final today = DateUtils.dateOnly(DateTime.now());
    for (final f in upcoming) {
      final fixture = toFixture(f);
      if (fixture != null && (f['status'] == 'live' || !fixture.startsAt.isBefore(today))) fixtures.add(fixture);
    }

    final results = <MatchResult>[];
    for (final f in past) {
      final score = f['score'];
      final fixture = toFixture(f);
      if (fixture == null || score is! Map) continue;
      results.add(MatchResult(fixture, score['home'] as int, score['away'] as int));
    }

    fixtures.sort((a, b) => a.startsAt.compareTo(b.startsAt));
    results.sort((a, b) => b.fixture.startsAt.compareTo(a.fixture.startsAt));
    return SportsData.fromMatches(fixtures, results);
  }

  static String? _name(Object? sport) => sport is Map ? sport['name'] as String? : null;

  static int? _schoolId(Object? team) {
    final school = team is Map ? team['school'] : null;
    return school is Map && school['id'] is int ? school['id'] as int : null;
  }

  /// `u16` -> `U/16`, `1st_team` -> `1st Team`. Anything else is shown as given.
  static String ageGroupLabel(String? level) {
    final value = (level ?? '').trim();
    if (value.isEmpty) return 'Open';
    final under = RegExp(r'^u(\d+)$', caseSensitive: false).firstMatch(value);
    if (under != null) return 'U/${under.group(1)}';
    if (value == '1st_team') return '1st Team';
    if (value == '2nd_team') return '2nd Team';
    return value;
  }

  static String leagueLabel(Map<String, dynamic> fixture) {
    final competition = fixture['competition'];
    if (competition is Map && '${competition['name']}'.trim().isNotEmpty) return '${competition['name']}';
    return switch (fixture['matchType']) {
      'friendly' => 'Friendlies',
      'championship' => 'Championship',
      'semifinal' => 'Semifinal',
      _ => 'League',
    };
  }

  static const _palette = [
    Color(0xFF1F3A68), Color(0xFFE8731A), Color(0xFF1E7B3A), Color(0xFF5B2A86), Color(0xFF0E4D64),
    Color(0xFF8A5A00), Color(0xFF7B1E3A), Color(0xFF2B5BA8), Color(0xFF4A4A4A), Color(0xFFB0203A),
  ];

  /// A crest colour that is always the same for the same school name.
  static Color colorFor(String name) {
    var hash = 0;
    for (final unit in name.toLowerCase().codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return _palette[hash % _palette.length];
  }
}
