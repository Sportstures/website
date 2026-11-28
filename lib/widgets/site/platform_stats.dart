import 'package:flutter/material.dart';

import '../../api/api_client.dart';
import '../../data/match_store.dart';

/// Headline numbers about the platform, as the backend counts them.
class PlatformCounts {
  const PlatformCounts({required this.schools, required this.provinces, required this.sports, required this.matches});

  final int schools;

  /// Provinces with at least one school.
  final int provinces;

  /// Sports some school has a team in.
  final int sports;

  /// Finished matches with a score.
  final int matches;

  static Future<PlatformCounts> load(ApiClient api) async {
    final schools = await api.get('/api/schools', query: {'limit': 1}, auth: false) as Map<String, dynamic>;
    final filters = await api.get('/api/schools/filters', auth: false) as Map<String, dynamic>;
    final results = await api.get('/api/results', query: {'limit': 1}, auth: false) as Map<String, dynamic>;
    return PlatformCounts(
      schools: schools['total'] as int,
      provinces: (filters['provinces'] as List).where((p) => ((p as Map)['schoolCount'] as int) > 0).length,
      sports: (filters['sports'] as List).length,
      matches: (results['summary'] as Map)['matchesPlayed'] as int,
    );
  }
}

/// Shows [live] with the backend's counts, or [sample] on a page built without a backend. While the
/// counts are loading, or if they cannot be fetched, it shows nothing: no figure is better than a made-up one.
class PlatformStats extends StatefulWidget {
  const PlatformStats({super.key, required this.sample, required this.live});

  final Widget sample;
  final Widget Function(PlatformCounts counts) live;

  @override
  State<PlatformStats> createState() => _PlatformStatsState();
}

class _PlatformStatsState extends State<PlatformStats> {
  ApiClient? _api;
  PlatformCounts? _counts;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final api = MatchScope.maybeOf(context)?.api;
    if (identical(api, _api)) return;
    _api = api;
    if (api != null) _load(api);
  }

  Future<void> _load(ApiClient api) async {
    try {
      final counts = await PlatformCounts.load(api);
      if (mounted) setState(() => _counts = counts);
    } catch (_) {
      // Stays empty.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_api == null) return widget.sample;
    final counts = _counts;
    return counts == null ? const SizedBox.shrink() : widget.live(counts);
  }
}
