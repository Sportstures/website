import 'package:flutter/material.dart';

import '../../ai/ai_provider.dart';
import '../../ai/ai_service.dart';
import '../../data/match_store.dart';
import '../../data/models.dart';
import '../../theme/app_colors.dart';
import 'ai_analysis_view.dart';

/// One line in the conversation.
class _Turn {
  const _Turn.thinking(this.question)
      : answer = null,
        pending = true;
  const _Turn.answered(this.question, this.answer) : pending = false;

  final String question;
  final AiAnswer? answer;
  final bool pending;
}

/// Floating "Ask Sportstures" button, pinned to the corner of every page.
class AiAssistantLauncher extends StatefulWidget {
  const AiAssistantLauncher({super.key});

  @override
  State<AiAssistantLauncher> createState() => _AiAssistantLauncherState();
}

class _AiAssistantLauncherState extends State<AiAssistantLauncher> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final compact = size.width < 520;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (_open)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: compact ? size.width - 40 : 380,
                  maxHeight: size.height * 0.7,
                ),
                child: _AssistantPanel(onClose: () => setState(() => _open = false)),
              ),
            ),
          _LauncherButton(
            open: _open,
            onTap: () => setState(() => _open = !_open),
          ),
        ],
      ),
    );
  }
}

class _LauncherButton extends StatelessWidget {
  const _LauncherButton({required this.open, required this.onTap});

  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.green,
      borderRadius: BorderRadius.circular(28),
      elevation: 6,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(open ? Icons.close : Icons.auto_awesome, size: 18, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                open ? 'Close' : 'Ask Sportstures',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AssistantPanel extends StatefulWidget {
  const _AssistantPanel({required this.onClose});

  final VoidCallback onClose;

  @override
  State<_AssistantPanel> createState() => _AssistantPanelState();
}

class _AssistantPanelState extends State<_AssistantPanel> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final _turns = <_Turn>[];
  /// Questions that need no school name, for while the matches are still loading.
  static const _generalStarters = ['What is on this week?', 'Who is top in football?', 'Which matches are worth watching?'];

  List<String> get _starters {
    final store = MatchScope.maybeOf(context);
    return store?.api != null && store!.data == null ? _generalStarters : aiService.starterQuestions();
  }

  @override
  void initState() {
    super.initState();
    // Answers come from the live matches, so fetch them as soon as the panel opens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) MatchScope.maybeOf(context)?.ensureLoaded();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send(String question) async {
    final trimmed = question.trim();
    if (trimmed.isEmpty) return;

    _controller.clear();
    setState(() => _turns.add(_Turn.thinking(trimmed)));
    _scrollToEnd();

    // Never answer a live site's questions from the sample data.
    final store = MatchScope.maybeOf(context);
    if (store?.api != null && store!.data == null) await store.ensureLoaded();
    if (!mounted) return;
    final answer = store?.api != null && store!.data == null
        ? const AiAnswer(text: "I couldn't load the matches just now. Please try again in a moment.")
        : await aiService.ask(trimmed);
    if (!mounted) return;

    setState(() {
      _turns
        ..removeLast()
        ..add(_Turn.answered(trimmed, answer));
    });
    _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 10,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PanelHeader(onClose: widget.onClose),
          Flexible(
            child: SingleChildScrollView(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_turns.isEmpty) _Welcome(starters: _starters, onPick: _send),
                  for (final turn in _turns) _TurnView(turn: turn, onPick: _send),
                ],
              ),
            ),
          ),
          _Composer(controller: _controller, onSend: _send),
        ],
      ),
    );
  }
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.greenDark, AppColors.green],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ask Sportstures',
                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 1),
                Text(
                  'Fixtures, form and tables',
                  style: TextStyle(color: Colors.white70, fontSize: 10),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close, color: Colors.white, size: 18),
            tooltip: 'Close',
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _Welcome extends StatelessWidget {
  const _Welcome({required this.starters, required this.onPick});

  final List<String> starters;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ask about any school, sport or region in the season so far.',
          style: TextStyle(fontSize: 12, color: AppColors.ink, height: 1.5),
        ),
        const SizedBox(height: 12),
        _Suggestions(items: starters, onPick: onPick),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _TurnView extends StatelessWidget {
  const _TurnView({required this.turn, required this.onPick});

  final _Turn turn;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final answer = turn.answer;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Container(
            margin: const EdgeInsets.only(bottom: 10, left: 32),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.green,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              turn.question,
              style: const TextStyle(color: Colors.white, fontSize: 12, height: 1.4),
            ),
          ),
        ),
        if (turn.pending)
          const Padding(
            padding: EdgeInsets.only(bottom: 14),
            child: Row(
              children: [
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.green),
                ),
                SizedBox(width: 8),
                Text('Looking it up…', style: TextStyle(fontSize: 11, color: AppColors.muted)),
              ],
            ),
          )
        else if (answer != null)
          _AnswerView(answer: answer, onPick: onPick),
      ],
    );
  }
}

class _AnswerView extends StatelessWidget {
  const _AnswerView({required this.answer, required this.onPick});

  final AiAnswer answer;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final fixture = answer.fixture;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14, right: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2, right: 7),
                child: Icon(Icons.auto_awesome, size: 13, color: AppColors.green),
              ),
              Expanded(
                child: Text(
                  answer.text,
                  style: const TextStyle(fontSize: 12, color: AppColors.ink, height: 1.5),
                ),
              ),
            ],
          ),
          if (answer.insights.isNotEmpty) ...[
            const SizedBox(height: 10),
            for (final insight in answer.insights) _InsightLine(insight: insight),
          ],
          if (fixture != null) ...[
            const SizedBox(height: 8),
            _AnalyseLink(fixture: fixture),
          ],
          if (answer.suggestions.isNotEmpty) ...[
            const SizedBox(height: 10),
            _Suggestions(items: answer.suggestions, onPick: onPick),
          ],
        ],
      ),
    );
  }
}

class _InsightLine extends StatelessWidget {
  const _InsightLine({required this.insight});

  final AiInsight insight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1, right: 7),
            child: Icon(insight.icon, size: 12, color: AppColors.muted),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.headline,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                    height: 1.3,
                  ),
                ),
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

class _AnalyseLink extends StatelessWidget {
  const _AnalyseLink({required this.fixture});

  final Fixture fixture;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20),
      child: Align(
        alignment: Alignment.centerLeft,
        child: AnalyzeButton(fixture: fixture),
      ),
    );
  }
}

class _Suggestions extends StatelessWidget {
  const _Suggestions({required this.items, required this.onPick});

  final List<String> items;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final item in items)
          InkWell(
            onTap: () => onPick(item),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                item,
                style: const TextStyle(fontSize: 10, color: AppColors.ink),
              ),
            ),
          ),
      ],
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({required this.controller, required this.onSend});

  final TextEditingController controller;
  final ValueChanged<String> onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 10),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onSubmitted: onSend,
              textInputAction: TextInputAction.send,
              style: const TextStyle(fontSize: 12, color: AppColors.ink),
              decoration: const InputDecoration(
                hintText: 'Ask about a school, sport or region…',
                hintStyle: TextStyle(fontSize: 12, color: AppColors.muted),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          IconButton(
            onPressed: () => onSend(controller.text),
            icon: const Icon(Icons.send, size: 18, color: AppColors.green),
            tooltip: 'Send',
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
