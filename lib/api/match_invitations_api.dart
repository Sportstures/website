import 'api_client.dart';

String _schoolOr(Map<String, dynamic> team) {
  final school = team['school'];
  return school is Map ? '${school['name']}' : '${team['name']}';
}

/// A team as the invitation screens need it.
class MatchTeam {
  const MatchTeam({required this.id, required this.name, required this.school, this.sportId, this.sport, this.logoUrl, this.hasCoach = true});

  final int id;
  final String name;

  /// The school's name, or the team's own name when it has no school.
  final String school;
  final int? sportId;
  final String? sport;
  final String? logoUrl;

  /// A team without a coach on Sportstures has nobody to accept an invitation.
  final bool hasCoach;

  factory MatchTeam.fromJson(Map<String, dynamic> json) {
    final sport = json['sport'];
    return MatchTeam(
      id: json['id'] as int,
      name: '${json['name']}',
      school: _schoolOr(json),
      sportId: sport is Map ? sport['id'] as int? : null,
      sport: sport is Map ? sport['name'] as String? : null,
      logoUrl: json['logoUrl'] as String?,
      hasCoach: !json.containsKey('coach') || json['coach'] != null,
    );
  }
}

/// An invitation to play a match, sent from one coach to another.
class MatchInvitation {
  const MatchInvitation({
    required this.id,
    required this.status,
    required this.matchDate,
    required this.matchType,
    required this.homeTeam,
    required this.awayTeam,
    required this.inviterTeam,
    required this.invitedTeam,
    required this.canRespond,
    required this.canCancel,
    this.direction,
    this.venue,
    this.message,
    this.responseMessage,
    this.invitedByName,
  });

  final int id;

  /// `pending`, `accepted`, `declined`, `cancelled` or `expired`.
  final String status;

  /// `received` or `sent`.
  final String? direction;
  final DateTime matchDate;
  final String matchType;
  final String? venue;
  final String? message;
  final String? responseMessage;
  final String? invitedByName;
  final MatchTeam homeTeam;
  final MatchTeam awayTeam;
  final MatchTeam inviterTeam;
  final MatchTeam invitedTeam;
  final bool canRespond;
  final bool canCancel;

  bool get isPending => status == 'pending';
  bool get isReceived => direction == 'received';

  factory MatchInvitation.fromJson(Map<String, dynamic> json) {
    MatchTeam team(String key) => MatchTeam.fromJson(Map<String, dynamic>.from(json[key] as Map));
    final by = json['invitedBy'];
    return MatchInvitation(
      id: json['id'] as int,
      status: '${json['status']}',
      direction: json['direction'] as String?,
      matchDate: DateTime.parse('${json['matchDate']}').toLocal(),
      matchType: '${json['matchType'] ?? 'friendly'}',
      venue: json['venue'] as String?,
      message: json['message'] as String?,
      responseMessage: json['responseMessage'] as String?,
      invitedByName: by is Map ? by['name'] as String? : null,
      homeTeam: team('homeTeam'),
      awayTeam: team('awayTeam'),
      inviterTeam: team('inviterTeam'),
      invitedTeam: team('invitedTeam'),
      canRespond: json['canRespond'] == true,
      canCancel: json['canCancel'] == true,
    );
  }
}

class MatchInvitationsApi {
  MatchInvitationsApi(this._client);

  final ApiClient _client;

  /// Invitations to and from my teams: pending ones first.
  Future<List<MatchInvitation>> list() async {
    final data = await _client.get('/api/match-invitations', query: {'limit': 100}) as Map<String, dynamic>;
    return [for (final i in data['invitations'] as List) MatchInvitation.fromJson(Map<String, dynamic>.from(i as Map))];
  }

  /// How many invitations are waiting for my answer.
  Future<int> waitingCount() async {
    final data = await _client.get('/api/match-invitations',
        query: {'direction': 'received', 'status': 'pending', 'limit': 1}) as Map<String, dynamic>;
    return data['total'] as int;
  }

  Future<void> send({
    required int teamId,
    required int opponentTeamId,
    required DateTime matchDate,
    required bool atHome,
    required String matchType,
    String? venue,
    String? message,
  }) async {
    await _client.post('/api/match-invitations', body: {
      'teamId': teamId,
      'opponentTeamId': opponentTeamId,
      // UTC carries the time zone the server asks for.
      'matchDate': matchDate.toUtc().toIso8601String(),
      'playAt': atHome ? 'home' : 'away',
      'matchType': matchType,
      if (venue != null && venue.isNotEmpty) 'venue': venue,
      if (message != null && message.isNotEmpty) 'message': message,
    });
  }

  Future<void> accept(int id) => _client.post('/api/match-invitations/$id/accept');
  Future<void> decline(int id, {String? message}) => _client.post('/api/match-invitations/$id/decline',
      body: {if (message != null && message.isNotEmpty) 'message': message});
  Future<void> withdraw(int id) => _client.post('/api/match-invitations/$id/cancel');

  Future<MatchTeam> team(int id) async {
    final data = await _client.get('/api/teams/$id') as Map<String, dynamic>;
    return MatchTeam.fromJson(Map<String, dynamic>.from(data['team'] as Map));
  }

  /// Teams at other schools that play [sportId], matched on team or school name.
  Future<List<MatchTeam>> opponents({int? sportId, String query = ''}) async {
    final data = await _client.get('/api/teams',
        query: {'otherSchools': true, 'sportId': sportId, 'q': query, 'limit': 20}) as Map<String, dynamic>;
    return [for (final t in data['teams'] as List) MatchTeam.fromJson(Map<String, dynamic>.from(t as Map))];
  }
}
