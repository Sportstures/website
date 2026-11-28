import 'api_client.dart';
import 'coach_api.dart';

/// One of my team's matches, with what is needed to change it.
class ManagedFixture {
  const ManagedFixture({
    required this.id,
    required this.startsAt,
    required this.status,
    required this.matchType,
    required this.homeTeamId,
    required this.awayTeamId,
    required this.homeName,
    required this.awayName,
    this.venue,
    this.competition,
    this.homeLineupIn = false,
    this.awayLineupIn = false,
  });

  final int id;
  final DateTime startsAt;

  /// `scheduled`, `live`, `postponed`, `cancelled` or `finished`.
  final String status;
  final String matchType;
  final int homeTeamId;
  final int awayTeamId;
  final String homeName;
  final String awayName;
  final String? venue;
  final String? competition;
  final bool homeLineupIn;
  final bool awayLineupIn;

  bool isHome(int teamId) => teamId == homeTeamId;
  String opponentOf(int teamId) => isHome(teamId) ? awayName : homeName;
  bool lineupIn(int teamId) => isHome(teamId) ? homeLineupIn : awayLineupIn;

  /// A live or finished match can no longer be edited.
  bool get canChange => status == 'scheduled' || status == 'postponed' || status == 'cancelled';

  /// Lineups close once a match is finished or cancelled.
  bool get takesLineup => status != 'finished' && status != 'cancelled';

  factory ManagedFixture.fromJson(Map<String, dynamic> json) {
    final base = CoachFixture.fromJson(json);
    final submitted = json['lineupSubmitted'];
    return ManagedFixture(
      id: base.id,
      startsAt: base.startsAt,
      status: base.status,
      matchType: '${json['matchType'] ?? 'friendly'}',
      homeTeamId: base.homeTeamId,
      awayTeamId: base.awayTeamId,
      homeName: base.homeName,
      awayName: base.awayName,
      venue: base.venue,
      competition: base.competition,
      homeLineupIn: submitted is Map && submitted['home'] == true,
      awayLineupIn: submitted is Map && submitted['away'] == true,
    );
  }
}

/// Where a player is on the match sheet.
enum LineupSlot { out, starter, bench }

/// The lineup already submitted for a team.
class SubmittedLineup {
  const SubmittedLineup({this.formation, this.starters = const {}, this.bench = const {}});

  final String? formation;

  /// Player user ids.
  final Set<int> starters;
  final Set<int> bench;

  factory SubmittedLineup.fromJson(Map<String, dynamic> json) {
    Set<int> ids(String key) => {for (final p in (json[key] as List? ?? const [])) (p as Map)['userId'] as int};
    return SubmittedLineup(formation: json['formation'] as String?, starters: ids('starters'), bench: ids('bench'));
  }
}

class FixtureManagementApi {
  FixtureManagementApi(this._client);

  final ApiClient _client;

  /// The team's matches still to be played (soonest first), including cancelled ones that were not yet due.
  Future<List<ManagedFixture>> upcoming(int teamId) async {
    Future<List<ManagedFixture>> read(Map<String, Object?> query) async {
      final body = await _client.get('/api/fixtures', query: {'teamId': teamId, 'limit': 100, ...query}) as Map<String, dynamic>;
      return [for (final f in body['fixtures'] as List) ManagedFixture.fromJson(Map<String, dynamic>.from(f as Map))];
    }

    final open = await read({'when': 'upcoming', 'order': 'asc'});
    final cancelled = await read({'status': 'cancelled', 'from': DateTime.now().toUtc().toIso8601String()});
    return [...open, ...cancelled]..sort((a, b) => a.startsAt.compareTo(b.startsAt));
  }

  /// Changes only what is given.
  Future<void> update(int fixtureId, {DateTime? matchDate, String? venue, String? matchType, String? status}) =>
      _client.patch('/api/fixtures/$fixtureId', body: {
        if (matchDate != null) 'matchDate': matchDate.toUtc().toIso8601String(),
        'venue': ?venue,
        'matchType': ?matchType,
        'status': ?status,
      });

  /// My team's submitted lineup, or null.
  Future<SubmittedLineup?> lineup(int fixtureId, int teamId) async {
    final body = await _client.get('/api/fixtures/$fixtureId/lineups') as Map<String, dynamic>;
    for (final side in ['home', 'away']) {
      final data = body[side];
      if (data is Map && data['teamId'] == teamId && data['lineup'] is Map) {
        return SubmittedLineup.fromJson(Map<String, dynamic>.from(data['lineup'] as Map));
      }
    }
    return null;
  }

  Future<void> submitLineup(int fixtureId, int teamId,
          {required List<int> starters, required List<int> bench, String? formation}) =>
      _client.put('/api/fixtures/$fixtureId/lineups/$teamId', body: {
        if (formation != null && formation.isNotEmpty) 'formation': formation,
        'starters': [for (final id in starters) {'userId': id}],
        'bench': [for (final id in bench) {'userId': id}],
      });

  Future<void> withdrawLineup(int fixtureId, int teamId) => _client.delete('/api/fixtures/$fixtureId/lineups/$teamId');
}
