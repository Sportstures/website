import 'package:flutter/material.dart';

import '../../../data/models.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/site/match_rows.dart';
import '../../../widgets/site/ui_kit.dart';

const _rankColumn = SiteTableColumn('#', width: 44, alignment: Alignment.centerLeft);
const _schoolColumn = SiteTableColumn('School', alignment: Alignment.centerLeft);

/// Rank number with a trophy or medal for the top three.
class _RankCell extends StatelessWidget {
  const _RankCell(this.index);

  final int index;

  static const _medals = [
    (Icons.emoji_events, Color(0xFFE0A100)),
    (Icons.military_tech, Color(0xFF9CA3AF)),
    (Icons.military_tech, Color(0xFFB45309)),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('${index + 1}', style: tableStrongStyle),
        if (index < _medals.length) ...[
          const SizedBox(width: 4),
          Icon(_medals[index].$1, size: 14, color: _medals[index].$2),
        ],
      ],
    );
  }
}

String _signed(int value) => value > 0 ? '+$value' : '$value';

class LeagueTable extends StatelessWidget {
  const LeagueTable({super.key, required this.standings});

  final List<SchoolStanding> standings;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SiteTable(
          minWidth: 640,
          columns: [
            _rankColumn,
            _schoolColumn,
            for (final label in ['P', 'W', 'D', 'L', 'GF', 'GA', 'GD'])
              // A phone keeps played, goal difference and points.
              SiteTableColumn(label, width: 38, hideOnNarrow: label != 'P' && label != 'GD'),
            const SiteTableColumn('Pts', width: 44),
          ],
          rows: [
            for (final (i, s) in standings.indexed)
              [
                _RankCell(i),
                SchoolCell(school: s.school),
                for (final value in [s.played, s.won, s.drawn, s.lost, s.scored, s.conceded])
                  Text('$value', style: tableCellStyle),
                Text(_signed(s.scoreDifference), style: tableCellStyle),
                Text('${s.points}', style: tableStrongStyle),
              ],
          ],
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(14, 12, 14, 0),
          child: Text(
            'Level on points? Score difference decides, then points scored, then the result between the two schools.',
            style: TextStyle(fontSize: 11, color: AppColors.muted, height: 1.4),
          ),
        ),
        const SizedBox(height: 14),
      ],
    );
  }
}

class FormGuideTable extends StatelessWidget {
  const FormGuideTable({super.key, required this.standings});

  final List<SchoolStanding> standings;

  static Color _outcomeColor(MatchOutcome outcome) => switch (outcome) {
        MatchOutcome.win => AppColors.greenBright,
        MatchOutcome.draw => AppColors.muted,
        MatchOutcome.loss => const Color(0xFFDC2626),
      };

  @override
  Widget build(BuildContext context) {
    return SiteTable(
      minWidth: 520,
      columns: const [
        _rankColumn,
        _schoolColumn,
        SiteTableColumn('Last 5', width: 130, alignment: Alignment.centerLeft),
        SiteTableColumn('Pts', width: 44),
      ],
      rows: [
        for (final (i, s) in standings.indexed)
          [
            _RankCell(i),
            SchoolCell(school: s.school),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final outcome in s.form.take(5))
                  Container(
                    width: 20,
                    height: 20,
                    margin: const EdgeInsets.only(right: 4),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _outcomeColor(outcome),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      outcome.letter,
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                    ),
                  ),
              ],
            ),
            Text('${s.points}', style: tableStrongStyle),
          ],
      ],
    );
  }
}

class ScoringTable extends StatelessWidget {
  const ScoringTable({super.key, required this.standings, required this.scoreLabel});

  final List<SchoolStanding> standings;
  final String scoreLabel;

  @override
  Widget build(BuildContext context) {
    final sorted = [...standings]..sort((a, b) => b.scored.compareTo(a.scored));
    return SiteTable(
      minWidth: 480,
      columns: [
        _rankColumn,
        _schoolColumn,
        const SiteTableColumn('P', width: 44),
        SiteTableColumn(scoreLabel, width: 64),
        const SiteTableColumn('Per game', width: 72),
      ],
      rows: [
        for (final (i, s) in sorted.indexed)
          [
            _RankCell(i),
            SchoolCell(school: s.school),
            Text('${s.played}', style: tableCellStyle),
            Text('${s.scored}', style: tableStrongStyle),
            Text((s.scored / s.played).toStringAsFixed(1), style: tableCellStyle),
          ],
      ],
    );
  }
}

class CleanSheetsTable extends StatelessWidget {
  const CleanSheetsTable({super.key, required this.standings});

  final List<SchoolStanding> standings;

  @override
  Widget build(BuildContext context) {
    final sorted = [...standings]
      ..sort((a, b) {
        final byCleanSheets = b.cleanSheets.compareTo(a.cleanSheets);
        return byCleanSheets != 0 ? byCleanSheets : a.conceded.compareTo(b.conceded);
      });
    return SiteTable(
      minWidth: 480,
      columns: const [
        _rankColumn,
        _schoolColumn,
        SiteTableColumn('P', width: 44),
        SiteTableColumn('Clean sheets', width: 90),
        SiteTableColumn('%', width: 56, hideOnNarrow: true),
      ],
      rows: [
        for (final (i, s) in sorted.indexed)
          [
            _RankCell(i),
            SchoolCell(school: s.school),
            Text('${s.played}', style: tableCellStyle),
            Text('${s.cleanSheets}', style: tableStrongStyle),
            Text('${(100 * s.cleanSheets / s.played).round()}%', style: tableCellStyle),
          ],
      ],
    );
  }
}
