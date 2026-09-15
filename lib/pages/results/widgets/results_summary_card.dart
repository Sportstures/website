import 'package:flutter/material.dart';

import '../../../data/models.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/site/ui_kit.dart';

class ResultsSummaryCard extends StatelessWidget {
  const ResultsSummaryCard({super.key, required this.results});

  final List<MatchResult> results;

  @override
  Widget build(BuildContext context) {
    final tiles = [
      (Icons.event_available_outlined, 'Matches played', results.length),
      (Icons.emoji_events_outlined, 'Home wins', results.where((r) => r.homeWon).length),
      (Icons.directions_bus_outlined, 'Away wins', results.where((r) => r.awayWon).length),
      (Icons.handshake_outlined, 'Draws', results.where((r) => r.isDraw).length),
      (
        Icons.scoreboard_outlined,
        'Points scored',
        results.fold(0, (sum, r) => sum + r.homeScore + r.awayScore),
      ),
    ];

    return SectionCard(
      title: 'Results summary',
      padding: const EdgeInsets.all(12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tileWidth = (constraints.maxWidth - 8) / 2;
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (icon, label, value) in tiles)
                SizedBox(
                  width: tileWidth,
                  child: _SummaryTile(icon: icon, label: label, value: value),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: Icon(icon, size: 15, color: AppColors.green),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 9, color: AppColors.muted),
                ),
                const SizedBox(height: 2),
                Text(
                  formatThousands(value),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.ink),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
