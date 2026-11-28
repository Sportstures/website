import 'api_client.dart';

List<Map<String, dynamic>> _maps(Object? list) => [for (final m in (list as List? ?? const [])) Map<String, dynamic>.from(m as Map)];

/// The ways teams level on points can be separated, with the words used for them.
const tiebreakerLabels = {
  'difference': 'Score difference',
  'for': 'Most scored',
  'against': 'Fewest conceded',
  'wins': 'Most wins',
  'head_to_head': 'Head-to-head',
};

/// The order used when a competition has not chosen its own.
const standardTiebreakers = ['difference', 'for', 'head_to_head'];

/// How a competition's table is decided.
class TableRules {
  const TableRules({this.win = 3, this.draw = 1, this.loss = 0, this.tiebreakers = standardTiebreakers, this.custom = false});

  final int win;
  final int draw;
  final int loss;
  final List<String> tiebreakers;

  /// False while the competition uses the standard rules.
  final bool custom;

  bool get isStandard =>
      win == 3 && draw == 1 && loss == 0 && tiebreakers.join(',') == standardTiebreakers.join(',');

  /// e.g. "Win 3, draw 1, loss 0. Level on points: score difference, then most scored."
  String get summary {
    final order = [for (final t in tiebreakers) (tiebreakerLabels[t] ?? t).toLowerCase()].join(', then ');
    return 'Win $win, draw $draw, loss $loss. Level on points: $order.';
  }

  factory TableRules.fromJson(Map<String, dynamic> json) => TableRules(
        win: json['pointsWin'] as int? ?? 3,
        draw: json['pointsDraw'] as int? ?? 1,
        loss: json['pointsLoss'] as int? ?? 0,
        tiebreakers: [for (final t in (json['tiebreakers'] as List? ?? standardTiebreakers)) '$t'],
        custom: json['custom'] == true,
      );
}

class Competition {
  const Competition({
    required this.id,
    required this.name,
    required this.rules,
    this.season,
    this.sportId,
    this.sport,
    this.status,
    this.teams = 0,
    this.canEdit = false,
  });

  final int id;
  final String name;
  final String? season;
  final int? sportId;
  final String? sport;

  /// `ongoing`, `upcoming` or `completed`.
  final String? status;
  final int teams;
  final TableRules rules;

  /// Whether the signed-in person may change it.
  final bool canEdit;

  factory Competition.fromJson(Map<String, dynamic> json) {
    final sport = json['sport'];
    return Competition(
      id: json['id'] as int,
      name: '${json['name']}',
      season: json['season'] as String?,
      sportId: sport is Map ? sport['id'] as int? : null,
      sport: sport is Map ? sport['name'] as String? : null,
      status: json['status'] as String?,
      teams: json['teams'] is int ? json['teams'] as int : 0,
      rules: json['rules'] is Map ? TableRules.fromJson(Map<String, dynamic>.from(json['rules'] as Map)) : const TableRules(),
      canEdit: json['canEdit'] == true,
    );
  }
}

class CompetitionRow {
  const CompetitionRow({
    required this.position,
    required this.team,
    required this.school,
    required this.played,
    required this.won,
    required this.drawn,
    required this.lost,
    required this.scored,
    required this.conceded,
    required this.difference,
    required this.points,
    this.tiebreaker,
    this.logoUrl,
  });

  final int position;
  final String team;
  final String school;
  final int played;
  final int won;
  final int drawn;
  final int lost;
  final int scored;
  final int conceded;
  final int difference;
  final int points;

  /// What separated this team from those level on points, or null when points were enough.
  final String? tiebreaker;
  final String? logoUrl;

  factory CompetitionRow.fromJson(Map<String, dynamic> json) {
    final team = Map<String, dynamic>.from(json['team'] as Map);
    final school = team['school'];
    int n(String key) => (json[key] as num?)?.toInt() ?? 0;
    return CompetitionRow(
      position: n('position'),
      team: '${team['name']}',
      school: school is Map ? '${school['name']}' : '${team['name']}',
      logoUrl: team['logoUrl'] as String?,
      played: n('played'),
      won: n('won'),
      drawn: n('drawn'),
      lost: n('lost'),
      scored: n('pointsFor'),
      conceded: n('pointsAgainst'),
      difference: n('difference'),
      points: n('points'),
      tiebreaker: json['tiebreaker'] as String?,
    );
  }
}

class CompetitionTableData {
  const CompetitionTableData({required this.competition, required this.rows});

  final Competition competition;
  final List<CompetitionRow> rows;
}

class CompetitionsApi {
  CompetitionsApi(this._client);

  final ApiClient _client;

  /// Every competition. Signed in, each says whether it can be edited.
  Future<List<Competition>> list({int? sportId, bool auth = true}) async {
    final data = await _client.get('/api/competitions', query: {'sportId': sportId}, auth: auth) as Map<String, dynamic>;
    return [for (final c in _maps(data['competitions'])) Competition.fromJson(c)];
  }

  Future<Competition> create({required String name, int? sportId, String? season, required TableRules rules}) async {
    final data = await _client.post('/api/competitions', body: {
      'name': name,
      'sportId': ?sportId,
      if (season != null && season.isNotEmpty) 'season': season,
      ..._rules(rules),
    }) as Map<String, dynamic>;
    return Competition.fromJson(Map<String, dynamic>.from(data['competition'] as Map));
  }

  Future<void> updateRules(int id, TableRules rules) => _client.patch('/api/competitions/$id', body: _rules(rules));

  /// The standard tiebreaker order is sent as null, so the competition follows the standard.
  static Map<String, Object?> _rules(TableRules rules) => {
        'pointsWin': rules.win,
        'pointsDraw': rules.draw,
        'pointsLoss': rules.loss,
        'tiebreakers': rules.tiebreakers.join(',') == standardTiebreakers.join(',') ? null : rules.tiebreakers,
      };

  /// The competition's table, worked out by the server with its own rules.
  Future<CompetitionTableData> table(int id) async {
    final data = await _client.get('/api/competitions/$id/standings', auth: false) as Map<String, dynamic>;
    return CompetitionTableData(
      competition: Competition.fromJson(Map<String, dynamic>.from(data['competition'] as Map)),
      rows: [for (final r in _maps(data['standings'])) CompetitionRow.fromJson(r)],
    );
  }
}
