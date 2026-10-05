import '../data/models.dart';

/// How much history the analysis rests on. Shown next to every prediction so a
/// thin sample is never passed off as a confident call.
enum AiConfidence {
  low('Low confidence', 'Thin match history — treat this as a rough read.'),
  medium('Medium confidence', 'Enough history for a reasonable read.'),
  high('High confidence', 'Backed by a deep run of recent matches.');

  const AiConfidence(this.label, this.detail);

  final String label;
  final String detail;
}

/// Which side a factor points towards, used to colour it in the UI.
enum AiLean { home, away, neutral }

/// One explainable driver behind a prediction, e.g. "Won 4 of their last 6".
class AiFactor {
  const AiFactor({required this.headline, required this.detail, required this.lean});

  final String headline;
  final String detail;
  final AiLean lean;
}

/// A school's recent record in one sport.
class TeamForm {
  const TeamForm({
    required this.school,
    required this.outcomes,
    required this.averageScored,
    required this.averageConceded,
  });

  final School school;

  /// Most recent first, capped at the window the analyser reads.
  final List<MatchOutcome> outcomes;
  final double averageScored;
  final double averageConceded;

  int get played => outcomes.length;
  int get won => outcomes.where((o) => o == MatchOutcome.win).length;
  int get drawn => outcomes.where((o) => o == MatchOutcome.draw).length;
  int get lost => outcomes.where((o) => o == MatchOutcome.loss).length;

  /// League points per game, 0-3.
  double get pointsPerGame => played == 0 ? 0 : (won * 3 + drawn) / played;
}

/// The two schools' previous meetings in this sport.
class HeadToHead {
  const HeadToHead({
    required this.meetings,
    required this.homeWins,
    required this.awayWins,
    required this.draws,
    required this.lastMeeting,
  });

  final int meetings;

  /// Wins for the school listed at home in the fixture being analysed, counted
  /// across both venues.
  final int homeWins;
  final int awayWins;
  final int draws;

  /// Most recent previous meeting, or null if they have never met.
  final MatchResult? lastMeeting;

  bool get hasHistory => meetings > 0;
}

/// A full read on one upcoming fixture.
class MatchAnalysis {
  const MatchAnalysis({
    required this.fixture,
    required this.homeWinChance,
    required this.drawChance,
    required this.awayWinChance,
    required this.confidence,
    required this.verdict,
    required this.predictedHomeScore,
    required this.predictedAwayScore,
    required this.homeForm,
    required this.awayForm,
    required this.headToHead,
    required this.factors,
  });

  final Fixture fixture;

  /// The three outcome chances, each 0-1. They sum to 1.
  final double homeWinChance;
  final double drawChance;
  final double awayWinChance;

  final AiConfidence confidence;

  /// One-line plain-English call, e.g. "Northview High edge it at home".
  final String verdict;

  final int predictedHomeScore;
  final int predictedAwayScore;

  final TeamForm homeForm;
  final TeamForm awayForm;
  final HeadToHead headToHead;
  final List<AiFactor> factors;

  /// The side the model favours, or null when it is effectively a coin toss.
  AiLean? get favoured {
    if ((homeWinChance - awayWinChance).abs() < 0.05) return null;
    return homeWinChance > awayWinChance ? AiLean.home : AiLean.away;
  }

  String get predictedScoreline => '$predictedHomeScore - $predictedAwayScore';
}

/// The seam between the site and whatever is doing the thinking.
///
/// [LocalAiService] implements this against the sample data that ships with the
/// app. When `Sportstures/backend-` exposes its AI endpoints, add a
/// `BackendAiService` alongside it and change the single binding in
/// `ai_provider.dart` - no page or widget needs to change. The Claude API call
/// belongs on that backend and not here: a Flutter web bundle is public, so an
/// API key placed in this package would be readable by anyone who opens
/// DevTools.
abstract interface class AiService {
  /// Reads an upcoming fixture and returns a prediction with its reasoning.
  Future<MatchAnalysis> analyzeFixture(Fixture fixture);
}
