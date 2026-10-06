import 'dart:math';

import 'package:flutter/material.dart';

import '../data/models.dart';
import '../data/sports_data.dart';
import 'ai_service.dart';
import 'local_assistant.dart';

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

  /// How many candidate fixtures recommendFixtures will analyse. Each one costs
  /// a full pass over the history, so the pool is capped.
  static const _pickPool = 40;

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

  @override
  Future<AiSummary> summarizeResults(List<MatchResult> results) async =>
      summarizeResultsSync(results);

  /// Reads a set of finished matches and says what stood out.
  ///
  /// Margins are compared within their own sport, so a three-goal football win
  /// is not weighed against a three-run cricket win.
  AiSummary summarizeResultsSync(List<MatchResult> results) {
    if (results.isEmpty) {
      return const AiSummary(headline: 'Nothing to read yet', insights: [], sampleSize: 0);
    }

    // Scale each sport against the full history rather than against the subset
    // being summarised. A filter showing one cricket match would otherwise give
    // cricket no measurable spread, and that single match would swamp the rest.
    final all = _history ?? SportsData.instance.results;
    final scaleBySport = <Sport, _Scale>{};
    _Scale scaleFor(Sport sport) => scaleBySport.putIfAbsent(
          sport,
          () => _Scale.from(all.where((r) => r.fixture.sport == sport).toList(growable: false)),
        );

    // The most one-sided match, judged against its own sport's spread.
    MatchResult? widest;
    var widestMargin = 0.0;
    for (final result in results) {
      final margin = (result.homeScore - result.awayScore).abs() / scaleFor(result.fixture.sport).deviation;
      if (margin > widestMargin) {
        widestMargin = margin;
        widest = result;
      }
    }

    final sports = results.map((r) => r.fixture.sport).toSet();
    final draws = results.where((r) => r.isDraw).length;
    final oneScore = results.where((r) {
      final margin = (r.homeScore - r.awayScore).abs();
      return margin > 0 && margin / scaleFor(r.fixture.sport).deviation <= 0.5;
    }).length;
    final shutouts = results.where((r) => r.homeScore == 0 || r.awayScore == 0).length;

    // Who won the most across the set.
    final wins = <School, int>{};
    for (final result in results) {
      if (result.isDraw) continue;
      final winner = result.homeWon ? result.fixture.home : result.fixture.away;
      wins[winner] = (wins[winner] ?? 0) + 1;
    }
    final topWinner = wins.entries.fold<MapEntry<School, int>?>(
      null,
      (best, entry) => best == null || entry.value > best.value ? entry : best,
    );

    final insights = <AiInsight>[
      if (widest != null)
        AiInsight(
          icon: Icons.trending_up,
          headline: '${widest.fixture.home.name} ${widest.homeScore}-${widest.awayScore} '
              '${widest.fixture.away.name}',
          detail: 'The most one-sided result here, in '
              '${widest.fixture.sport.label.toLowerCase()}.',
        ),
      if (topWinner != null && topWinner.value > 1)
        AiInsight(
          icon: Icons.emoji_events_outlined,
          headline: '${topWinner.key.name} won ${topWinner.value} of them',
          detail: 'More than any other school across these matches.',
        ),
      if (oneScore > 0)
        AiInsight(
          icon: Icons.compare_arrows,
          headline: '$oneScore ${_plural(oneScore, 'match', 'matches')} came down to the wire',
          detail: 'Decided by a margin well inside what these sports normally swing by.',
        ),
      if (draws > 0)
        AiInsight(
          icon: Icons.handshake_outlined,
          headline: '$draws ended level',
          detail: '${(draws / results.length * 100).round()}% of the matches read here.',
        ),
      if (shutouts > 0)
        AiInsight(
          icon: Icons.shield_outlined,
          headline: '$shutouts ${_plural(shutouts, 'side', 'sides')} kept a clean sheet',
          detail: 'Held their opponent scoreless.',
        ),
    ];

    return AiSummary(
      headline: _resultsHeadline(results, sports.length, topWinner),
      insights: insights.take(4).toList(growable: false),
      sampleSize: results.length,
    );
  }

  static String _resultsHeadline(
    List<MatchResult> results,
    int sportCount,
    MapEntry<School, int>? topWinner,
  ) {
    final matches = '${results.length} ${_plural(results.length, 'match', 'matches')}';
    final across = sportCount == 1 ? '' : ' across $sportCount sports';
    if (topWinner != null && topWinner.value > 2) {
      return '$matches$across, with ${topWinner.key.name} the standout';
    }
    return '$matches$across, and no one side ran away with it';
  }

  @override
  Future<AiSummary> summarizeStandings(List<SchoolStanding> standings, Sport sport) async =>
      summarizeStandingsSync(standings, sport);

  /// Reads a league table: who leads, by how much, and who is moving.
  AiSummary summarizeStandingsSync(List<SchoolStanding> standings, Sport sport) {
    final played = standings.where((standing) => standing.played > 0).toList(growable: false);
    if (played.length < 2) {
      return const AiSummary(headline: 'Not enough played yet', insights: [], sampleSize: 0);
    }

    final unit = sport.scoreLabel.toLowerCase();
    final leader = played.first;
    final second = played[1];
    final gap = leader.points - second.points;

    // A points lead means less when the sides have played a different number of
    // matches. Comparing the rate catches a leader who is only ahead on volume.
    final leaderRate = leader.points / leader.played;
    final secondRate = second.points / second.played;
    final chased = second.played < leader.played && secondRate > leaderRate;

    final bestAttack = played.reduce((a, b) => a.scored / a.played > b.scored / b.played ? a : b);
    final bestDefence = played.reduce((a, b) => a.conceded / a.played < b.conceded / b.played ? a : b);

    // Form over the most recent matches each side has played.
    SchoolStanding? hottest;
    var hottestPoints = -1.0;
    for (final standing in played) {
      final recent = standing.form.take(5);
      if (recent.length < 3) continue;
      final points = recent.fold<int>(
            0,
            (sum, outcome) => sum + switch (outcome) {
              MatchOutcome.win => 3,
              MatchOutcome.draw => 1,
              MatchOutcome.loss => 0,
            },
          ) /
          recent.length;
      if (points > hottestPoints) {
        hottestPoints = points;
        hottest = standing;
      }
    }

    final insights = <AiInsight>[
      AiInsight(
        icon: Icons.emoji_events_outlined,
        headline: gap == 0
            ? '${leader.school.name} lead on score difference'
            : '${leader.school.name} lead by $gap ${_plural(gap, 'point', 'points')}',
        detail: gap == 0
            ? 'Level with ${second.school.name} on ${leader.points} points.'
            : '${leader.points} points from ${leader.played} played, '
                'ahead of ${second.school.name}.',
      ),
      if (chased)
        AiInsight(
          icon: Icons.schedule,
          headline: '${second.school.name} have ${leader.played - second.played} '
              '${_plural(leader.played - second.played, 'match', 'matches')} in hand',
          detail: 'And a better return while they are at it: '
              '${secondRate.toStringAsFixed(1)} points a game against '
              '${leaderRate.toStringAsFixed(1)}.',
        )
      else if (gap <= 3)
        AiInsight(
          icon: Icons.local_fire_department_outlined,
          headline: 'The title race is still live',
          detail: 'Only $gap ${_plural(gap, 'point', 'points')} separate the top two with '
              'matches still to play.',
        ),
      AiInsight(
        icon: Icons.sports_score,
        headline: '${bestAttack.school.name} score the most',
        detail: '${(bestAttack.scored / bestAttack.played).toStringAsFixed(1)} $unit a game.',
      ),
      AiInsight(
        icon: Icons.shield_outlined,
        headline: '${bestDefence.school.name} concede the fewest',
        detail: '${(bestDefence.conceded / bestDefence.played).toStringAsFixed(1)} $unit a game'
            '${bestDefence.cleanSheets > 0 ? ', with ${bestDefence.cleanSheets} clean sheets' : ''}.',
      ),
      if (hottest != null && hottest != leader && hottestPoints >= 2)
        AiInsight(
          icon: Icons.trending_up,
          headline: '${hottest.school.name} are the form side',
          detail: 'Taking ${hottestPoints.toStringAsFixed(1)} points a game from their recent run.',
        ),
    ];

    return AiSummary(
      headline: switch ((chased, gap <= 3)) {
        (true, _) => '${leader.school.name} lead, but the chasers have games in hand',
        (false, true) => '${leader.school.name} edge it at the top, but only just',
        (false, false) => '${leader.school.name} are pulling clear',
      },
      insights: insights.take(4).toList(growable: false),
      sampleSize: played.fold(0, (sum, standing) => sum + standing.played),
    );
  }

  @override
  Future<List<AiPick>> recommendFixtures(List<Fixture> candidates, {int limit = 4}) async =>
      recommendFixturesSync(candidates, limit: limit);

  /// Ranks fixtures by how worth watching they look.
  ///
  /// A good watch is a close match between two sides in decent form, ideally
  /// with some history behind it. Scanning every candidate means running the
  /// full analysis on each, so this reads at most [_pickPool] of them.
  List<AiPick> recommendFixturesSync(List<Fixture> candidates, {int limit = 4}) {
    final picks = <AiPick>[];

    for (final fixture in candidates.take(_pickPool)) {
      final analysis = analyzeFixtureSync(fixture);
      final homeForm = analysis.homeForm;
      final awayForm = analysis.awayForm;
      if (homeForm.played == 0 || awayForm.played == 0) continue;

      // Evenly matched sides make the better watch.
      final closeness = 1 - (analysis.homeWinChance - analysis.awayWinChance).abs();
      // As do two sides who are actually winning matches.
      final quality = ((homeForm.pointsPerGame + awayForm.pointsPerGame) / 2) / 3;
      final history = min(analysis.headToHead.meetings, 3) / 3;

      picks.add(AiPick(
        fixture: fixture,
        score: 0.45 * closeness + 0.35 * quality + 0.2 * history,
        reason: _pickReason(analysis, closeness, quality),
      ));
    }

    picks.sort((a, b) => b.score.compareTo(a.score));
    return picks.take(limit).toList(growable: false);
  }

  static String _pickReason(MatchAnalysis analysis, double closeness, double quality) {
    final h2h = analysis.headToHead;
    final homeForm = analysis.homeForm;
    final awayForm = analysis.awayForm;

    if (closeness > 0.9) {
      return 'The model cannot separate them: '
          '${(analysis.homeWinChance * 100).round()}% against '
          '${(analysis.awayWinChance * 100).round()}%.';
    }
    if (quality > 0.6) {
      return 'Two in-form sides: ${homeForm.won} wins from ${homeForm.played} against '
          '${awayForm.won} from ${awayForm.played}.';
    }
    if (h2h.meetings >= 2) {
      final last = h2h.lastMeeting;
      return 'They have met ${h2h.meetings} times'
          '${last == null ? '' : ', last out ${last.homeScore}-${last.awayScore}'}.';
    }
    return analysis.verdict;
  }

  static String _plural(int count, String one, String many) => count == 1 ? one : many;

  /// e.g. +1.4 or -0.8, so a margin reads as a margin.
  static String _signed(double value) =>
      '${value >= 0 ? '+' : ''}${value.toStringAsFixed(1)}';

  @override
  Future<AiAnswer> ask(String question) async => LocalAssistant(this).answer(question);

  @override
  List<String> starterQuestions() => LocalAssistant(this).starterQuestions();

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

    // The comparison the rating actually turns on. This is always a candidate
    // and outranks the rest, because without it a single loud factor pointing
    // the other way can end up as the only thing shown next to a call it
    // disagrees with, which reads as a contradiction.
    if (home.played >= 2 && away.played >= 2) {
      final homeMargin = home.averageScored - home.averageConceded;
      final awayMargin = away.averageScored - away.averageConceded;
      final difference = (homeMargin - awayMargin) / scale.deviation;

      if (difference.abs() >= 0.15) {
        final ahead = difference > 0 ? home : away;
        final behind = difference > 0 ? away : home;
        add(
          0.5 + difference.abs(),
          '${ahead.school.name} carry the better margin',
          '${_signed(ahead.averageScored - ahead.averageConceded)} $unit a game against '
              '${_signed(behind.averageScored - behind.averageConceded)} for '
              '${behind.school.name}.',
          difference > 0 ? AiLean.home : AiLean.away,
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
