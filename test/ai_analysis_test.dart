import 'package:flutter_test/flutter_test.dart';
import 'package:website/ai/ai_service.dart';
import 'package:website/ai/local_ai_service.dart';
import 'package:website/data/models.dart';
import 'package:website/data/sports_data.dart';

/// A finished match, for building controlled histories.
MatchResult _played(
  School home,
  School away,
  int homeScore,
  int awayScore, {
  required Sport sport,
  required int daysAgo,
}) {
  return MatchResult(
    Fixture(
      sport: sport,
      ageGroup: 'U/19',
      league: 'Schools Cup',
      home: home,
      away: away,
      startsAt: DateTime(2026, 6, 1).subtract(Duration(days: daysAgo)),
    ),
    homeScore,
    awayScore,
  );
}

Fixture _upcoming(School home, School away, Sport sport) => Fixture(
      sport: sport,
      ageGroup: 'U/19',
      league: 'Schools Cup',
      home: home,
      away: away,
      startsAt: DateTime(2026, 6, 8),
    );

void main() {
  final strong = SportsData.schools[0];
  final weak = SportsData.schools[1];
  final filler = SportsData.schools[2];

  group('against the sample data', () {
    const ai = LocalAiService();
    final fixtures = SportsData.instance.fixtures;

    test('every upcoming fixture produces a usable analysis', () {
      expect(fixtures, isNotEmpty, reason: 'sample data should contain fixtures to analyse');

      for (final fixture in fixtures) {
        final analysis = ai.analyzeFixtureSync(fixture);
        final total = analysis.homeWinChance + analysis.drawChance + analysis.awayWinChance;

        expect(total, closeTo(1, 1e-9), reason: 'the three outcomes should account for all of it');
        for (final chance in [
          analysis.homeWinChance,
          analysis.drawChance,
          analysis.awayWinChance,
        ]) {
          expect(chance, inInclusiveRange(0, 1));
        }

        expect(analysis.predictedHomeScore, greaterThanOrEqualTo(0));
        expect(analysis.predictedAwayScore, greaterThanOrEqualTo(0));
        expect(analysis.factors, isNotEmpty, reason: 'a prediction should always show its reasoning');
        expect(analysis.verdict, isNotEmpty);
      }
    });

    test('form only counts the fixture\'s own sport and respects the window', () {
      for (final fixture in fixtures.take(40)) {
        final analysis = ai.analyzeFixtureSync(fixture);
        for (final form in [analysis.homeForm, analysis.awayForm]) {
          expect(form.played, lessThanOrEqualTo(8));
          expect(form.outcomes.length, form.played);
          expect(form.won + form.drawn + form.lost, form.played);
          if (form.played > 0) {
            expect(form.averageScored, greaterThanOrEqualTo(0));
            expect(form.pointsPerGame, inInclusiveRange(0, 3));
          }
        }
      }
    });

    test('head-to-head only counts meetings between the two schools', () {
      for (final fixture in fixtures.take(40)) {
        final h2h = ai.analyzeFixtureSync(fixture).headToHead;
        expect(h2h.meetings, h2h.homeWins + h2h.awayWins + h2h.draws);

        final last = h2h.lastMeeting;
        if (last != null) {
          expect(last.fixture.sport, fixture.sport);
          expect({last.fixture.home, last.fixture.away}, {fixture.home, fixture.away});
        } else {
          expect(h2h.meetings, 0);
        }
      }
    });

    test('the reasoning on show supports the call it sits next to', () {
      // The sidebar shows only the top two factors, so it is not enough for a
      // supporting reason to exist somewhere down the list: one has to be high
      // enough up to be visible, or the card contradicts itself.
      var checked = 0;
      for (final fixture in fixtures) {
        final analysis = ai.analyzeFixtureSync(fixture);
        final favoured = analysis.favoured;
        if (favoured == null) continue;
        if (analysis.homeForm.played < 2 || analysis.awayForm.played < 2) continue;

        checked++;
        expect(
          analysis.factors.take(2).any((factor) => factor.lean == favoured),
          isTrue,
          reason: '${fixture.home.name} vs ${fixture.away.name}: favours $favoured but the '
              'top two reasons are '
              '${analysis.factors.take(2).map((f) => '${f.headline} (${f.lean})').toList()}',
        );
      }
      expect(checked, greaterThan(0));
    });

    test('no sport comes out systematically skewed', () {
      // Sample scores are drawn evenly, so no sport should sit far off a
      // coin toss on average. A sport that does means its scale is wrong.
      final bySport = <Sport, List<double>>{};
      for (final fixture in fixtures) {
        final analysis = ai.analyzeFixtureSync(fixture);
        bySport.putIfAbsent(fixture.sport, () => []).add(analysis.homeWinChance);
      }

      for (final entry in bySport.entries) {
        final average = entry.value.reduce((a, b) => a + b) / entry.value.length;
        expect(
          average,
          inInclusiveRange(0.25, 0.75),
          reason: '${entry.key.label} home chances average $average, which looks skewed',
        );
      }
    });
  });

  group('summaries and picks', () {
    const ai = LocalAiService();
    final results = SportsData.instance.results;
    final fixtures = SportsData.instance.fixtures;

    test('a recap reads every match it is handed', () {
      final recent = results.take(30).toList();
      final summary = ai.summarizeResultsSync(recent);

      expect(summary.sampleSize, recent.length);
      expect(summary.headline, isNotEmpty);
      expect(summary.insights, isNotEmpty);
      expect(summary.insights.length, lessThanOrEqualTo(4));
      for (final insight in summary.insights) {
        expect(insight.headline, isNotEmpty);
        expect(insight.detail, isNotEmpty);
      }
    });

    test('a recap of nothing says so rather than inventing one', () {
      final summary = ai.summarizeResultsSync([]);
      expect(summary.isEmpty, isTrue);
      expect(summary.sampleSize, 0);
      expect(summary.insights, isEmpty);
    });

    test('a table read names the leader and counts what it read', () {
      final football = results.where((r) => r.fixture.sport == Sport.football).toList();
      final standings = SportsData.standingsFor(football);
      final summary = ai.summarizeStandingsSync(standings, Sport.football);

      expect(summary.headline, contains(standings.first.school.name));
      expect(summary.insights, isNotEmpty);
      expect(summary.insights.first.headline, contains(standings.first.school.name));
      expect(summary.sampleSize, football.length, reason: 'each match counts once, though two schools played it');
    });

    test('a table with nobody in it does not pretend to have a leader', () {
      final summary = ai.summarizeStandingsSync([], Sport.football);
      expect(summary.isEmpty, isTrue);
      expect(summary.sampleSize, 0);
    });

    test('picks come back ranked, within the limit, and each says why', () {
      final picks = ai.recommendFixturesSync(fixtures, limit: 3);

      expect(picks.length, lessThanOrEqualTo(3));
      expect(picks, isNotEmpty, reason: 'the sample data should offer something worth watching');
      for (final pick in picks) {
        expect(pick.reason, isNotEmpty);
        expect(pick.score, inInclusiveRange(0, 1));
        expect(fixtures, contains(pick.fixture));
      }
      for (var i = 1; i < picks.length; i++) {
        expect(picks[i - 1].score, greaterThanOrEqualTo(picks[i].score));
      }
    });

    test('picks skip fixtures with no form to go on', () {
      // weak has never played, so nothing involving it can be recommended.
      final history = [
        for (var i = 0; i < 6; i++)
          _played(strong, filler, 3, 1, sport: Sport.football, daysAgo: i),
      ];
      final picks = LocalAiService(history: history).recommendFixturesSync([
        _upcoming(strong, weak, Sport.football),
        _upcoming(strong, filler, Sport.football),
      ]);

      expect(picks, hasLength(1));
      expect(picks.single.fixture.away, filler);
    });

    test('an evenly matched fixture outranks a mismatch', () {
      final history = [
        for (var i = 0; i < 8; i++) ...[
          // strong and filler trade results; weak loses everything.
          _played(strong, filler, 2, 1, sport: Sport.football, daysAgo: i * 3),
          _played(filler, strong, 2, 1, sport: Sport.football, daysAgo: i * 3 + 1),
          _played(filler, weak, 4, 0, sport: Sport.football, daysAgo: i * 3 + 2),
        ],
      ];
      final picks = LocalAiService(history: history).recommendFixturesSync([
        _upcoming(strong, weak, Sport.football),
        _upcoming(strong, filler, Sport.football),
      ], limit: 2);

      expect(picks, hasLength(2));
      expect(
        picks.first.fixture.away,
        filler,
        reason: 'the close one should be the better watch',
      );
    });
  });

  group('with a controlled history', () {
    /// A one-sided run: [strong] wins every match, [weak] loses every match,
    /// both against [filler], so neither has met the other.
    List<MatchResult> lopsided(Sport sport, {required int winBy, required int baseline}) {
      return [
        for (var i = 0; i < 8; i++) ...[
          _played(strong, filler, baseline + winBy, baseline, sport: sport, daysAgo: i * 2),
          _played(filler, weak, baseline + winBy, baseline, sport: sport, daysAgo: i * 2 + 1),
        ],
      ];
    }

    test('the clearly better side is favoured, in every sport', () {
      // The winning margin is scaled to the sport so the test means the same
      // thing for football as it does for cricket.
      const margins = {
        Sport.football: (winBy: 3, baseline: 1),
        Sport.rugby: (winBy: 20, baseline: 15),
        Sport.netball: (winBy: 15, baseline: 25),
        Sport.basketball: (winBy: 25, baseline: 50),
        Sport.cricket: (winBy: 70, baseline: 120),
        Sport.hockey: (winBy: 3, baseline: 1),
        Sport.swimming: (winBy: 30, baseline: 60),
        Sport.volleyball: (winBy: 2, baseline: 1),
      };

      for (final entry in margins.entries) {
        final sport = entry.key;
        final ai = LocalAiService(
          history: lopsided(sport, winBy: entry.value.winBy, baseline: entry.value.baseline),
        );

        final analysis = ai.analyzeFixtureSync(_upcoming(strong, weak, sport));
        expect(
          analysis.homeWinChance,
          greaterThan(analysis.awayWinChance),
          reason: '${sport.label}: the side that wins every match should be favoured',
        );
        expect(analysis.favoured, AiLean.home, reason: '${sport.label}: should not read as a toss-up');

        // And the same match the other way round must flip, not just drift.
        final reversed = ai.analyzeFixtureSync(_upcoming(weak, strong, sport));
        expect(
          reversed.awayWinChance,
          greaterThan(reversed.homeWinChance),
          reason: '${sport.label}: home advantage should not outweigh a gulf in form',
        );
      }
    });

    test('evenly matched sides come out near a coin toss', () {
      final history = [
        for (var i = 0; i < 8; i++) ...[
          _played(strong, filler, 2, 2, sport: Sport.football, daysAgo: i * 2),
          _played(filler, weak, 2, 2, sport: Sport.football, daysAgo: i * 2 + 1),
        ],
      ];
      final ai = LocalAiService(history: history);
      final analysis = ai.analyzeFixtureSync(_upcoming(strong, weak, Sport.football));

      expect((analysis.homeWinChance - analysis.awayWinChance).abs(), lessThan(0.15));
      expect(analysis.drawChance, greaterThan(0.3), reason: 'a history of nothing but draws should show');
    });

    test('head-to-head is read from both venues', () {
      final history = [
        _played(strong, weak, 3, 0, sport: Sport.football, daysAgo: 2),
        _played(weak, strong, 0, 2, sport: Sport.football, daysAgo: 9), // strong won away
        _played(strong, weak, 1, 1, sport: Sport.football, daysAgo: 16),
      ];
      final h2h = LocalAiService(history: history)
          .analyzeFixtureSync(_upcoming(strong, weak, Sport.football))
          .headToHead;

      expect(h2h.meetings, 3);
      expect(h2h.homeWins, 2, reason: 'both of those wins belong to the side listed at home');
      expect(h2h.awayWins, 0);
      expect(h2h.draws, 1);
      expect(h2h.lastMeeting?.fixture.startsAt, DateTime(2026, 6, 1).subtract(const Duration(days: 2)));
    });

    test('a side with no history does not break the analysis', () {
      final history = [
        for (var i = 0; i < 4; i++)
          _played(strong, filler, 3, 1, sport: Sport.football, daysAgo: i),
      ];
      final analysis = LocalAiService(history: history)
          .analyzeFixtureSync(_upcoming(strong, weak, Sport.football));

      expect(analysis.awayForm.played, 0);
      expect(analysis.confidence, AiConfidence.low);
      expect(analysis.homeWinChance + analysis.drawChance + analysis.awayWinChance, closeTo(1, 1e-9));
      expect(analysis.factors, isNotEmpty);
    });

    test('the recap judges margins against the sport, not the raw number', () {
      // One cricket match won by 20 runs against a football match won 4-0. In
      // raw numbers cricket looks far more one-sided; measured against how each
      // sport normally scores, the football result is the rout.
      final history = [
        for (var i = 0; i < 6; i++) ...[
          _played(strong, filler, 150 + i * 10, 140 + i * 10, sport: Sport.cricket, daysAgo: i),
          _played(filler, weak, 2, 1, sport: Sport.football, daysAgo: i),
        ],
      ];
      final ai = LocalAiService(history: history);

      final summary = ai.summarizeResultsSync([
        _played(strong, filler, 160, 140, sport: Sport.cricket, daysAgo: 1),
        _played(weak, filler, 4, 0, sport: Sport.football, daysAgo: 1),
      ]);

      expect(summary.sampleSize, 2);
      expect(
        summary.insights.first.headline,
        contains(weak.name),
        reason: 'the 4-0 football win should read as the most one-sided result',
      );
    });

    test('an empty history still returns something sane', () {
      final analysis = const LocalAiService(history: [])
          .analyzeFixtureSync(_upcoming(strong, weak, Sport.football));

      expect(analysis.homeWinChance + analysis.drawChance + analysis.awayWinChance, closeTo(1, 1e-9));
      expect(analysis.confidence, AiConfidence.low);
      expect(analysis.factors, hasLength(1));
      expect(analysis.factors.single.lean, AiLean.neutral);
    });
  });
}
