import 'api_client.dart';

/// One match as the coach pages need it. Built from a backend fixture object.
class CoachFixture {
  const CoachFixture({
    required this.id,
    required this.startsAt,
    required this.status,
    required this.homeTeamId,
    required this.awayTeamId,
    required this.homeName,
    required this.awayName,
    this.venue,
    this.competition,
    this.homeScore,
    this.awayScore,
  });

  final int id;
  final DateTime startsAt;
  final String status;
  final int homeTeamId;
  final int awayTeamId;
  final String homeName;
  final String awayName;
  final String? venue;
  final String? competition;
  final int? homeScore;
  final int? awayScore;

  bool get hasScore => homeScore != null && awayScore != null;

  /// The other side's name, seen from [teamId].
  String opponentOf(int teamId) => teamId == homeTeamId ? awayName : homeName;

  bool isHome(int teamId) => teamId == homeTeamId;

  /// "W", "L" or "D" for [teamId], or null until there is a score.
  String? outcomeFor(int teamId) {
    if (!hasScore) return null;
    final mine = isHome(teamId) ? homeScore! : awayScore!;
    final theirs = isHome(teamId) ? awayScore! : homeScore!;
    return mine > theirs ? 'W' : mine < theirs ? 'L' : 'D';
  }

  factory CoachFixture.fromJson(Map<String, dynamic> json) {
    final home = json['homeTeam'] as Map<String, dynamic>;
    final away = json['awayTeam'] as Map<String, dynamic>;
    final score = json['score'];
    final competition = json['competition'];
    return CoachFixture(
      id: json['id'] as int,
      startsAt: DateTime.parse('${json['matchDate']}').toLocal(),
      status: '${json['status']}',
      homeTeamId: home['id'] as int,
      awayTeamId: away['id'] as int,
      homeName: _teamLabel(home),
      awayName: _teamLabel(away),
      venue: json['venue'] as String?,
      competition: competition is Map ? competition['name'] as String? : null,
      homeScore: score is Map ? score['home'] as int? : null,
      awayScore: score is Map ? score['away'] as int? : null,
    );
  }

  /// "Northview High" when the team has a school, otherwise the team's own name.
  static String _teamLabel(Map<String, dynamic> team) {
    final school = team['school'];
    return school is Map ? '${school['name']}' : '${team['name']}';
  }
}

/// Something the coach needs to do, from the dashboard.
class ActionItem {
  const ActionItem({required this.type, this.dueAt, this.fixture, this.count});

  /// `record_result`, `submit_lineup`, `file_report` or `review_join_requests`.
  final String type;
  final DateTime? dueAt;
  final CoachFixture? fixture;
  final int? count;

  factory ActionItem.fromJson(Map<String, dynamic> json) => ActionItem(
        type: '${json['type']}',
        dueAt: json['dueAt'] == null ? null : DateTime.parse('${json['dueAt']}').toLocal(),
        fixture: json['fixture'] is Map ? CoachFixture.fromJson(Map<String, dynamic>.from(json['fixture'] as Map)) : null,
        count: json['count'] as int?,
      );
}

class TeamRecord {
  const TeamRecord({required this.played, required this.won, required this.drawn, required this.lost, this.winRate, this.form = const []});

  final int played;
  final int won;
  final int drawn;
  final int lost;

  /// A percentage (0 to 100), or null until the team has played.
  final double? winRate;

  /// The last five results, oldest first: W, D or L.
  final List<String> form;

  factory TeamRecord.fromJson(Map<String, dynamic> json) => TeamRecord(
        played: json['played'] as int,
        won: json['won'] as int,
        drawn: json['drawn'] as int,
        lost: json['lost'] as int,
        winRate: (json['winRate'] as num?)?.toDouble(),
        form: [for (final f in (json['form'] as List? ?? const [])) '$f'],
      );
}

class CoachTeam {
  const CoachTeam({required this.id, required this.name, this.sport, this.level, this.school, this.province});

  final int id;
  final String name;
  final String? sport;
  final String? level;
  final String? school;
  final String? province;

  factory CoachTeam.fromJson(Map<String, dynamic> json) {
    final sport = json['sport'];
    final school = json['school'];
    return CoachTeam(
      id: json['id'] as int,
      name: '${json['name']}',
      sport: sport is Map ? sport['name'] as String? : null,
      level: json['level'] as String?,
      school: school is Map ? school['name'] as String? : null,
      province: school is Map ? school['province'] as String? : null,
    );
  }
}

class CoachDashboard {
  const CoachDashboard({
    required this.team,
    required this.squadSize,
    required this.pendingRequests,
    required this.record,
    required this.nextMatch,
    required this.upcoming,
    required this.recentResults,
    required this.actionItems,
  });

  final CoachTeam team;
  final int squadSize;
  final int pendingRequests;
  final TeamRecord record;
  final CoachFixture? nextMatch;
  final List<CoachFixture> upcoming;
  final List<CoachFixture> recentResults;
  final List<ActionItem> actionItems;

  factory CoachDashboard.fromJson(Map<String, dynamic> json) {
    List<CoachFixture> fixtures(String key) => [
          for (final f in (json[key] as List? ?? const [])) CoachFixture.fromJson(Map<String, dynamic>.from(f as Map)),
        ];
    return CoachDashboard(
      team: CoachTeam.fromJson(json['team'] as Map<String, dynamic>),
      squadSize: json['squadSize'] as int,
      pendingRequests: json['pendingRequests'] as int,
      record: TeamRecord.fromJson(json['record'] as Map<String, dynamic>),
      nextMatch: json['nextMatch'] is Map ? CoachFixture.fromJson(Map<String, dynamic>.from(json['nextMatch'] as Map)) : null,
      upcoming: fixtures('upcoming'),
      recentResults: fixtures('recentResults'),
      actionItems: [
        for (final a in (json['actionItems'] as List? ?? const [])) ActionItem.fromJson(Map<String, dynamic>.from(a as Map)),
      ],
    );
  }
}

/// A player on (or asking to join) the team.
class RosterMember {
  const RosterMember({
    required this.userId,
    required this.name,
    required this.status,
    this.jerseyNumber,
    this.position,
    this.grade,
    this.className,
    this.requestedAt,
  });

  final int userId;
  final String name;

  /// `active` or `pending`.
  final String status;
  final int? jerseyNumber;
  final String? position;
  final int? grade;
  final String? className;
  final DateTime? requestedAt;

  bool get isPending => status == 'pending';

  String get gradeLabel => [if (grade != null) 'Grade $grade', if (className != null && className!.isNotEmpty) className!].join(' · ');

  factory RosterMember.fromJson(Map<String, dynamic> json) => RosterMember(
        userId: json['userId'] as int,
        name: '${json['name'] ?? 'Unnamed player'}',
        status: '${json['status']}',
        jerseyNumber: json['jerseyNumber'] as int?,
        position: json['position'] as String?,
        grade: json['grade'] as int?,
        className: json['className'] as String?,
        requestedAt: json['requestedAt'] == null ? null : DateTime.tryParse('${json['requestedAt']}')?.toLocal(),
      );
}

/// A learner at the team's school who could be added.
class Candidate {
  const Candidate({required this.userId, required this.name, this.grade, this.className, this.declaredSport, this.declaredJersey});

  final int userId;
  final String name;
  final int? grade;
  final String? className;
  final String? declaredSport;
  final int? declaredJersey;

  String get gradeLabel => [if (grade != null) 'Grade $grade', if (className != null && className!.isNotEmpty) className!].join(' · ');

  factory Candidate.fromJson(Map<String, dynamic> json) => Candidate(
        userId: json['userId'] as int,
        name: '${json['name'] ?? 'Unnamed player'}',
        grade: json['grade'] as int?,
        className: json['className'] as String?,
        declaredSport: json['declaredSport'] as String?,
        declaredJersey: json['declaredJerseyNumber'] as int?,
      );
}

/// The coach's calls to the backend.
class CoachApi {
  CoachApi(this.api);

  final ApiClient api;

  Future<CoachDashboard> dashboard() async =>
      CoachDashboard.fromJson(await api.get('/api/coach/dashboard') as Map<String, dynamic>);

  Future<List<RosterMember>> roster(int teamId, {bool pending = false}) async {
    final body = await api.get('/api/teams/$teamId/roster', query: {'status': pending ? 'pending' : 'active'}) as Map<String, dynamic>;
    return [for (final m in body['roster'] as List) RosterMember.fromJson(Map<String, dynamic>.from(m as Map))];
  }

  Future<List<Candidate>> candidates(int teamId, {String query = ''}) async {
    final body = await api.get('/api/teams/$teamId/candidates', query: {'q': query.trim()}) as Map<String, dynamic>;
    return [for (final c in body['candidates'] as List) Candidate.fromJson(Map<String, dynamic>.from(c as Map))];
  }

  /// Adds a learner, or approves their pending request.
  Future<void> addPlayer(int teamId, int userId, {int? jerseyNumber, String? position}) => api.post(
        '/api/teams/$teamId/roster',
        body: {'userId': userId, 'jerseyNumber': ?jerseyNumber, if (position != null && position.isNotEmpty) 'position': position},
      );

  Future<void> updatePlayer(int teamId, int userId, {int? jerseyNumber, bool clearJersey = false, String? position}) => api.patch(
        '/api/teams/$teamId/roster/$userId',
        body: {
          if (jerseyNumber != null || clearJersey) 'jerseyNumber': jerseyNumber,
          if (position != null) 'position': position.isEmpty ? null : position,
        },
      );

  /// Rejects a request or removes a player.
  Future<void> removePlayer(int teamId, int userId) => api.delete('/api/teams/$teamId/roster/$userId');
}
