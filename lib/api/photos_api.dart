import 'api_client.dart';

/// Profile photo and team logo uploads.
class PhotosApi {
  PhotosApi(this._client);

  final ApiClient _client;

  /// My profile photo address, or null.
  Future<String?> myAvatar() async {
    final data = await _client.get('/api/auth/me') as Map<String, dynamic>;
    return (data['user'] as Map<String, dynamic>)['avatarUrl'] as String?;
  }

  Future<String> uploadAvatar(List<int> bytes, String filename) async {
    final data = await _client.putPhoto('/api/me/avatar', bytes, filename: filename) as Map<String, dynamic>;
    return data['avatarUrl'] as String;
  }

  Future<void> removeAvatar() => _client.delete('/api/me/avatar');

  /// The team's logo address, or null.
  Future<String?> teamLogo(int teamId) async {
    final data = await _client.get('/api/teams/$teamId', auth: false) as Map<String, dynamic>;
    return (data['team'] as Map<String, dynamic>)['logoUrl'] as String?;
  }

  Future<String> uploadTeamLogo(int teamId, List<int> bytes, String filename) async {
    final data = await _client.putPhoto('/api/teams/$teamId/logo', bytes, filename: filename) as Map<String, dynamic>;
    return data['logoUrl'] as String;
  }

  Future<void> removeTeamLogo(int teamId) => _client.delete('/api/teams/$teamId/logo');
}
