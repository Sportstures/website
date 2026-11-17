import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:website/data/models.dart';
import 'package:website/data/sports_data.dart';

School _school(String name) => School(
      name: name,
      town: 'Town',
      region: 'Gauteng',
      province: 'Gauteng',
      type: SchoolType.values.first,
      color: const Color(0xFF000000),
      sports: const [],
      athletes: 0,
      joinedDaysAgo: 0,
    );

MatchResult _game(School home, int homeScore, School away, int awayScore) => MatchResult(
      Fixture(sport: Sport.values.first, ageGroup: 'U/16', league: 'League', home: home, away: away, startsAt: DateTime(2026, 9, 1)),
      homeScore,
      awayScore,
    );

void main() {
  final a = _school('A');
  final b = _school('B');
  final c = _school('C');
  final d = _school('D');

  List<String> order(List<MatchResult> results, {TeamSide? side}) =>
      SportsData.standingsFor(results, side: side).map((s) => s.school.name).toList();

  test('score difference, then points scored, still come before head-to-head', () {
    // A beat C 3-0, B beat D 2-0: both 3 points, A has the better difference.
    expect(order([_game(a, 3, c, 0), _game(b, 2, d, 0)]).take(2), ['A', 'B']);
  });

  test('head-to-head separates schools level on points, difference and scored', () {
    // A beat B 1-0, B beat C 1-0, D beat A 1-0: A and B are both 3 points, scored 1, conceded 1.
    final results = [_game(a, 1, b, 0), _game(b, 1, c, 0), _game(d, 1, a, 0)];
    expect(order(results), ['D', 'A', 'B', 'C']);
    // Reverse who beat whom and the order of A and B flips (it is not just alphabetical).
    final flipped = [_game(b, 1, a, 0), _game(a, 1, c, 0), _game(d, 1, b, 0)];
    expect(order(flipped), ['D', 'B', 'A', 'C']);
  });

  test('a head-to-head that is level falls back to the alphabet', () {
    expect(order([_game(b, 2, a, 1), _game(a, 2, b, 1)]), ['A', 'B']);
  });
}
