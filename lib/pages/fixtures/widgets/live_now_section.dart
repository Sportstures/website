import 'dart:async';

import 'package:flutter/material.dart';

import '../../../api/api_client.dart';
import '../../../api/live_scoring_api.dart';
import '../../../data/match_store.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/site/ui_kit.dart';

/// How often the scores of matches in progress are asked for again.
const liveScoresInterval = Duration(seconds: 20);

/// Matches being played right now, with their confirmed scores. Takes no space when there are none,
/// and does nothing on a page that uses the sample data.
class LiveNowSection extends StatefulWidget {
  const LiveNowSection({super.key});

  @override
  State<LiveNowSection> createState() => _LiveNowSectionState();
}

class _LiveNowSectionState extends State<LiveNowSection> {
  MatchStore? _store;
  Timer? _poll;
  List<LiveMatch> _matches = const [];
  bool _loading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final store = MatchScope.maybeOf(context);
    if (identical(store, _store)) return;
    _store = store;
    _poll?.cancel();
    _poll = null;
    final api = store?.api;
    if (api == null) return;
    _load(api);
    _poll = Timer.periodic(liveScoresInterval, (_) => _load(api));
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _load(ApiClient api) async {
    if (_loading) return;
    _loading = true;
    try {
      final body = await api.get('/api/fixtures', query: {'status': 'live', 'limit': 20}, auth: false) as Map<String, dynamic>;
      final scoring = LiveScoringApi(api);
      final matches = await Future.wait([
        for (final f in body['fixtures'] as List)
          if ((f as Map)['status'] == 'live') scoring.match(f['id'] as int),
      ]);
      if (!mounted) return;
      final now = {for (final m in matches) m.fixture.id};
      final ended = _matches.any((m) => !now.contains(m.fixture.id));
      setState(() => _matches = [for (final m in matches) if (m.fixture.status == 'live') m]);
      // A match that has just ended belongs in the results now.
      if (ended) _store?.reload();
    } catch (_) {
      // Unreachable or an unexpected reply: keep the last scores shown; the next check tries again.
    } finally {
      _loading = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_matches.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: SectionCard(
        title: 'Live now',
        child: DividedColumn(children: [for (final m in _matches) _LiveRow(m)]),
      ),
    );
  }
}

class _LiveRow extends StatelessWidget {
  const _LiveRow(this.match);

  final LiveMatch match;

  @override
  Widget build(BuildContext context) {
    final f = match.fixture;
    // Only scores both sides agree on are shown to the public.
    final scorers = [
      for (final g in match.goals)
        if (g.status == 'confirmed')
          [if (g.minute != null) "${g.minute}'", g.playerName ?? g.teamName].join(' '),
    ];
    const name = TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink);
    return Padding(
      key: ValueKey('live-${f.id}'),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Text(f.homeName, textAlign: TextAlign.right, style: name)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text('${match.homeScore} - ${match.awayScore}',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.green)),
              ),
              Expanded(child: Text(f.awayName, style: name)),
            ],
          ),
          const SizedBox(height: 4),
          const StatusPill('Live', color: Colors.red),
          if (scorers.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(scorers.join(' · '),
                  textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
            ),
        ],
      ),
    );
  }
}
