import 'package:flutter/material.dart';

import '../../../api/api_client.dart';
import '../../../api/rankings_api.dart';
import '../../../data/match_store.dart';
import '../../../data/models.dart';
import '../../../data/sports_data.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/site/ai_analysis_view.dart';
import '../../../widgets/site/ai_picks_card.dart';
import '../../../widgets/site/match_rows.dart';
import '../../../widgets/site/site_routes.dart';
import '../../../widgets/site/site_scaffold.dart';
import '../../../widgets/site/ui_kit.dart';

typedef _Region = ({String name, int schools, int points});

/// The soonest fixtures, the leading regions and the match picks. With a backend these are live;
/// on a page built without one they come from the sample data.
class FixturesAndRegionsSection extends StatefulWidget {
  const FixturesAndRegionsSection({super.key});

  @override
  State<FixturesAndRegionsSection> createState() => _FixturesAndRegionsSectionState();
}

class _FixturesAndRegionsSectionState extends State<FixturesAndRegionsSection> {
  MatchStore? _store;
  List<_Region>? _regions;
  bool _regionsFailed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final store = MatchScope.maybeOf(context);
    if (identical(store, _store)) return;
    _store = store;
    final api = store?.api;
    if (api == null) return;
    // Not during build: loading notifies listeners.
    WidgetsBinding.instance.addPostFrameCallback((_) => store!.ensureLoaded());
    _loadRegions(api);
  }

  Future<void> _loadRegions(ApiClient api) async {
    try {
      final result = await RankingsApi(api).rankings(type: 'regions', limit: 9);
      if (!mounted) return;
      setState(() {
        _regions = [for (final r in result.rows) (name: r.name, schools: r.schoolsRanked ?? 0, points: r.points)];
        _regionsFailed = false;
      });
    } catch (_) {
      if (mounted) setState(() => _regionsFailed = true);
    }
  }

  void _retry() {
    final store = _store!;
    setState(() => _regionsFailed = false);
    store.reload();
    _loadRegions(store.api!);
  }

  List<_Region> _sampleRegions() => [
        for (final r in SportsData.rankingsFor(SportsData.instance.results, RankingType.regions, now: DateTime.now()))
          (name: r.title, schools: r.schools.length, points: r.points),
      ];

  Widget _waiting(bool failed, String message) => failed
      ? Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(children: [
            EmptyState(message),
            SiteButton(label: 'TRY AGAIN', small: true, onPressed: _retry),
          ]),
        )
      : const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()));

  @override
  Widget build(BuildContext context) {
    final store = MatchScope.maybeOf(context);
    final live = store?.api != null;
    final data = store == null ? SportsData.instance : store.data;
    final regionRows = live ? _regions : _sampleRegions();

    final upcoming = SectionCard(
      title: 'Upcoming fixtures',
      trailing: CardLink(
        label: 'View all fixtures',
        onTap: () => openSiteRoute(context, SiteRoutes.fixtures),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (data == null)
            _waiting(store?.state == MatchLoad.failed, "Fixtures couldn't be loaded.")
          else if (data.fixtures.isEmpty)
            const EmptyState('No upcoming fixtures yet.')
          else
            DividedColumn(
              children: [
                for (final fixture in data.fixtures.take(5)) FixtureRow(fixture: fixture, action: AnalyzeButton(fixture: fixture)),
              ],
            ),
          const SizedBox(height: 8),
          Center(
            child: SiteButton(
              label: 'VIEW ALL FIXTURES',
              small: true,
              onPressed: () => openSiteRoute(context, SiteRoutes.fixtures),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );

    final regions = SectionCard(
      title: 'Top regions - Champ race',
      trailing: CardLink(
        label: 'View full rankings',
        onTap: () => openSiteRoute(context, SiteRoutes.rankings, arguments: RankingType.regions),
      ),
      padding: EdgeInsets.zero,
      child: regionRows == null
          ? _waiting(_regionsFailed, "Rankings couldn't be loaded.")
          : regionRows.isEmpty
              ? const EmptyState('No results yet.')
              : _RegionsTable(regionRows),
    );

    // Reads the soonest fixtures rather than the whole season, which is all
    // the picks need and keeps the work off the landing page's critical path.
    final picks = data == null || data.fixtures.isEmpty ? null : AiPicksCard(fixtures: data.fixtures.take(20).toList());

    return ContentWidth(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 56),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= 900) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: upcoming),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [regions, if (picks != null) ...[const SizedBox(height: 20), picks]],
                    ),
                  ),
                ],
              );
            }
            return Column(
              children: [
                upcoming,
                const SizedBox(height: 20),
                regions,
                if (picks != null) ...[const SizedBox(height: 20), picks],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _RegionsTable extends StatelessWidget {
  const _RegionsTable(this.regions);

  final List<_Region> regions;

  @override
  Widget build(BuildContext context) {
    const headerStyle = TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.muted);

    Widget line({required Widget rank, required Widget region, required Widget schools, required Widget points}) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            SizedBox(width: 36, child: rank),
            Expanded(child: region),
            SizedBox(width: 64, child: schools),
            SizedBox(width: 64, child: points),
          ],
        ),
      );
    }

    return Column(
      children: [
        ColoredBox(
          color: AppColors.surface,
          child: line(
            rank: const Text('NO.', style: headerStyle),
            region: const Text('REGION', style: headerStyle),
            schools: const Text('SCHOOLS', textAlign: TextAlign.center, style: headerStyle),
            points: const Text('POINTS', textAlign: TextAlign.right, style: headerStyle),
          ),
        ),
        DividedColumn(
          children: [
            for (final (i, standing) in regions.indexed)
              line(
                rank: Text(
                  '${i + 1}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: i < 3 ? FontWeight.w900 : FontWeight.w500,
                    color: i < 3 ? AppColors.orange : AppColors.ink,
                  ),
                ),
                region: Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(color: AppColors.orange, shape: BoxShape.circle),
                      child: const Icon(Icons.shield_outlined, size: 12, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        standing.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: AppColors.ink, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                schools: Text(
                  '${standing.schools}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: AppColors.ink),
                ),
                points: Text(
                  formatThousands(standing.points),
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.ink),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
