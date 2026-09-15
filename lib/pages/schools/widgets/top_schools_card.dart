import 'package:flutter/material.dart';

import '../../../data/models.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/site/match_rows.dart';
import '../../../widgets/site/site_routes.dart';
import '../../../widgets/site/ui_kit.dart';

class TopSchoolsCard extends StatelessWidget {
  const TopSchoolsCard({super.key, required this.rankings});

  /// School rankings, best first.
  final List<RankingEntry> rankings;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Top performing schools',
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Based on overall performance this season.',
            style: TextStyle(fontSize: 11, color: AppColors.muted),
          ),
          const SizedBox(height: 6),
          for (final (i, entry) in rankings.take(5).indexed)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  SizedBox(width: 20, child: Text('${i + 1}', style: tableStrongStyle)),
                  Expanded(child: SchoolCell(school: entry.school!, crestSize: 22)),
                  Text(
                    '${formatThousands(entry.points)} PTS',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.ink),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          SiteButton(
            label: 'VIEW ALL RANKINGS',
            variant: SiteButtonVariant.outline,
            small: true,
            expand: true,
            onPressed: () => openSiteRoute(context, SiteRoutes.rankings),
          ),
        ],
      ),
    );
  }
}
