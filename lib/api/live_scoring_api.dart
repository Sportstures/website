import 'api_client.dart';
import 'fixture_management_api.dart';

/// One goal (or other score) in a match, as the signed-in person sees it.
class LiveGoal {
  const LiveGoal({
    required this.id,
    required this.teamName,
    required this.points,
    required this.status,
    this.minute,
    this.playerName,
    this.addedBy,
    this.disputeReason,
    this.autoConfirmed = false,
    this.canConfirm = false,
    this.canDispute = false,
    this.canDelete = false,
  });

  final int id;
  final String teamName;
  final int points;

  /// `pending` (not counted yet), `confirmed` (counted) or `disputed` (not counted).
  final String status;
  final int? minute;
  final String? playerName;
  final String? addedBy;
  final String? disputeReason;
  final bool autoConfirmed;
  final bool canConfirm;
  final bool canDispute;
  final bool canDelete;

  factory LiveGoal.fromJson(Map<String, dynamic> json) {
    String? name(String key) => json[key] is Map ? (json[key] as Map)['name'] as String? : null;
    return LiveGoal(
      id: json['id'] as int,
      teamName: name('team') ?? '',
      points: json['points'] as int? ?? 1,
      status: '${json['status']}',
      minute: json['minute'] as int?,
      playerName: name('player'),
      addedBy: name('addedBy'),
      disputeReason: json['disputeReason'] as String?,
      autoConfirmed: json['autoConfirmed'] == true,
      canConfirm: json['canConfirm'] == true,
      canDispute: json['canDispute'] == true,
      canDelete: json['canDelete'] == true,
    );
  }
}

/// The whole match, which every scoring call answers with.
class LiveMatch {
  const LiveMatch({
    required this.fixture,
    required this.goals,
    required this.homeScore,
    required this.awayScore,
    required this.homePending,
    required this.awayPending,
  });

  final ManagedFixture fixture;

  /// In match order.
  final List<LiveGoal> goals;

  /// Confirmed goals only.
  final int homeScore;
  final int awayScore;

  /// How many goals on each side still wait for the other coach.
  final int homePending;
  final int awayPending;

  factory LiveMatch.fromJson(Map<String, dynamic> json) {
    int side(String key, String name) => json[key] is Map ? ((json[key] as Map)[name] as int? ?? 0) : 0;
    return LiveMatch(
      fixture: ManagedFixture.fromJson(Map<String, dynamic>.from(json['fixture'] as Map)),
      goals: [for (final g in json['goals'] as List) LiveGoal.fromJson(Map<String, dynamic>.from(g as Map))],
      homeScore: side('score', 'home'),
      awayScore: side('score', 'away'),
      homePending: side('pending', 'home'),
      awayPending: side('pending', 'away'),
    );
  }
}

class LiveScoringApi {
  LiveScoringApi(this._client);

  final ApiClient _client;

  Future<LiveMatch> _read(Future<dynamic> call) async => LiveMatch.fromJson(await call as Map<String, dynamic>);

  Future<LiveMatch> match(int fixtureId) => _read(_client.get('/api/fixtures/$fixtureId/goals'));

  Future<LiveMatch> start(int fixtureId) => _read(_client.post('/api/fixtures/$fixtureId/start'));

  Future<LiveMatch> addGoal(int fixtureId, {required int teamId, int points = 1, int? minute, int? playerId}) =>
      _read(_client.post('/api/fixtures/$fixtureId/goals',
          body: {'teamId': teamId, 'points': points, 'minute': ?minute, 'playerId': ?playerId}));

  Future<LiveMatch> confirm(int fixtureId, int goalId) =>
      _read(_client.post('/api/fixtures/$fixtureId/goals/$goalId/confirm'));

  Future<LiveMatch> dispute(int fixtureId, int goalId, {String? reason}) => _read(_client.post(
      '/api/fixtures/$fixtureId/goals/$goalId/dispute',
      body: {if (reason != null && reason.isNotEmpty) 'reason': reason}));

  Future<LiveMatch> delete(int fixtureId, int goalId) => _read(_client.delete('/api/fixtures/$fixtureId/goals/$goalId'));

  /// Full time: goals still pending are counted.
  Future<LiveMatch> finish(int fixtureId) => _read(_client.post('/api/fixtures/$fixtureId/finish'));
}
