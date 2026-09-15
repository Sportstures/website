import 'package:flutter/material.dart';

import '../../../data/models.dart';
import '../../../data/sports_data.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/site/match_rows.dart';
import '../../../widgets/site/ui_kit.dart';

/// The leading school in each region, with a shortcut to that region's table.
class TopByRegion extends StatelessWidget {
  const TopByRegion({super.key, required this.rankings, required this.onViewRegion});

  /// School rankings, best first.
  final List<RankingEntry> rankings;
  final ValueChanged<String> onViewRegion;

  @override
  Widget build(BuildContext context) {
    final leaders = [
      for (final region in SportsData.regions) ?rankings.where((e) => e.region == region).firstOrNull,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'TOP SCHOOLS BY REGION',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.ink),
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            const gap = 12.0;
            final columns = constraints.maxWidth >= 640 ? 4 : 2;
            final cardWidth = (constraints.maxWidth - gap * (columns - 1)) / columns;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final leader in leaders)
                  SizedBox(
                    width: cardWidth,
                    child: _RegionLeaderCard(
                      entry: leader,
                      onView: () => onViewRegion(leader.region),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _RegionLeaderCard extends StatelessWidget {
  const _RegionLeaderCard({required this.entry, required this.onView});

  final RankingEntry entry;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            entry.region.toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.muted),
          ),
          const SizedBox(height: 10),
          TeamCrest(school: entry.school!, size: 40),
          const SizedBox(height: 8),
          Text(
            entry.title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.ink),
          ),
          const SizedBox(height: 2),
          Text(
            '${formatThousands(entry.points)} pts',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.orange),
          ),
          const SizedBox(height: 10),
          SiteButton(
            label: 'VIEW TOP 10',
            variant: SiteButtonVariant.outline,
            small: true,
            expand: true,
            onPressed: onView,
          ),
        ],
      ),
    );
  }
}
