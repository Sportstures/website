import 'package:flutter/material.dart';

import '../../ai/ai_provider.dart';
import '../../ai/ai_service.dart';
import '../../data/models.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';
import 'ai_analysis_view.dart';
import 'match_rows.dart';
import 'ui_kit.dart';

/// "Matches to watch": the fixtures the model rates as the best watch, each
/// with the reason it was picked. Tapping one opens the full analysis.
class AiPicksCard extends StatefulWidget {
  const AiPicksCard({
    super.key,
    required this.fixtures,
    this.title = 'Matches to watch',
    this.limit = 3,
  });

  final List<Fixture> fixtures;
  final String title;
  final int limit;

  @override
  State<AiPicksCard> createState() => _AiPicksCardState();
}

class _AiPicksCardState extends State<AiPicksCard> {
  late Future<List<AiPick>> _picks;

  /// Cheap stand-in for the whole list, so a filter change reloads but an
  /// ordinary rebuild does not.
  Object _signature(AiPicksCard widget) => (
        widget.limit,
        widget.fixtures.length,
        widget.fixtures.isEmpty ? null : widget.fixtures.first,
        widget.fixtures.isEmpty ? null : widget.fixtures.last,
      );

  @override
  void initState() {
    super.initState();
    _picks = aiService.recommendFixtures(widget.fixtures, limit: widget.limit);
  }

  @override
  void didUpdateWidget(AiPicksCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_signature(oldWidget) != _signature(widget)) {
      _picks = aiService.recommendFixtures(widget.fixtures, limit: widget.limit);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: widget.title,
      trailing: const AiBadge(),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: FutureBuilder<List<AiPick>>(
        future: _picks,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const _PicksMessage('The picks could not be reached just now.');
          }
          final picks = snapshot.data;
          if (picks == null) {
            return const _PicksMessage('Weighing up the fixtures…');
          }
          if (picks.isEmpty) {
            return const _PicksMessage(
              'Nothing stands out yet. Once these sides have played a few matches the '
              'picks will fill in.',
            );
          }
          return DividedColumn(
            children: [for (final pick in picks) _PickRow(pick: pick)],
          );
        },
      ),
    );
  }
}

class _PickRow extends StatelessWidget {
  const _PickRow({required this.pick});

  final AiPick pick;

  @override
  Widget build(BuildContext context) {
    final fixture = pick.fixture;

    return InkWell(
      onTap: () => showMatchAnalysis(context, fixture),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                TeamCrest(school: fixture.home, size: 20),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${fixture.home.name} vs ${fixture.away.name}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                      height: 1.3,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                TeamCrest(school: fixture.away, size: 20),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              '${fixture.competition} · ${formatShortDate(fixture.startsAt)} · '
              '${formatTime(fixture.startsAt)}',
              style: const TextStyle(fontSize: 9, color: AppColors.orange, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              pick.reason,
              style: const TextStyle(fontSize: 10, color: AppColors.muted, height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}

class _PicksMessage extends StatelessWidget {
  const _PicksMessage(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 11, color: AppColors.muted, height: 1.4),
      ),
    );
  }
}
