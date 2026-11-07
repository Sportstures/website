import 'package:flutter/material.dart';

import '../../ai/ai_provider.dart';
import '../../ai/ai_service.dart';
import '../../data/models.dart';
import '../../theme/app_colors.dart';
import 'ai_analysis_view.dart';
import 'ui_kit.dart';

/// Plain-English read of the results a page is currently showing.
class AiResultsRecapCard extends StatefulWidget {
  const AiResultsRecapCard({super.key, required this.results});

  final List<MatchResult> results;

  @override
  State<AiResultsRecapCard> createState() => _AiResultsRecapCardState();
}

class _AiResultsRecapCardState extends State<AiResultsRecapCard> {
  late Future<AiSummary> _summary;

  /// Cheap stand-in for the whole list: if the filters move, this moves with
  /// them. Avoids refetching on every rebuild once a backend is answering.
  Object _signature(AiResultsRecapCard widget) => (
        widget.results.length,
        widget.results.isEmpty ? null : widget.results.first.fixture,
        widget.results.isEmpty ? null : widget.results.last.fixture,
      );

  @override
  void initState() {
    super.initState();
    _summary = aiService.summarizeResults(widget.results);
  }

  @override
  void didUpdateWidget(AiResultsRecapCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_signature(oldWidget) != _signature(widget)) {
      _summary = aiService.summarizeResults(widget.results);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SummaryCard(
      title: 'AI recap',
      summary: _summary,
      emptyMessage: 'Widen the filters and the recap will read what comes back.',
    );
  }
}

/// Reads a league table the way a reporter would.
class AiStandingsReadCard extends StatefulWidget {
  const AiStandingsReadCard({super.key, required this.standings, required this.sport});

  final List<SchoolStanding> standings;
  final Sport sport;

  @override
  State<AiStandingsReadCard> createState() => _AiStandingsReadCardState();
}

class _AiStandingsReadCardState extends State<AiStandingsReadCard> {
  late Future<AiSummary> _summary;

  Object _signature(AiStandingsReadCard widget) => (
        widget.sport,
        widget.standings.length,
        widget.standings.isEmpty ? null : widget.standings.first.school,
        widget.standings.isEmpty ? 0 : widget.standings.first.points,
      );

  @override
  void initState() {
    super.initState();
    _summary = aiService.summarizeStandings(widget.standings, widget.sport);
  }

  @override
  void didUpdateWidget(AiStandingsReadCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_signature(oldWidget) != _signature(widget)) {
      _summary = aiService.summarizeStandings(widget.standings, widget.sport);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SummaryCard(
      title: 'AI table read',
      summary: _summary,
      emptyMessage: 'Once a few matches are played this table will read properly.',
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.summary,
    required this.emptyMessage,
  });

  final String title;
  final Future<AiSummary> summary;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: title,
      trailing: const AiBadge(),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: FutureBuilder<AiSummary>(
        future: summary,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const _CardMessage('The summary could not be reached just now.');
          }
          final data = snapshot.data;
          if (data == null) {
            return const _CardMessage('Reading the numbers…');
          }
          if (data.isEmpty) {
            return _CardMessage(emptyMessage);
          }
          return _SummaryBody(summary: data);
        },
      ),
    );
  }
}

class _SummaryBody extends StatelessWidget {
  const _SummaryBody({required this.summary});

  final AiSummary summary;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.auto_awesome, size: 14, color: AppColors.green),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                summary.headline,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        for (final insight in summary.insights) _InsightTile(insight: insight),
        const SizedBox(height: 2),
        Text(
          'Read from ${summary.sampleSize} '
          '${summary.sampleSize == 1 ? 'match' : 'matches'} already played.',
          style: const TextStyle(fontSize: 10, color: AppColors.muted),
        ),
      ],
    );
  }
}

class _InsightTile extends StatelessWidget {
  const _InsightTile({required this.insight});

  final AiInsight insight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(insight.icon, size: 13, color: AppColors.green),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.headline,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  insight.detail,
                  style: const TextStyle(fontSize: 10, color: AppColors.muted, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CardMessage extends StatelessWidget {
  const _CardMessage(this.message);

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
