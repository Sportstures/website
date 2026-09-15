import 'package:flutter/material.dart';

import '../../../data/models.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/site/match_rows.dart';
import '../../../widgets/site/ui_kit.dart';

enum _PerformerStat { scoring, assists, cleanSheets }

class TopPerformersCard extends StatefulWidget {
  const TopPerformersCard({super.key, required this.sport, required this.standings});

  final Sport sport;
  final List<SchoolStanding> standings;

  @override
  State<TopPerformersCard> createState() => _TopPerformersCardState();
}

class _TopPerformersCardState extends State<TopPerformersCard> {
  var _stat = _PerformerStat.scoring;

  String _label(_PerformerStat stat) => switch (stat) {
        _PerformerStat.scoring => widget.sport.scoreLabel,
        _PerformerStat.assists => 'Assists',
        _PerformerStat.cleanSheets => 'Clean sheets',
      };

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Top performers',
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              for (final stat in _PerformerStat.values)
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _stat = stat),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: stat == _stat ? AppColors.green : AppColors.border,
                            width: stat == _stat ? 2 : 1,
                          ),
                        ),
                      ),
                      child: Text(
                        _label(stat).toUpperCase(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: stat == _stat ? AppColors.green : AppColors.muted,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ..._buildList(),
        ],
      ),
    );
  }

  List<Widget> _buildList() {
    // TODO: switch to player leaderboards once the backend records player stats
    if (_stat == _PerformerStat.assists) {
      return const [EmptyState('Assists will show once schools start recording player stats.')];
    }
    if (widget.standings.isEmpty) {
      return const [EmptyState('No results for this table yet.')];
    }

    int valueOf(SchoolStanding s) => _stat == _PerformerStat.scoring ? s.scored : s.cleanSheets;
    final top = ([...widget.standings]..sort((a, b) => valueOf(b).compareTo(valueOf(a)))).take(5);

    return [
      for (final (i, standing) in top.indexed)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              SizedBox(width: 20, child: Text('${i + 1}', style: tableStrongStyle)),
              Expanded(child: SchoolCell(school: standing.school, crestSize: 22)),
              Text('${valueOf(standing)}', style: tableStrongStyle),
            ],
          ),
        ),
    ];
  }
}
