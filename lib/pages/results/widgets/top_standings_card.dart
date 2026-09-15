import 'package:flutter/material.dart';

import '../../../data/models.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/site/match_rows.dart';
import '../../../widgets/site/ui_kit.dart';

class TopStandingsCard extends StatelessWidget {
  const TopStandingsCard({
    super.key,
    required this.standings,
    required this.showAll,
    required this.onToggle,
  });

  static const _collapsedRows = 6;
  static const _statWidth = 28.0;

  final List<SchoolStanding> standings;
  final bool showAll;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final canExpand = standings.length > _collapsedRows;
    final rows = showAll ? standings : standings.take(_collapsedRows);

    return SectionCard(
      title: 'Top standings',
      trailing: canExpand
          ? CardLink(label: showAll ? 'Show top 6' : 'View all standings', onTap: onToggle)
          : null,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: standings.isEmpty
          ? const EmptyState('No results to rank yet.')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _line(
                  rank: const Text('#', style: _headerStyle),
                  school: const Text('SCHOOL', style: _headerStyle),
                  stats: const ['P', 'W', 'D', 'L', 'PTS'],
                  style: _headerStyle,
                ),
                for (final (i, standing) in rows.indexed)
                  _line(
                    rank: Text('${i + 1}', style: _cellStyle),
                    school: Row(
                      children: [
                        TeamCrest(school: standing.school, size: 20),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            standing.school.name,
                            overflow: TextOverflow.ellipsis,
                            style: _cellStyle,
                          ),
                        ),
                      ],
                    ),
                    stats: [
                      standing.played,
                      standing.won,
                      standing.drawn,
                      standing.lost,
                      standing.points,
                    ].map((n) => '$n').toList(),
                    style: _cellStyle,
                  ),
                if (canExpand) ...[
                  const SizedBox(height: 12),
                  SiteButton(
                    label: showAll ? 'SHOW LESS' : 'FULL STANDINGS',
                    small: true,
                    expand: true,
                    onPressed: onToggle,
                  ),
                ],
              ],
            ),
    );
  }

  static const _headerStyle = TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.muted);
  static const _cellStyle = TextStyle(fontSize: 11, color: AppColors.ink);

  Widget _line({
    required Widget rank,
    required Widget school,
    required List<String> stats,
    required TextStyle style,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 20, child: rank),
          Expanded(child: school),
          for (final (i, stat) in stats.indexed)
            SizedBox(
              width: _statWidth,
              child: Text(
                stat,
                textAlign: TextAlign.center,
                style: i == stats.length - 1 ? style.copyWith(fontWeight: FontWeight.w800) : style,
              ),
            ),
        ],
      ),
    );
  }
}
