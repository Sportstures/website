import 'api_client.dart';
import 'coach_api.dart';

List<Map<String, dynamic>> _maps(Object? list) => [for (final m in (list as List? ?? const [])) Map<String, dynamic>.from(m as Map)];

/// A registered school.
class LiveSchool {
  const LiveSchool({
    required this.id,
    required this.name,
    this.province,
    this.town,
    this.teamCount = 0,
    this.sports = const [],
    this.played = 0,
    this.won = 0,
    this.drawn = 0,
    this.lost = 0,
    this.winRate,
  });

  final int id;
  final String name;
  final String? province;
  final String? town;
  final int teamCount;
  final List<String> sports;
  final int played;
  final int won;
  final int drawn;
  final int lost;

  /// A whole percentage, or null before any match.
  final int? winRate;

  /// "Soweto, Gauteng", or whichever part is known.
  String get location => [town, province].whereType<String>().where((s) => s.isNotEmpty).join(', ');

  factory LiveSchool.fromJson(Map<String, dynamic> json) {
    final record = json['record'] is Map ? json['record'] as Map : const {};
    return LiveSchool(
      id: json['id'] as int,
      name: '${json['name']}',
      province: json['province'] as String?,
      town: json['town'] as String?,
      teamCount: json['teamCount'] as int? ?? 0,
      sports: [for (final s in (json['sports'] as List? ?? const [])) '$s'],
      played: record['played'] as int? ?? 0,
      won: record['won'] as int? ?? 0,
      drawn: record['drawn'] as int? ?? 0,
      lost: record['lost'] as int? ?? 0,
      winRate: (record['winRate'] as num?)?.round(),
    );
  }
}

class SchoolList {
  const SchoolList({required this.schools, required this.total, required this.hasMore});

  final List<LiveSchool> schools;
  final int total;
  final bool hasMore;
}

class SchoolFilters {
  const SchoolFilters({this.provinces = const [], this.sports = const []});

  /// Every province, with how many schools it has.
  final List<({String name, int count})> provinces;
  final List<({int id, String name, int count})> sports;

  factory SchoolFilters.fromJson(Map<String, dynamic> json) => SchoolFilters(
        provinces: [for (final p in _maps(json['provinces'])) (name: '${p['name']}', count: p['schoolCount'] as int)],
        sports: [for (final s in _maps(json['sports'])) (id: s['id'] as int, name: '${s['name']}', count: s['schoolCount'] as int)],
      );
}

class SchoolTeam {
  const SchoolTeam({required this.name, this.sport, this.ageGroup, this.coach, this.logoUrl, this.playerCount = 0});

  final String name;
  final String? sport;
  final String? ageGroup;
  final String? coach;
  final String? logoUrl;
  final int playerCount;

  factory SchoolTeam.fromJson(Map<String, dynamic> json) => SchoolTeam(
        name: '${json['name']}',
        sport: json['sport'] is Map ? (json['sport'] as Map)['name'] as String? : null,
        ageGroup: json['ageGroup'] as String?,
        coach: json['coach'] is Map ? (json['coach'] as Map)['name'] as String? : null,
        logoUrl: json['logoUrl'] as String?,
        playerCount: json['playerCount'] as int? ?? 0,
      );
}

class SchoolPageData {
  const SchoolPageData({required this.school, required this.teams, required this.results, required this.upcoming});

  final LiveSchool school;
  final List<SchoolTeam> teams;

  /// The last five finished matches, newest first.
  final List<CoachFixture> results;

  /// The next five, soonest first.
  final List<CoachFixture> upcoming;

  factory SchoolPageData.fromJson(Map<String, dynamic> json) => SchoolPageData(
        school: LiveSchool.fromJson(Map<String, dynamic>.from(json['school'] as Map)),
        teams: [for (final t in _maps(json['teams'])) SchoolTeam.fromJson(t)],
        results: [for (final f in _maps(json['recentResults'])) CoachFixture.fromJson(f)],
        upcoming: [for (final f in _maps(json['upcoming'])) CoachFixture.fromJson(f)],
      );
}

class SchoolsApi {
  SchoolsApi(this._client);

  final ApiClient _client;

  /// Schools by name. [query] matches the name or town.
  Future<SchoolList> list({String query = '', String? province, int? sportId, int limit = 12, int offset = 0}) async {
    final data = await _client.get('/api/schools', auth: false, query: {
      'q': query,
      'province': province,
      'sportId': sportId,
      'limit': limit,
      'offset': offset,
    }) as Map<String, dynamic>;
    return SchoolList(
      schools: [for (final s in _maps(data['schools'])) LiveSchool.fromJson(s)],
      total: data['total'] as int,
      hasMore: data['hasMore'] == true,
    );
  }

  Future<SchoolFilters> filters() async =>
      SchoolFilters.fromJson(await _client.get('/api/schools/filters', auth: false) as Map<String, dynamic>);

  Future<SchoolPageData> school(int id) async =>
      SchoolPageData.fromJson(await _client.get('/api/schools/$id', auth: false) as Map<String, dynamic>);

  /// The id of the school with exactly this name (ignoring case), or null.
  Future<int?> idOf(String name) async {
    final found = await list(query: name, limit: 100);
    final wanted = name.trim().toLowerCase();
    return found.schools.where((s) => s.name.toLowerCase() == wanted).firstOrNull?.id;
  }
}
