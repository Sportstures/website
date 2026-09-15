import 'package:flutter/material.dart';

import '../../../data/models.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/site/match_rows.dart';
import '../../../widgets/site/ui_kit.dart';

// TODO: keep in sync with the backend's ranking formula
const rankingWeights = [
  ('Match wins', 40),
  ('Strength of opposition', 25),
  ('Goals scored', 20),
  ('Consistency', 10),
  ('Participation', 5),
];

class RankingWeightsList extends StatelessWidget {
  const RankingWeightsList({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (label, weight) in rankingWeights)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(label, style: tableCellStyle)),
                    Text('$weight%', style: tableStrongStyle),
                  ],
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: weight / 100,
                    minHeight: 5,
                    color: AppColors.orange,
                    backgroundColor: AppColors.border,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class RankingBreakdownCard extends StatelessWidget {
  const RankingBreakdownCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const SectionCard(
      title: 'Ranking breakdown',
      padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: RankingWeightsList(),
    );
  }
}

class TopSportsCard extends StatelessWidget {
  const TopSportsCard({super.key, required this.pointsBySport});

  final List<(Sport, int)> pointsBySport;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Top performing sports',
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      child: pointsBySport.isEmpty
          ? const EmptyState('No results yet.')
          : Column(
              children: [
                for (final (sport, points) in pointsBySport.take(5))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    child: Row(
                      children: [
                        Icon(sport.icon, size: 16, color: AppColors.ink),
                        const SizedBox(width: 10),
                        Expanded(child: Text(sport.label, style: tableCellStyle)),
                        Text('${formatThousands(points)} pts', style: tableStrongStyle),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

class TopRisesCard extends StatefulWidget {
  const TopRisesCard({super.key, required this.rankings});

  final List<RankingEntry> rankings;

  @override
  State<TopRisesCard> createState() => _TopRisesCardState();
}

class _TopRisesCardState extends State<TopRisesCard> {
  var _showAll = false;

  @override
  Widget build(BuildContext context) {
    final rises = widget.rankings.where((e) => e.trend > 0).toList()
      ..sort((a, b) => b.trend.compareTo(a.trend));
    final shown = _showAll ? rises : rises.take(5);

    return SectionCard(
      title: 'Top rise this season',
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
      child: rises.isEmpty
          ? const EmptyState('No schools have climbed the rankings this week.')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (i, entry) in shown.indexed)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        SizedBox(width: 20, child: Text('${i + 1}', style: tableStrongStyle)),
                        Expanded(child: SchoolCell(school: entry.school!, crestSize: 22)),
                        TrendIndicator(entry.trend),
                      ],
                    ),
                  ),
                if (rises.length > 5) ...[
                  const SizedBox(height: 8),
                  Center(
                    child: SiteButton(
                      label: _showAll ? 'SHOW TOP 5' : 'VIEW ALL RISES',
                      variant: SiteButtonVariant.outline,
                      small: true,
                      onPressed: () => setState(() => _showAll = !_showAll),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}
