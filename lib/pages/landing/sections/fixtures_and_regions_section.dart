import 'package:flutter/material.dart';

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

class FixturesAndRegionsSection extends StatelessWidget {
  const FixturesAndRegionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final upcoming = SectionCard(
      title: 'Upcoming fixtures',
      trailing: CardLink(
        label: 'View all fixtures',
        onTap: () => openSiteRoute(context, SiteRoutes.fixtures),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DividedColumn(
            children: [
              for (final fixture in SportsData.instance.fixtures.take(5))
                FixtureRow(fixture: fixture, action: AnalyzeButton(fixture: fixture)),
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
      child: _RegionsTable(
        SportsData.rankingsFor(SportsData.instance.results, RankingType.regions, now: DateTime.now()),
      ),
    );

    // Reads the soonest fixtures rather than the whole season, which is all
    // the picks need and keeps the work off the landing page's critical path.
    final picks = AiPicksCard(fixtures: SportsData.instance.fixtures.take(20).toList());

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
                      children: [regions, const SizedBox(height: 20), picks],
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
                const SizedBox(height: 20),
                picks,
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

  final List<RankingEntry> regions;

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
                        standing.title,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: AppColors.ink, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                schools: Text(
                  '${standing.schools.length}',
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
