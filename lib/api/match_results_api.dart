import 'api_client.dart';
import 'api_exception.dart';

/// The one report a match has, shared by both coaches.
class MatchReport {
  const MatchReport({required this.summary, this.author, this.updatedAt});

  final String summary;
  final String? author;
  final DateTime? updatedAt;

  factory MatchReport.fromJson(Map<String, dynamic> json) => MatchReport(
        summary: '${json['summary']}',
        author: json['author'] is Map ? (json['author'] as Map)['name'] as String? : null,
        updatedAt: json['updatedAt'] == null ? null : DateTime.tryParse('${json['updatedAt']}')?.toLocal(),
      );
}

/// Final scores and match reports.
class MatchResultsApi {
  MatchResultsApi(this._client);

  final ApiClient _client;

  /// Records the final score, or corrects it. Only the home team's coach may.
  Future<void> recordResult(int fixtureId, {required int homeScore, required int awayScore}) =>
      _client.put('/api/fixtures/$fixtureId/result', body: {'homeScore': homeScore, 'awayScore': awayScore});

  /// The match's report, or null when none has been filed.
  Future<MatchReport?> report(int fixtureId) async {
    try {
      final data = await _client.get('/api/fixtures/$fixtureId/report') as Map<String, dynamic>;
      return MatchReport.fromJson(Map<String, dynamic>.from(data['report'] as Map));
    } on ApiException catch (e) {
      if (e.code == 'REPORT_NOT_FOUND') return null;
      rethrow;
    }
  }

  /// Files the report, or replaces it. The result must have been recorded.
  Future<void> fileReport(int fixtureId, String summary) =>
      _client.put('/api/fixtures/$fixtureId/report', body: {'summary': summary});
}
