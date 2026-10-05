import 'dart:math';

import '../data/models.dart';
import '../data/sports_data.dart';
import 'ai_service.dart';

/// Reads the match history that ships with the app and turns it into a
/// prediction with its reasoning attached.
///
/// Everything is measured against the sport being played rather than against
/// fixed numbers, because a score means something different in each one: a 3 is
/// a rout in football and a rounding error in cricket. Scoring rates, how often
/// matches are drawn and how much home advantage is worth are all read back out
/// of the results, so the model keeps up when the data behind it changes.
class LocalAiService implements AiService {
  /// Reads the app's own match history. Pass [history] (newest first) to run
  /// the model over a controlled set of results instead, as the tests do.
  // The field is private and Dart does not allow a private name as a named
  // parameter, so an initializing formal is not available here.
  // ignore: prefer_initializing_formals
  const LocalAiService({List<MatchResult>? history}) : _history = history;

  final List<MatchResult>? _history;

  /// Recent matches read per team. Long enough to be steady, short enough that
  /// a team's current run still moves it.
  static const _formWindow = 8;

  @override
  Future<MatchAnalysis> analyzeFixture(Fixture fixture) async => analyzeFixtureSync(fixture);

  /// The analysis itself. Separate from [analyzeFixture] so tests can read it
  /// without awaiting; the interface stays async for the backend swap.
  MatchAnalysis analyzeFixtureSync(Fixture fixture) {
    // Newest first, matching SportsData's ordering.
    final history = (_history ?? SportsData.instance.results)
        .where((result) => result.fixture.sport == fixture.sport)
        .toList(growable: false);

    final scale = _Scale.from(history);
    final homeForm = _formFor(fixture.home, history);
    final awayForm = _formFor(fixture.away, history);
    final headToHead = _headToHead(fixture, history);

    final edge = _rating(homeForm, scale) - _rating(awayForm, scale) +
        scale.homeAdvantage +
        _headToHeadEdge(headToHead);

    final (homeWinChance, drawChance, awayWinChance) = _chances(edge, scale);

    return MatchAnalysis(
      fixture: fixture,
      homeWinChance: homeWinChance,
      drawChance: drawChance,
      awayWinChance: awayWinChance,
      confidence: _confidence(homeForm, awayForm, headToHead),
      verdict: _verdict(fixture, homeWinChance, awayWinChance),
      predictedHomeScore: _expectedScore(homeForm, awayForm, scale, atHome: true),
      predictedAwayScore: _expectedScore(awayForm, homeForm, scale, atHome: false),
      homeForm: homeForm,
      awayForm: awayForm,
      headToHead: headToHead,
      factors: _factors(fixture, homeForm, awayForm, headToHead, scale),
    );
  }

  // --- the model -----------------------------------------------------------

  /// How good a team looks, in standard deviations of this sport's scoring.
  /// Mostly scoring margin, with recent results folded in so that a team
  /// grinding out narrow wins is not read as weak.
  static double _rating(TeamForm form, _Scale scale) {
    if (form.played == 0) return 0;
    final margin = (form.averageScored - form.averageConceded) / scale.deviation;
    final record = (form.pointsPerGame - 1.5) / 1.5; // -1 to 1
    return 0.7 * margin + 0.3 * record;
  }

  /// A small nudge for a one-sided history between these two schools, damped so
  /// a single past meeting cannot swing the call.
  static double _headToHeadEdge(HeadToHead h2h) {
    if (!h2h.hasHistory) return 0;
    final decided = h2h.homeWins + h2h.awayWins;
    if (decided == 0) return 0;
    final bias = (h2h.homeWins - h2h.awayWins) / decided; // -1 to 1
    final weight = min(h2h.meetings, 4) / 4;
    return 0.25 * bias * weight;
  }

  /// Splits the three outcomes. Draws start at the rate this sport actually
  /// draws at and thin out as the gap between the sides widens.
  static (double, double, double) _chances(double edge, _Scale scale) {
    final draw = scale.drawRate * exp(-0.6 * edge.abs());
    final decided = 1 - draw;
    final home = decided / (1 + exp(-1.8 * edge));
    return (home, draw, decided - home);
  }

  /// Blends what this team scores with what the opponent lets in.
  static int _expectedScore(
    TeamForm attack,
    TeamForm defence,
    _Scale scale, {
    required bool atHome,
  }) {
    final scored = attack.played == 0 ? scale.mean : attack.averageScored;
    final conceded = defence.played == 0 ? scale.mean : defence.averageConceded;
    final bump = atHome ? scale.deviation * 0.12 : 0.0;
    return max(0, ((scored + conceded) / 2 + bump).round());
  }

  static AiConfidence _confidence(TeamForm home, TeamForm away, HeadToHead h2h) {
    final depth = min(home.played, away.played);
    if (depth >= 6 && h2h.meetings >= 2) return AiConfidence.high;
    if (depth >= 3) return AiConfidence.medium;
    return AiConfidence.low;
  }

  static String _verdict(Fixture fixture, double home, double away) {
    final gap = (home - away).abs();
    final leader = home > away ? fixture.home : fixture.away;
    final atHome = home > away;

    if (gap < 0.05) return 'Too close to call';
    if (gap < 0.15) {
      return atHome ? '${leader.name} shade it at home' : '${leader.name} shade it on the road';
    }
    if (gap < 0.3) return '${leader.name} are the pick';
    return '${leader.name} are strong favourites';
  }

  // --- reading the history -------------------------------------------------

  static TeamForm _formFor(School school, List<MatchResult> history) {
    final outcomes = <MatchOutcome>[];
    var scored = 0;
    var conceded = 0;

    for (final result in history) {
      if (outcomes.length >= _formWindow) break;

      final isHome = result.fixture.home == school;
      if (!isHome && result.fixture.away != school) continue;

      final forScore = isHome ? result.homeScore : result.awayScore;
      final againstScore = isHome ? result.awayScore : result.homeScore;

      outcomes.add(switch (forScore.compareTo(againstScore)) {
        > 0 => MatchOutcome.win,
        0 => MatchOutcome.draw,
        _ => MatchOutcome.loss,
      });
      scored += forScore;
      conceded += againstScore;
    }

    final played = outcomes.length;
    return TeamForm(
      school: school,
      outcomes: outcomes,
      averageScored: played == 0 ? 0 : scored / played,
      averageConceded: played == 0 ? 0 : conceded / played,
    );
  }

  static HeadToHead _headToHead(Fixture fixture, List<MatchResult> history) {
    var homeWins = 0;
    var awayWins = 0;
    var draws = 0;
    MatchResult? lastMeeting;

    for (final result in history) {
      final playedHome = result.fixture.home;
      final playedAway = result.fixture.away;
      final samePair = (playedHome == fixture.home && playedAway == fixture.away) ||
          (playedHome == fixture.away && playedAway == fixture.home);
      if (!samePair) continue;

      lastMeeting ??= result; // history is newest first

      if (result.isDraw) {
        draws++;
      } else if ((result.homeWon ? playedHome : playedAway) == fixture.home) {
        homeWins++;
      } else {
        awayWins++;
      }
    }

    return HeadToHead(
      meetings: homeWins + awayWins + draws,
      homeWins: homeWins,
      awayWins: awayWins,
      draws: draws,
      lastMeeting: lastMeeting,
    );
  }

  // --- the reasoning shown to the reader -----------------------------------

  /// The strongest few drivers behind the call, each carrying the number it
  /// came from so a reader can check it rather than take it on trust.
  static List<AiFactor> _factors(
    Fixture fixture,
    TeamForm home,
    TeamForm away,
    HeadToHead h2h,
    _Scale scale,
  ) {
    final sport = fixture.sport.label.toLowerCase();
    final unit = fixture.sport.scoreLabel.toLowerCase();
    final candidates = <(double, AiFactor)>[];

    void add(double weight, String headline, String detail, AiLean lean) {
      candidates.add((weight, AiFactor(headline: headline, detail: detail, lean: lean)));
    }

    // Recent record.
    for (final (form, lean) in [(home, AiLean.home), (away, AiLean.away)]) {
      if (form.played < 3) continue;
      final gap = (form.pointsPerGame - 1.5).abs();
      if (form.won > form.lost) {
        add(
          gap,
          '${form.school.name} won ${form.won} of their last ${form.played}',
          'Taking ${form.pointsPerGame.toStringAsFixed(1)} points a game from that run.',
          lean,
        );
      } else if (form.lost > form.won) {
        add(
          gap,
          '${form.school.name} lost ${form.lost} of their last ${form.played}',
          'Down to ${form.pointsPerGame.toStringAsFixed(1)} points a game over that stretch.',
          lean == AiLean.home ? AiLean.away : AiLean.home,
        );
      }
    }

    // Scoring and defending, measured against this sport's average.
    for (final (form, lean) in [(home, AiLean.home), (away, AiLean.away)]) {
      if (form.played < 3) continue;

      final attackGap = (form.averageScored - scale.mean) / scale.deviation;
      if (attackGap.abs() >= 0.4) {
        add(
          attackGap.abs(),
          '${form.school.name} ${attackGap > 0 ? 'outscore' : 'undershoot'} the $sport average',
          '${form.averageScored.toStringAsFixed(1)} $unit a game against a league average of '
              '${scale.mean.toStringAsFixed(1)}.',
          attackGap > 0 ? lean : _flip(lean),
        );
      }

      final defenceGap = (scale.mean - form.averageConceded) / scale.deviation;
      if (defenceGap.abs() >= 0.4) {
        add(
          defenceGap.abs(),
          '${form.school.name} ${defenceGap > 0 ? 'keep it tight' : 'leak'} at the back',
          'Conceding ${form.averageConceded.toStringAsFixed(1)} $unit a game, league average '
              '${scale.mean.toStringAsFixed(1)}.',
          defenceGap > 0 ? lean : _flip(lean),
        );
      }
    }

    // Previous meetings.
    if (h2h.meetings >= 2 && h2h.homeWins != h2h.awayWins) {
      final leaderIsHome = h2h.homeWins > h2h.awayWins;
      final leader = leaderIsHome ? fixture.home : fixture.away;
      final wins = leaderIsHome ? h2h.homeWins : h2h.awayWins;
      add(
        0.4 + 0.1 * h2h.meetings,
        '${leader.name} lead the head-to-head $wins-${leaderIsHome ? h2h.awayWins : h2h.homeWins}',
        'Across ${h2h.meetings} meetings in $sport'
            '${h2h.draws > 0 ? ', with ${h2h.draws} drawn' : ''}.',
        leaderIsHome ? AiLean.home : AiLean.away,
      );
    }

    // Home advantage, but only where the results actually show one. In this
    // sample data they mostly do not, and inventing one would be a lie.
    if (scale.homeWinRate >= 0.52) {
      add(
        (scale.homeWinRate - 0.5) * 2,
        'Home sides win ${(scale.homeWinRate * 100).round()}% of $sport matches',
        '${fixture.home.name} host this one at ${fixture.venue}.',
        AiLean.home,
      );
    }

    candidates.sort((a, b) => b.$1.compareTo(a.$1));
    final factors = [for (final (_, factor) in candidates.take(4)) factor];

    if (factors.isEmpty) {
      factors.add(const AiFactor(
        headline: 'Not much to go on yet',
        detail: 'These sides have barely played this season, so the model is close to a coin toss.',
        lean: AiLean.neutral,
      ));
    }
    return factors;
  }

  static AiLean _flip(AiLean lean) => switch (lean) {
        AiLean.home => AiLean.away,
        AiLean.away => AiLean.home,
        AiLean.neutral => AiLean.neutral,
      };
}

/// What "normal" looks like in one sport: how much gets scored, how often
/// matches are drawn, and how much it is worth being at home. Derived from the
/// results rather than hard-coded, so these stay right as the data changes.
class _Scale {
  const _Scale({
    required this.mean,
    required this.deviation,
    required this.drawRate,
    required this.homeWinRate,
  });

  factory _Scale.from(List<MatchResult> history) {
    if (history.isEmpty) {
      return const _Scale(mean: 0, deviation: 1, drawRate: 0.15, homeWinRate: 0.5);
    }

    final scores = [
      for (final result in history) ...[result.homeScore, result.awayScore],
    ];
    final mean = scores.reduce((a, b) => a + b) / scores.length;
    final variance =
        scores.map((score) => pow(score - mean, 2).toDouble()).reduce((a, b) => a + b) / scores.length;
    final deviation = sqrt(variance);

    return _Scale(
      mean: mean,
      deviation: deviation <= 0 ? 1 : deviation,
      drawRate: history.where((result) => result.isDraw).length / history.length,
      homeWinRate: history.where((result) => result.homeWon).length / history.length,
    );
  }

  /// Average score by one team in one match.
  final double mean;

  /// Spread of those scores, used to put every sport on one footing.
  final double deviation;
  final double drawRate;
  final double homeWinRate;

  /// Home advantage expressed in the same units as a team rating.
  double get homeAdvantage => (homeWinRate - (1 - drawRate - homeWinRate)) * 0.5;
}
