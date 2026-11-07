import 'package:flutter/material.dart';

import '../../../data/models.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/site/ai_analysis_view.dart';
import '../../../widgets/site/ui_kit.dart';

/// Sidebar analyser. Steps through whichever fixtures the page is currently
/// showing, so it always reflects the visitor's filters.
class AiAnalyzerCard extends StatefulWidget {
  const AiAnalyzerCard({super.key, required this.fixtures});

  final List<Fixture> fixtures;

  @override
  State<AiAnalyzerCard> createState() => _AiAnalyzerCardState();
}

class _AiAnalyzerCardState extends State<AiAnalyzerCard> {
  int _index = 0;

  @override
  void didUpdateWidget(AiAnalyzerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Filters changed under us; start again from the top of the new list.
    if (oldWidget.fixtures != widget.fixtures && _index >= widget.fixtures.length) {
      _index = 0;
    }
  }

  void _step(int delta) {
    setState(() {
      final count = widget.fixtures.length;
      _index = (_index + delta + count) % count;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.fixtures.isEmpty) {
      return const SectionCard(
        title: 'AI match analyser',
        trailing: AiBadge(),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Text(
            'Pick a day with fixtures and the analyser will read it.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: AppColors.muted),
          ),
        ),
      );
    }

    final fixture = widget.fixtures[_index.clamp(0, widget.fixtures.length - 1)];

    return SectionCard(
      title: 'AI match analyser',
      trailing: const AiBadge(),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _FixturePicker(
            fixture: fixture,
            position: _index + 1,
            total: widget.fixtures.length,
            onPrevious: widget.fixtures.length > 1 ? () => _step(-1) : null,
            onNext: widget.fixtures.length > 1 ? () => _step(1) : null,
          ),
          const Divider(height: 20, color: AppColors.border),
          AiAnalysisView(key: ValueKey(fixture), fixture: fixture, compact: true),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: CardLink(
              label: 'FULL ANALYSIS',
              onTap: () => showMatchAnalysis(context, fixture),
            ),
          ),
        ],
      ),
    );
  }
}

class _FixturePicker extends StatelessWidget {
  const _FixturePicker({
    required this.fixture,
    required this.position,
    required this.total,
    required this.onPrevious,
    required this.onNext,
  });

  final Fixture fixture;
  final int position;
  final int total;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StepArrow(icon: Icons.chevron_left, onTap: onPrevious, tooltip: 'Previous fixture'),
        Expanded(
          child: Column(
            children: [
              Text(
                '${fixture.home.name} vs ${fixture.away.name}',
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${fixture.competition} · $position of $total',
                style: const TextStyle(fontSize: 9, color: AppColors.muted),
              ),
            ],
          ),
        ),
        _StepArrow(icon: Icons.chevron_right, onTap: onNext, tooltip: 'Next fixture'),
      ],
    );
  }
}

class _StepArrow extends StatelessWidget {
  const _StepArrow({required this.icon, required this.onTap, required this.tooltip});

  final IconData icon;
  final VoidCallback? onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      color: AppColors.ink,
      disabledColor: AppColors.border,
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
      padding: EdgeInsets.zero,
    );
  }
}
