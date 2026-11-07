import 'dart:math';

import 'package:flutter/material.dart';

import '../../ai/ai_provider.dart';
import '../../ai/ai_service.dart';
import '../../data/models.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';
import 'match_rows.dart';

/// Shared marker for anything on the site the model produced, so AI output is
/// never mistaken for a result that actually happened.
class AiBadge extends StatelessWidget {
  const AiBadge({super.key, this.label = 'AI', this.onDark = false});

  final String label;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.green, AppColors.greenBright]),
        borderRadius: BorderRadius.circular(20),
        border: onDark ? Border.all(color: Colors.white.withValues(alpha: 0.25)) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome, size: 10, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

/// Opens the full analysis for [fixture] in a dialog.
Future<void> showMatchAnalysis(BuildContext context, Fixture fixture) {
  return showDialog<void>(
    context: context,
    builder: (context) {
      final width = MediaQuery.sizeOf(context).width;
      return Dialog(
        insetPadding: EdgeInsets.symmetric(horizontal: width < 560 ? 12 : 24, vertical: 24),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DialogHeader(fixture: fixture),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: AiAnalysisView(fixture: fixture),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _DialogHeader extends StatelessWidget {
  const _DialogHeader({required this.fixture});

  final Fixture fixture;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.greenDark, AppColors.green],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AiBadge(label: 'AI match analysis', onDark: true),
                const SizedBox(height: 8),
                Text(
                  '${fixture.home.name} vs ${fixture.away.name}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${fixture.competition} · ${formatShortDate(fixture.startsAt)} · '
                  '${formatTime(fixture.startsAt)}',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 11),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.white, size: 20),
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }
}

/// Runs the analyser for [fixture] and lays the result out.
///
/// Reads through [aiService], so this renders the backend's answer unchanged
/// once that is wired up. [compact] drops the deeper sections for sidebar use.
class AiAnalysisView extends StatefulWidget {
  const AiAnalysisView({super.key, required this.fixture, this.compact = false});

  final Fixture fixture;
  final bool compact;

  @override
  State<AiAnalysisView> createState() => _AiAnalysisViewState();
}

class _AiAnalysisViewState extends State<AiAnalysisView> {
  late Future<MatchAnalysis> _analysis;

  @override
  void initState() {
    super.initState();
    _analysis = aiService.analyzeFixture(widget.fixture);
  }

  @override
  void didUpdateWidget(AiAnalysisView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fixture != widget.fixture) {
      _analysis = aiService.analyzeFixture(widget.fixture);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<MatchAnalysis>(
      future: _analysis,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _AnalysisMessage(
            icon: Icons.cloud_off_outlined,
            message: 'The analyser could not be reached. Try again in a moment.',
          );
        }
        final analysis = snapshot.data;
        if (analysis == null) {
          return const _AnalysisMessage(
            icon: Icons.auto_awesome,
            message: 'Reading recent form…',
          );
        }
        return _AnalysisBody(analysis: analysis, compact: widget.compact);
      },
    );
  }
}

class _AnalysisMessage extends StatelessWidget {
  const _AnalysisMessage({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          Icon(icon, size: 26, color: AppColors.muted),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _AnalysisBody extends StatelessWidget {
  const _AnalysisBody({required this.analysis, required this.compact});

  final MatchAnalysis analysis;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Verdict(analysis: analysis),
        const SizedBox(height: 14),
        _OutcomeBar(analysis: analysis),
        const SizedBox(height: 16),
        _PredictedScore(analysis: analysis),
        if (!compact) ...[
          const SizedBox(height: 20),
          _Heading(
            'Recent form',
            trailing: 'Last ${max(analysis.homeForm.played, analysis.awayForm.played)} '
                'in ${analysis.fixture.sport.label.toLowerCase()}',
          ),
          const SizedBox(height: 10),
          _FormRow(form: analysis.homeForm, sport: analysis.fixture.sport),
          const SizedBox(height: 8),
          _FormRow(form: analysis.awayForm, sport: analysis.fixture.sport),
          const SizedBox(height: 20),
          const _Heading('Head to head'),
          const SizedBox(height: 10),
          _HeadToHeadPanel(analysis: analysis),
        ],
        const SizedBox(height: 20),
        const _Heading('What this is based on'),
        const SizedBox(height: 10),
        for (final factor in compact ? analysis.factors.take(2) : analysis.factors)
          _FactorTile(factor: factor, analysis: analysis),
        const SizedBox(height: 16),
        _Disclaimer(confidence: analysis.confidence),
      ],
    );
  }
}

class _Verdict extends StatelessWidget {
  const _Verdict({required this.analysis});

  final MatchAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.auto_awesome, size: 16, color: AppColors.green),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            analysis.verdict,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink),
          ),
        ),
      ],
    );
  }
}

/// Stacked home / draw / away bar, coloured to match the two crests.
class _OutcomeBar extends StatelessWidget {
  const _OutcomeBar({required this.analysis});

  final MatchAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final fixture = analysis.fixture;
    final segments = [
      (analysis.homeWinChance, fixture.home.color, '${fixture.home.name} win'),
      (analysis.drawChance, AppColors.muted, 'Draw'),
      (analysis.awayWinChance, fixture.away.color, '${fixture.away.name} win'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: SizedBox(
            height: 10,
            child: Row(
              // Stretch, so the segments are given a tight height. A ColoredBox
              // with no child takes the smallest size it is offered, and under
              // the default centre alignment that is a height of zero.
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (chance, color, label) in segments)
                  if (chance > 0.004)
                    Expanded(
                      flex: (chance * 1000).round(),
                      child: Tooltip(
                        message: '$label ${_percent(chance)}',
                        child: ColoredBox(color: color),
                      ),
                    ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            for (final (chance, color, label) in segments)
              Expanded(
                child: _OutcomeLegend(
                  chance: chance,
                  color: color,
                  label: label.replaceFirst(' win', ''),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _OutcomeLegend extends StatelessWidget {
  const _OutcomeLegend({required this.chance, required this.color, required this.label});

  final double chance;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
            Text(
              _percent(chance),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.ink),
            ),
          ],
        ),
        const SizedBox(height: 1),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 10, color: AppColors.muted),
        ),
      ],
    );
  }
}

class _PredictedScore extends StatelessWidget {
  const _PredictedScore({required this.analysis});

  final MatchAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Projected scoreline',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.muted),
            ),
          ),
          Text(
            analysis.predictedScoreline,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.ink),
          ),
          const SizedBox(width: 8),
          Text(
            analysis.fixture.sport.scoreLabel.toLowerCase(),
            style: const TextStyle(fontSize: 10, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text, {this.trailing});

  final String text;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            text.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: AppColors.ink,
              letterSpacing: 0.5,
            ),
          ),
        ),
        if (trailing != null)
          Text(
            trailing!,
            style: const TextStyle(fontSize: 10, color: AppColors.muted),
          ),
      ],
    );
  }
}

class _FormRow extends StatelessWidget {
  const _FormRow({required this.form, required this.sport});

  final TeamForm form;
  final Sport sport;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: SchoolCell(school: form.school, crestSize: 22)),
        if (form.played == 0)
          const Text(
            'No recent matches',
            style: TextStyle(fontSize: 10, color: AppColors.muted),
          )
        else ...[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final outcome in form.outcomes.take(6)) _FormDot(outcome: outcome),
            ],
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 62,
            child: Text(
              '${form.averageScored.toStringAsFixed(1)}-${form.averageConceded.toStringAsFixed(1)}',
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.ink),
            ),
          ),
        ],
      ],
    );
  }
}

class _FormDot extends StatelessWidget {
  const _FormDot({required this.outcome});

  final MatchOutcome outcome;

  @override
  Widget build(BuildContext context) {
    final color = switch (outcome) {
      MatchOutcome.win => AppColors.green,
      MatchOutcome.draw => AppColors.muted,
      MatchOutcome.loss => const Color(0xFFDC2626),
    };

    return Container(
      width: 16,
      height: 16,
      margin: const EdgeInsets.only(left: 3),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
      child: Text(
        outcome.letter,
        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white),
      ),
    );
  }
}

class _HeadToHeadPanel extends StatelessWidget {
  const _HeadToHeadPanel({required this.analysis});

  final MatchAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final h2h = analysis.headToHead;
    final fixture = analysis.fixture;

    if (!h2h.hasHistory) {
      return const Text(
        'These two have not met in this sport yet, so the read leans entirely on form.',
        style: TextStyle(fontSize: 11, color: AppColors.muted, height: 1.5),
      );
    }

    final last = h2h.lastMeeting;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _H2hTally(count: h2h.homeWins, label: fixture.home.name, color: fixture.home.color),
            _H2hTally(count: h2h.draws, label: 'Drawn', color: AppColors.muted),
            _H2hTally(count: h2h.awayWins, label: fixture.away.name, color: fixture.away.color),
          ],
        ),
        if (last != null) ...[
          const SizedBox(height: 10),
          Text(
            'Last meeting · ${formatShortDate(last.fixture.startsAt)}: '
            '${last.fixture.home.name} ${last.homeScore}-${last.awayScore} '
            '${last.fixture.away.name}',
            style: const TextStyle(fontSize: 11, color: AppColors.muted, height: 1.5),
          ),
        ],
      ],
    );
  }
}

class _H2hTally extends StatelessWidget {
  const _H2hTally({required this.count, required this.label, required this.color});

  final int count;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _FactorTile extends StatelessWidget {
  const _FactorTile({required this.factor, required this.analysis});

  final AiFactor factor;
  final MatchAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final color = switch (factor.lean) {
      AiLean.home => analysis.fixture.home.color,
      AiLean.away => analysis.fixture.away.color,
      AiLean.neutral => AppColors.muted,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 3,
            height: 32,
            margin: const EdgeInsets.only(top: 2, right: 10),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  factor.headline,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  factor.detail,
                  style: const TextStyle(fontSize: 11, color: AppColors.muted, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Disclaimer extends StatelessWidget {
  const _Disclaimer({required this.confidence});

  final AiConfidence confidence;

  @override
  Widget build(BuildContext context) {
    final color = switch (confidence) {
      AiConfidence.low => AppColors.orange,
      AiConfidence.medium => AppColors.muted,
      AiConfidence.high => AppColors.green,
    };

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 13, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  confidence.label,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color),
                ),
                const SizedBox(height: 2),
                Text(
                  '${confidence.detail} A projection from past results, not a forecast of what '
                  'will happen.',
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

String _percent(double chance) => '${(chance * 100).round()}%';

/// "Analyse" affordance used on fixture rows.
class AnalyzeButton extends StatelessWidget {
  const AnalyzeButton({super.key, required this.fixture});

  final Fixture fixture;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'AI analysis of this fixture',
      child: InkWell(
        onTap: () => showMatchAnalysis(context, fixture),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.green.withValues(alpha: 0.4)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome, size: 11, color: AppColors.green),
              SizedBox(width: 5),
              Text(
                'ANALYSE',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: AppColors.green,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
