import 'api_client.dart';

/// A team's own details and its school's location.
class TeamDetails {
  const TeamDetails({
    required this.id,
    required this.name,
    this.genderCategory,
    this.description,
    this.location,
    this.foundedYear,
    this.sportId,
    this.schoolId,
    this.schoolName,
    this.province,
    this.town,
  });

  final int id;
  final String name;

  /// `boys`, `girls` or `mixed`.
  final String? genderCategory;
  final String? description;

  /// Where the team plays or trains.
  final String? location;
  final int? foundedYear;
  final int? sportId;
  final int? schoolId;
  final String? schoolName;
  final String? province;
  final String? town;

  factory TeamDetails.fromJson(Map<String, dynamic> json) {
    final school = json['school'] is Map ? json['school'] as Map : null;
    return TeamDetails(
      id: json['id'] as int,
      name: '${json['name']}',
      genderCategory: json['genderCategory'] as String?,
      description: json['description'] as String?,
      location: json['location'] as String?,
      foundedYear: json['foundedYear'] as int?,
      sportId: json['sport'] is Map ? (json['sport'] as Map)['id'] as int? : null,
      schoolId: school?['id'] as int?,
      schoolName: school?['name'] as String?,
      province: school?['province'] as String?,
      town: school?['town'] as String?,
    );
  }
}

/// The nine provinces, exactly as the backend accepts them.
const provinces = [
  'Eastern Cape',
  'Free State',
  'Gauteng',
  'KwaZulu-Natal',
  'Limpopo',
  'Mpumalanga',
  'North West',
  'Northern Cape',
  'Western Cape',
];

class TeamDetailsApi {
  TeamDetailsApi(this._client);

  final ApiClient _client;

  Future<TeamDetails> team(int id) async {
    final data = await _client.get('/api/teams/$id') as Map<String, dynamic>;
    return TeamDetails.fromJson(Map<String, dynamic>.from(data['team'] as Map));
  }

  /// Sends only [changes]; a null value clears that field.
  Future<void> updateTeam(int id, Map<String, Object?> changes) => _client.patch('/api/teams/$id', body: changes);

  Future<void> updateSchool(int id, Map<String, Object?> changes) => _client.patch('/api/schools/$id', body: changes);

  /// Puts a match on the calendar with my team at home.
  Future<void> createFixture({
    required int homeTeamId,
    required int awayTeamId,
    required DateTime matchDate,
    required String matchType,
    String? venue,
    int? competitionId,
  }) =>
      _client.post('/api/fixtures', body: {
        'homeTeamId': homeTeamId,
        'awayTeamId': awayTeamId,
        'matchDate': matchDate.toUtc().toIso8601String(),
        'matchType': matchType,
        if (venue != null && venue.isNotEmpty) 'venue': venue,
        'competitionId': ?competitionId,
      });
}
