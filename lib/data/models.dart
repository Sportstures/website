import 'package:flutter/material.dart';

enum Sport {
  football('Football', Icons.sports_soccer, 'Goals'),
  rugby('Rugby', Icons.sports_rugby, 'Points'),
  netball('Netball', Icons.sports_handball, 'Goals'),
  basketball('Basketball', Icons.sports_basketball, 'Points'),
  cricket('Cricket', Icons.sports_cricket, 'Runs'),
  hockey('Hockey', Icons.sports_hockey, 'Goals'),
  swimming('Swimming', Icons.pool, 'Points'),
  volleyball('Volleyball', Icons.sports_volleyball, 'Sets');

  const Sport(this.label, this.icon, this.scoreLabel);

  final String label;
  final IconData icon;

  /// What a score counts in this sport, e.g. Goals or Runs.
  final String scoreLabel;

  /// The sport the backend calls [name] ("Football", "soccer"...), or null if the site has no page for it.
  static Sport? fromName(String? name) {
    final wanted = (name ?? '').trim().toLowerCase();
    if (wanted == 'soccer') return football;
    for (final sport in values) {
      if (sport.label.toLowerCase() == wanted) return sport;
    }
    return null;
  }
}

enum SchoolType {
  public('Public'),
  independent('Independent');

  const SchoolType(this.label);

  final String label;
}

class School {
  const School({
    required this.name,
    required this.town,
    required this.region,
    required this.province,
    required this.type,
    required this.color,
    required this.sports,
    required this.athletes,
    required this.joinedDaysAgo,
    this.featured = false,
  });

  final String name;
  final String town;
  final String region;
  final String province;
  final SchoolType type;

  /// Stand-in for the school's crest until real crest images exist.
  final Color color;
  final List<Sport> sports;
  final int athletes;
  final int joinedDaysAgo;
  final bool featured;

  String get initials => name.split(' ').take(2).map((word) => word[0]).join().toUpperCase();

  /// e.g. Sandton, Gauteng
  String get location => '$town, $province';
}

class Fixture {
  const Fixture({
    required this.sport,
    required this.ageGroup,
    required this.league,
    required this.home,
    required this.away,
    required this.startsAt,
    this.id,
    this.venueName,
  });

  /// The backend's id; null for sample data.
  final int? id;

  /// The venue the backend has, if any. Otherwise it is worked out from the home school.
  final String? venueName;

  final Sport sport;
  final String ageGroup;
  final String league;
  final School home;
  final School away;
  final DateTime startsAt;

  String get venue => (venueName != null && venueName!.trim().isNotEmpty) ? venueName! : '${home.name} Sports Ground';

  /// e.g. FOOTBALL U/19
  String get competition => '${sport.label} $ageGroup'.toUpperCase();
}

class MatchResult {
  const MatchResult(this.fixture, this.homeScore, this.awayScore);

  final Fixture fixture;
  final int homeScore;
  final int awayScore;

  bool get isDraw => homeScore == awayScore;
  bool get homeWon => homeScore > awayScore;
  bool get awayWon => awayScore > homeScore;
}

enum TeamSide { home, away }

enum MatchOutcome {
  win('W'),
  draw('D'),
  loss('L');

  const MatchOutcome(this.letter);

  final String letter;
}

class SchoolStanding {
  SchoolStanding(this.school);

  final School school;
  int won = 0, drawn = 0, lost = 0, scored = 0, conceded = 0, cleanSheets = 0;

  /// Outcomes, most recent first.
  final form = <MatchOutcome>[];

  int get played => won + drawn + lost;
  int get points => won * 3 + drawn;
  int get scoreDifference => scored - conceded;

  /// Adds one match, seen from this school's side. Record newest matches first.
  void record(int scoredInMatch, int concededInMatch) {
    scored += scoredInMatch;
    conceded += concededInMatch;
    if (concededInMatch == 0) cleanSheets++;

    final outcome = scoredInMatch > concededInMatch
        ? MatchOutcome.win
        : scoredInMatch == concededInMatch
            ? MatchOutcome.draw
            : MatchOutcome.loss;
    switch (outcome) {
      case MatchOutcome.win:
        won++;
      case MatchOutcome.draw:
        drawn++;
      case MatchOutcome.loss:
        lost++;
    }
    form.add(outcome);
  }
}

enum RankingType {
  schools('Schools', Icons.school_outlined),
  teams('Teams', Icons.groups_outlined),
  athletes('Athletes', Icons.directions_run),
  regions('Regions', Icons.map_outlined);

  const RankingType(this.label, this.icon);

  final String label;
  final IconData icon;
}

class RankingEntry {
  RankingEntry({
    required this.key,
    required this.title,
    required this.region,
    this.subtitle,
    this.school,
  });

  final String key;
  final String title;
  final String region;
  final String? subtitle;

  /// Null for region rankings.
  final School? school;

  int points = 0;
  int played = 0;
  final sports = <Sport>{};
  final schools = <School>{};

  /// Places gained (positive) or lost (negative) compared with a week ago.
  int trend = 0;
}
