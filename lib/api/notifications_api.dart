import 'api_client.dart';

/// One item in the inbox.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.createdAt,
    required this.read,
    this.body,
    this.fixtureId,
  });

  final int id;

  /// For example `match_invitation_received` or `goal_confirmation_needed`.
  final String type;
  final String title;
  final String? body;
  final DateTime createdAt;
  final bool read;

  /// The match it is about, when there is one.
  final int? fixtureId;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    return AppNotification(
      id: json['id'] as int,
      type: '${json['type']}',
      title: '${json['title']}',
      body: json['body'] as String?,
      createdAt: DateTime.parse('${json['createdAt']}').toLocal(),
      read: json['read'] == true,
      fixtureId: data is Map ? data['fixtureId'] as int? : null,
    );
  }
}

class NotificationPage {
  const NotificationPage({required this.items, required this.unreadCount, required this.hasMore});

  final List<AppNotification> items;
  final int unreadCount;
  final bool hasMore;
}

class NotificationsApi {
  NotificationsApi(this._client);

  final ApiClient _client;

  /// Newest first.
  Future<NotificationPage> list({int limit = 20, int offset = 0}) async {
    final data = await _client.get('/api/me/notifications', query: {'limit': limit, 'offset': offset}) as Map<String, dynamic>;
    return NotificationPage(
      items: [for (final n in data['notifications'] as List) AppNotification.fromJson(Map<String, dynamic>.from(n as Map))],
      unreadCount: data['unreadCount'] as int,
      hasMore: data['hasMore'] == true,
    );
  }

  Future<int> unreadCount() async =>
      (await _client.get('/api/me/notifications/unread-count') as Map<String, dynamic>)['unreadCount'] as int;

  Future<void> markRead(int id) => _client.put('/api/me/notifications/$id/read');
  Future<void> markAllRead() => _client.post('/api/me/notifications/read-all');
  Future<void> delete(int id) => _client.delete('/api/me/notifications/$id');

  /// Which kinds are switched on, by category name.
  Future<Map<String, bool>> settings() async => _settings(await _client.get('/api/me/notifications/settings'));

  Future<Map<String, bool>> setSetting(String category, bool on) async =>
      _settings(await _client.put('/api/me/notifications/settings', body: {category: on}));

  static Map<String, bool> _settings(dynamic data) => {
        for (final e in ((data as Map<String, dynamic>)['settings'] as Map).entries) '${e.key}': e.value == true,
      };
}
