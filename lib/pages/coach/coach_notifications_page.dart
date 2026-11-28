import 'dart:async';

import 'package:flutter/material.dart';

import '../../api/api_exception.dart';
import '../../api/notifications_api.dart';
import '../../api/session.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';
import '../../widgets/site/page_hero.dart';
import '../../widgets/site/site_routes.dart';
import '../../widgets/site/site_scaffold.dart';
import '../../widgets/site/ui_kit.dart';
import 'coach_guard.dart';
import 'coach_live_page.dart';

/// The coach's inbox, and which kinds of notification to get.
class CoachNotificationsPage extends StatelessWidget {
  const CoachNotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CoachGuard(
      currentRoute: SiteRoutes.coachNotifications,
      title: 'Notifications',
      subtitle: 'Invitations, scores to confirm and changes to your matches.',
      builder: (context, coach) => const _Inbox(),
    );
  }
}

/// How often the inbox checks for something new while it is open.
const notificationPollInterval = Duration(seconds: 60);

/// The settings coaches are shown. The others are for learners.
const _coachSettings = [
  ('matchInvitations', 'Match invitations', 'A school invites you, answers your invitation or withdraws theirs.'),
  ('goalConfirmations', 'Scores to confirm', 'The other coach adds a score you need to confirm, or disputes yours.'),
  ('fixtureChanges', 'Match changes', 'The other coach schedules, moves, postpones or cancels a match.'),
];

/// Where tapping a notification leads, or null when it has nowhere to go.
String? notificationRoute(AppNotification n) {
  if (n.type.startsWith('match_invitation')) return SiteRoutes.coachMatchInvites;
  final id = n.fixtureId;
  if (id != null && (n.type.startsWith('goal_') || n.type == 'match_started' || n.type == 'match_result')) {
    return CoachLivePage.routeFor(id);
  }
  if (n.type.startsWith('fixture_')) return SiteRoutes.coachMatches;
  return null;
}

class _Inbox extends StatefulWidget {
  const _Inbox();

  @override
  State<_Inbox> createState() => _InboxState();
}

class _InboxState extends State<_Inbox> {
  late final NotificationsApi _api = NotificationsApi(SessionScope.read(context).api);

  static const _pageSize = 20;

  List<AppNotification>? _items;
  int _unread = 0;
  bool _hasMore = false;
  int _shown = _pageSize;
  Map<String, bool>? _settings;
  String? _loadError;
  String? _error;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _load();
    _loadSettings();
    _poll = Timer.periodic(notificationPollInterval, (_) => _load());
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      // The server allows at most 100 at a time.
      final page = await _api.list(limit: _shown.clamp(1, 100));
      if (!mounted) return;
      setState(() {
        _items = page.items;
        _unread = page.unreadCount;
        _hasMore = page.hasMore && _shown < 100;
        _loadError = null;
      });
    } on ApiException catch (e) {
      // A failed check keeps what is on screen.
      if (mounted && _items == null) setState(() => _loadError = e.message);
    }
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await _api.settings();
      if (mounted) setState(() => _settings = settings);
    } on ApiException {
      // The inbox still works; the settings card says they could not be loaded.
      if (mounted) setState(() => _settings = const {});
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _error = null);
    try {
      await action();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
    if (mounted) await _load();
  }

  Future<void> _open(AppNotification n) async {
    final route = notificationRoute(n);
    if (!n.read) await _run(() => _api.markRead(n.id));
    if (route != null && mounted) openSiteRoute(context, route);
  }

  Future<void> _toggle(String category, bool on) async {
    final before = _settings!;
    setState(() {
      _settings = {...before, category: on};
      _error = null;
    });
    try {
      final saved = await _api.setSetting(category, on);
      if (mounted) setState(() => _settings = saved);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _settings = before;
          _error = e.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    return SiteScaffold(
      currentRoute: SiteRoutes.coachNotifications,
      children: [
        const PageHero(title: 'Notifications', breadcrumb: 'Notifications', subtitle: 'Invitations, scores to confirm and changes to your matches.'),
        ContentWidth(
          child: Padding(
            padding: const EdgeInsets.only(top: 28, bottom: 56),
            child: TwoColumnLayout(
              main: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(_error!, style: TextStyle(fontSize: 13, color: Colors.red.shade700, fontWeight: FontWeight.w700)),
                    ),
                  SectionCard(
                    title: _unread == 0 ? 'Inbox' : 'Inbox · $_unread unread',
                    trailing: _unread == 0
                        ? null
                        : TextButton(onPressed: () => _run(_api.markAllRead), child: const Text('Mark all read')),
                    child: _loadError != null
                        ? Column(children: [
                            EmptyState(_loadError!),
                            const SizedBox(height: 8),
                            SiteButton(label: 'TRY AGAIN', small: true, onPressed: _load),
                            const SizedBox(height: 12),
                          ])
                        : items == null
                            ? const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
                            : items.isEmpty
                                ? const EmptyState('Nothing yet. Invitations and match changes will show here.')
                                : DividedColumn(children: [for (final n in items) _row(n)]),
                  ),
                  if (_hasMore) ...[
                    const SizedBox(height: 12),
                    Center(
                      child: TextButton(
                        onPressed: () {
                          _shown += _pageSize;
                          _load();
                        },
                        child: const Text('Show older'),
                      ),
                    ),
                  ],
                ],
              ),
              sidebar: _settingsCard(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _row(AppNotification n) {
    return InkWell(
      key: ValueKey('notification-${n.id}'),
      onTap: () => _open(n),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Icon(Icons.circle, size: 9, color: n.read ? Colors.transparent : AppColors.orange, semanticLabel: n.read ? null : 'Unread'),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(n.title,
                      style: TextStyle(fontSize: 13, fontWeight: n.read ? FontWeight.w600 : FontWeight.w900, color: AppColors.ink)),
                  if (n.body != null && n.body!.isNotEmpty)
                    Text(n.body!, style: const TextStyle(fontSize: 12, color: AppColors.muted, height: 1.45)),
                  Text('${formatShortDate(n.createdAt)}, ${formatTime(n.createdAt)}',
                      style: const TextStyle(fontSize: 11, color: AppColors.muted, height: 1.6)),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Delete notification',
              icon: const Icon(Icons.close, size: 16, color: AppColors.muted),
              onPressed: () => _run(() => _api.delete(n.id)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _settingsCard() {
    final settings = _settings;
    return SectionCard(
      title: 'Notify me about',
      child: settings == null
          ? const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
          : settings.isEmpty
              ? const EmptyState("Your settings couldn't be loaded. Refresh the page to try again.")
              : DividedColumn(
                  children: [
                    for (final (category, title, hint) in _coachSettings)
                      // Transparent Material so the switch row can draw its tap effect inside the card.
                      Material(
                        type: MaterialType.transparency,
                        child: SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.ink)),
                          subtitle: Text(hint, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                          value: settings[category] ?? true,
                          onChanged: (on) => _toggle(category, on),
                        ),
                      ),
                  ],
                ),
    );
  }
}
