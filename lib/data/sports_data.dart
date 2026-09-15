import 'dart:math';

import 'package:flutter/material.dart';

import 'models.dart';

// TODO: replace this generated sample data with calls to the Node/JS backend
class SportsData {
  SportsData._(this.fixtures, this.results);

  static final instance = SportsData._generate(DateTime.now());

  /// Upcoming fixtures, soonest first.
  final List<Fixture> fixtures;

  /// Finished matches, most recent first.
  final List<MatchResult> results;

  /// Calendar years that have matches, newest first.
  late final List<int> seasons = {
    for (final fixture in fixtures) fixture.startsAt.year,
    for (final result in results) result.fixture.startsAt.year,
  }.toList()
    ..sort((a, b) => b.compareTo(a));

  static const schools = [
    School(
      name: 'Northview High',
      town: 'Sandton',
      region: 'Gauteng North',
      province: 'Gauteng',
      type: SchoolType.public,
      color: Color(0xFF1F3A68),
      sports: [Sport.football, Sport.rugby, Sport.basketball, Sport.cricket, Sport.hockey, Sport.swimming],
      athletes: 940,
      joinedDaysAgo: 210,
      featured: true,
    ),
    School(
      name: 'Riverside College',
      town: 'Pretoria',
      region: 'Gauteng North',
      province: 'Gauteng',
      type: SchoolType.independent,
      color: Color(0xFFE8731A),
      sports: [Sport.football, Sport.rugby, Sport.netball, Sport.cricket, Sport.hockey, Sport.volleyball],
      athletes: 780,
      joinedDaysAgo: 180,
      featured: true,
    ),
    School(
      name: 'Greenwood Academy',
      town: 'Alberton',
      region: 'Gauteng South',
      province: 'Gauteng',
      type: SchoolType.independent,
      color: Color(0xFF1E7B3A),
      sports: [Sport.football, Sport.netball, Sport.basketball, Sport.hockey, Sport.swimming, Sport.volleyball],
      athletes: 620,
      joinedDaysAgo: 40,
    ),
    School(
      name: 'Kingsway High',
      town: 'Soweto',
      region: 'Gauteng South',
      province: 'Gauteng',
      type: SchoolType.public,
      color: Color(0xFF5B2A86),
      sports: [Sport.football, Sport.rugby, Sport.netball, Sport.basketball, Sport.cricket, Sport.volleyball],
      athletes: 1150,
      joinedDaysAgo: 150,
    ),
    School(
      name: 'Lakeside Collegiate',
      town: 'Cape Town',
      region: 'Western Cape',
      province: 'Western Cape',
      type: SchoolType.independent,
      color: Color(0xFF0E4D64),
      sports: [Sport.rugby, Sport.netball, Sport.cricket, Sport.hockey, Sport.swimming, Sport.football],
      athletes: 710,
      joinedDaysAgo: 230,
      featured: true,
    ),
    School(
      name: 'Oakridge High',
      town: 'Stellenbosch',
      region: 'Western Cape',
      province: 'Western Cape',
      type: SchoolType.public,
      color: Color(0xFF8A5A00),
      sports: [Sport.rugby, Sport.cricket, Sport.hockey, Sport.football, Sport.netball],
      athletes: 830,
      joinedDaysAgo: 25,
    ),
    School(
      name: 'Hillcrest Secondary',
      town: 'Pinetown',
      region: 'KwaZulu-Natal',
      province: 'KwaZulu-Natal',
      type: SchoolType.public,
      color: Color(0xFF7B1E3A),
      sports: [Sport.football, Sport.rugby, Sport.netball, Sport.basketball, Sport.swimming, Sport.hockey],
      athletes: 1020,
      joinedDaysAgo: 200,
    ),
    School(
      name: 'Meadowbrook College',
      town: 'Pietermaritzburg',
      region: 'KwaZulu-Natal',
      province: 'KwaZulu-Natal',
      type: SchoolType.independent,
      color: Color(0xFF2B5BA8),
      sports: [Sport.football, Sport.rugby, Sport.cricket, Sport.hockey, Sport.swimming, Sport.basketball],
      athletes: 560,
      joinedDaysAgo: 55,
      featured: true,
    ),
    School(
      name: 'Summit Park School',
      town: 'Gqeberha',
      region: 'Eastern Cape',
      province: 'Eastern Cape',
      type: SchoolType.public,
      color: Color(0xFF4A4A4A),
      sports: [Sport.football, Sport.rugby, Sport.netball, Sport.cricket, Sport.basketball],
      athletes: 690,
      joinedDaysAgo: 120,
    ),
    School(
      name: 'Valley View Academy',
      town: 'Bloemfontein',
      region: 'Free State',
      province: 'Free State',
      type: SchoolType.independent,
      color: Color(0xFFB0203A),
      sports: [Sport.football, Sport.netball, Sport.rugby, Sport.hockey, Sport.volleyball, Sport.cricket],
      athletes: 480,
      joinedDaysAgo: 15,
    ),
    School(
      name: 'Eastgate Secondary',
      town: 'Polokwane',
      region: 'Limpopo',
      province: 'Limpopo',
      type: SchoolType.public,
      color: Color(0xFF14532D),
      sports: [Sport.football, Sport.netball, Sport.basketball, Sport.volleyball, Sport.cricket],
      athletes: 870,
      joinedDaysAgo: 90,
    ),
    School(
      name: 'Silverton High',
      town: 'Mbombela',
      region: 'Mpumalanga',
      province: 'Mpumalanga',
      type: SchoolType.public,
      color: Color(0xFFB45309),
      sports: [Sport.football, Sport.rugby, Sport.netball, Sport.basketball, Sport.hockey, Sport.swimming],
      athletes: 750,
      joinedDaysAgo: 70,
    ),
  ];

  static final regions = {for (final school in schools) school.region}.toList()..sort();
  static final provinces = {for (final school in schools) school.province}.toList()..sort();

  static const ageGroups = ['U/14', 'U/15', 'U/16', 'U/17', 'U/19'];
  static const leagues = ['Champ Region League', 'Schools Cup', 'Friendlies'];

  factory SportsData._generate(DateTime now) {
    final random = Random(7);
    final fixtures = <Fixture>[];
    final results = <MatchResult>[];

    for (var dayOffset = -90; dayOffset <= 30; dayOffset++) {
      final matchCount = 4 + random.nextInt(9);
      for (var i = 0; i < matchCount; i++) {
        final homeIndex = random.nextInt(schools.length);
        final awayIndex = (homeIndex + 1 + random.nextInt(schools.length - 1)) % schools.length;
        final home = schools[homeIndex];
        final away = schools[awayIndex];
        final shared = home.sports.where(away.sports.contains).toList();
        final sportPool = shared.isEmpty ? home.sports : shared;
        final sport = sportPool[random.nextInt(sportPool.length)];

        final fixture = Fixture(
          sport: sport,
          ageGroup: ageGroups[random.nextInt(ageGroups.length)],
          league: leagues[random.nextInt(leagues.length)],
          home: home,
          away: away,
          startsAt: DateTime(
            now.year,
            now.month,
            now.day + dayOffset,
            8 + random.nextInt(8),
            random.nextBool() ? 0 : 30,
          ),
        );

        final (low, high) = _scoreRange(sport);
        final homeScore = low + random.nextInt(high - low + 1);
        final awayScore = low + random.nextInt(high - low + 1);

        if (fixture.startsAt.isAfter(now)) {
          fixtures.add(fixture);
        } else {
          results.add(MatchResult(fixture, homeScore, awayScore));
        }
      }
    }

    fixtures.sort((a, b) => a.startsAt.compareTo(b.startsAt));
    results.sort((a, b) => b.fixture.startsAt.compareTo(a.fixture.startsAt));
    return SportsData._(fixtures, results);
  }

  static (int, int) _scoreRange(Sport sport) => switch (sport) {
        Sport.football || Sport.hockey => (0, 5),
        Sport.rugby => (0, 55),
        Sport.netball => (15, 55),
        Sport.basketball => (30, 90),
        Sport.cricket => (80, 260),
        Sport.swimming => (40, 120),
        Sport.volleyball => (0, 3),
      };

  /// Log table built from [results] (newest first): 3 points for a win, 1 for
  /// a draw. Pass [side] to count only home or only away matches.
  static List<SchoolStanding> standingsFor(Iterable<MatchResult> results, {TeamSide? side}) {
    final table = <School, SchoolStanding>{};
    SchoolStanding entry(School school) => table.putIfAbsent(school, () => SchoolStanding(school));

    for (final result in results) {
      if (side != TeamSide.away) {
        entry(result.fixture.home).record(result.homeScore, result.awayScore);
      }
      if (side != TeamSide.home) {
        entry(result.fixture.away).record(result.awayScore, result.homeScore);
      }
    }

    return table.values.toList()
      ..sort((a, b) {
        for (final comparison in [
          b.points.compareTo(a.points),
          b.scoreDifference.compareTo(a.scoreDifference),
          b.scored.compareTo(a.scored),
        ]) {
          if (comparison != 0) return comparison;
        }
        return a.school.name.compareTo(b.school.name);
      });
  }

  // TODO: the backend's ranking formula should follow the weights shown in the
  // Rankings page breakdown card; this placeholder only rewards results.
  static int rankingPoints(int scored, int conceded) => scored > conceded
      ? 40
      : scored == conceded
          ? 15
          : 5;

  /// Ranked entries of [type] from [results], with each entry's movement
  /// compared with the table as it stood a week before [now].
  static List<RankingEntry> rankingsFor(
    List<MatchResult> results,
    RankingType type, {
    required DateTime now,
  }) {
    // No player data yet, so athletes can't be ranked.
    if (type == RankingType.athletes) return const <RankingEntry>[];

    final current = _rank(results, type);
    final weekAgo = now.subtract(const Duration(days: 7));
    final previousPlaces = {
      for (final (place, entry) in _rank(results.where((r) => r.fixture.startsAt.isBefore(weekAgo)), type).indexed)
        entry.key: place,
    };
    for (final (place, entry) in current.indexed) {
      final before = previousPlaces[entry.key];
      entry.trend = before == null ? 0 : before - place;
    }
    return current;
  }

  static List<RankingEntry> _rank(Iterable<MatchResult> results, RankingType type) {
    final entries = <String, RankingEntry>{};

    void credit(Fixture fixture, School school, int scored, int conceded) {
      final team = '${fixture.sport.label} ${fixture.ageGroup}';
      final key = switch (type) {
        RankingType.teams => '${school.name}|$team',
        RankingType.regions => school.region,
        _ => school.name,
      };
      final entry = entries.putIfAbsent(
        key,
        () => type == RankingType.regions
            ? RankingEntry(key: key, title: school.region, region: school.region)
            : RankingEntry(
                key: key,
                title: school.name,
                subtitle: type == RankingType.teams ? team : null,
                school: school,
                region: school.region,
              ),
      );
      entry
        ..points += rankingPoints(scored, conceded)
        ..played += 1;
      entry.sports.add(fixture.sport);
      entry.schools.add(school);
    }

    for (final result in results) {
      credit(result.fixture, result.fixture.home, result.homeScore, result.awayScore);
      credit(result.fixture, result.fixture.away, result.awayScore, result.homeScore);
    }

    return entries.values.toList()
      ..sort((a, b) {
        final byPoints = b.points.compareTo(a.points);
        return byPoints != 0 ? byPoints : a.title.compareTo(b.title);
      });
  }

  /// Ranking points earned in each sport, highest first.
  static List<(Sport, int)> pointsBySport(Iterable<MatchResult> results) {
    final totals = <Sport, int>{};
    for (final result in results) {
      final earned = rankingPoints(result.homeScore, result.awayScore) +
          rankingPoints(result.awayScore, result.homeScore);
      totals.update(result.fixture.sport, (total) => total + earned, ifAbsent: () => earned);
    }
    return [for (final entry in totals.entries) (entry.key, entry.value)]
      ..sort((a, b) => b.$2.compareTo(a.$2));
  }
}
