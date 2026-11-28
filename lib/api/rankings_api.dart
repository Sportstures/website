import 'api_client.dart';

String? _name(Object? value) => value is Map ? value['name'] as String? : null;

List<Map<String, dynamic>> _maps(Object? list) => [for (final m in (list as List? ?? const [])) Map<String, dynamic>.from(m as Map)];

/// One row of a ranking table, whatever is being ranked.
class RankingRow {
  const RankingRow({
    required this.position,
    required this.name,
    required this.points,
    this.detail,
    this.province,
    this.played = 0,
    this.sportsPlayed,
    this.schoolsRanked,
    this.trend,
    this.logoUrl,
  });

  final int position;
  final String name;

  /// The second line, e.g. "3 sports played" or "Rugby 1st Team".
  final String? detail;
  final String? province;
  final int points;
  final int played;
  final int? sportsPlayed;
  final int? schoolsRanked;

  /// Places moved since a week ago; null for a new entry.
  final int? trend;
  final String? logoUrl;

  factory RankingRow.fromJson(Map<String, dynamic> json) => RankingRow(
        position: json['position'] as int,
        name: '${json['name'] ?? ''}',
        detail: json['detail'] as String?,
        province: json['province'] as String?,
        points: (json['points'] as num?)?.round() ?? 0,
        played: json['played'] as int? ?? 0,
        sportsPlayed: json['sportsPlayed'] as int?,
        schoolsRanked: json['schoolsRanked'] as int?,
        trend: json['trend'] as int?,
        logoUrl: json['team'] is Map ? (json['team'] as Map)['logoUrl'] as String? : null,
      );
}

class RankingResult {
  const RankingResult({required this.rows, required this.total, this.updatedAt});

  final List<RankingRow> rows;
  final int total;

  /// When the latest result was recorded.
  final DateTime? updatedAt;
}

typedef RankingWeight = ({String label, int percent, String description});
typedef SportLeader = ({String label, String? school, int points});
typedef Riser = ({String name, int trend});
typedef RegionLeader = ({String province, String name, int points});

/// The cards around the table.
class RankingOverview {
  const RankingOverview({this.weights = const [], this.topSports = const [], this.risers = const [], this.regionLeaders = const []});

  final List<RankingWeight> weights;
  final List<SportLeader> topSports;
  final List<Riser> risers;
  final List<RegionLeader> regionLeaders;

  factory RankingOverview.fromJson(Map<String, dynamic> json) => RankingOverview(
        weights: [
          for (final w in _maps(json['breakdown']))
            (label: '${w['label']}', percent: ((w['weight'] as num) * 100).round(), description: '${w['description'] ?? ''}'),
        ],
        topSports: [
          for (final s in _maps(json['topSports']))
            (label: '${s['label'] ?? _name(s['sport']) ?? ''}', school: _name(s['school']), points: (s['points'] as num).round()),
        ],
        risers: [for (final r in _maps(json['topRisers'])) (name: '${r['name']}', trend: r['trend'] as int)],
        regionLeaders: [
          for (final r in _maps(json['regionLeaders']))
            if (r['leader'] is Map)
              (
                province: '${r['province']}',
                name: '${(r['leader'] as Map)['name']}',
                points: ((r['leader'] as Map)['points'] as num).round(),
              ),
        ],
      );
}

/// What can be filtered on: only things that have results.
class RankingFilters {
  const RankingFilters({this.seasons = const [], this.sports = const [], this.ageGroups = const [], this.provinces = const []});

  final List<int> seasons;
  final List<({int id, String name})> sports;
  final List<String> ageGroups;
  final List<String> provinces;

  factory RankingFilters.fromJson(Map<String, dynamic> json) => RankingFilters(
        seasons: [for (final s in (json['seasons'] as List? ?? const [])) s as int],
        sports: [for (final s in _maps(json['sports'])) (id: s['id'] as int, name: '${s['name']}')],
        ageGroups: [for (final a in (json['ageGroups'] as List? ?? const [])) '$a'],
        provinces: [for (final p in (json['provinces'] as List? ?? const [])) '$p'],
      );
}

class RankingsApi {
  RankingsApi(this._client);

  final ApiClient _client;

  Future<RankingResult> rankings({
    required String type,
    int? sportId,
    String? ageGroup,
    String? province,
    int? season,
    int limit = 10,
  }) async {
    final data = await _client.get('/api/rankings', auth: false, query: {
      'type': type,
      'sportId': sportId,
      'ageGroup': ageGroup,
      'province': province,
      'season': season,
      'limit': limit,
    }) as Map<String, dynamic>;
    return RankingResult(
      rows: [for (final r in _maps(data['rankings'])) RankingRow.fromJson(r)],
      total: data['total'] as int,
      updatedAt: data['updatedAt'] == null ? null : DateTime.tryParse('${data['updatedAt']}')?.toLocal(),
    );
  }

  Future<RankingOverview> overview({int? season}) async => RankingOverview.fromJson(
      await _client.get('/api/rankings/overview', auth: false, query: {'season': season}) as Map<String, dynamic>);

  Future<RankingFilters> filters({int? season}) async => RankingFilters.fromJson(
      await _client.get('/api/rankings/filters', auth: false, query: {'season': season}) as Map<String, dynamic>);
}
