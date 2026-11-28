import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../api/api_exception.dart';
import '../../api/match_results_api.dart';
import '../../theme/app_colors.dart';

/// Enter or correct a match's final score. Closes with a message once saved.
class ResultDialog extends StatefulWidget {
  const ResultDialog({
    super.key,
    required this.api,
    required this.fixtureId,
    required this.homeName,
    required this.awayName,
    this.homeScore,
    this.awayScore,
  });

  final MatchResultsApi api;
  final int fixtureId;
  final String homeName;
  final String awayName;

  /// The score already recorded, when correcting one.
  final int? homeScore;
  final int? awayScore;

  @override
  State<ResultDialog> createState() => _ResultDialogState();
}

class _ResultDialogState extends State<ResultDialog> {
  late final _home = TextEditingController(text: widget.homeScore?.toString() ?? '');
  late final _away = TextEditingController(text: widget.awayScore?.toString() ?? '');
  bool _saving = false;
  String? _error;

  bool get _correcting => widget.homeScore != null;

  @override
  void dispose() {
    _home.dispose();
    _away.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final home = int.tryParse(_home.text.trim());
    final away = int.tryParse(_away.text.trim());
    if (home == null || away == null) {
      setState(() => _error = 'Enter both scores.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.api.recordResult(widget.fixtureId, homeScore: home, awayScore: away);
      if (mounted) Navigator.pop(context, _correcting ? 'Score corrected.' : 'Result recorded.');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = switch (e.code) {
          'FIXTURE_NOT_STARTED' => 'The match time has not come yet.',
          'FIXTURE_NOT_PLAYABLE' => 'This match is postponed or cancelled.',
          'MATCH_LIVE' => 'This match is being scored live. End it from the live scoring page.',
          'FORBIDDEN' => "Only the home team's coach can record the result.",
          _ => e.fieldErrors.isNotEmpty ? e.fieldErrors.values.first : e.message,
        };
      });
    }
  }

  Widget _score(String team, TextEditingController controller) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Expanded(child: Text(team, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink))),
            const SizedBox(width: 12),
            SizedBox(
              width: 90,
              child: TextField(
                key: ValueKey('score-$team'),
                controller: controller,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                // Scores run from 0 to 999.
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)],
                onSubmitted: (_) => _save(),
                decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
              ),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(_correcting ? 'Correct the score' : 'Record the result'),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _score(widget.homeName, _home),
              _score(widget.awayName, _away),
              const Text('This is the final score. Tables and rankings update from it.',
                  style: TextStyle(fontSize: 12, color: AppColors.muted)),
              if (_error != null) _DialogError(_error!),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          FilledButton(onPressed: _saving ? null : _save, child: Text(_saving ? 'Saving…' : 'Save result')),
        ],
      );
}

/// Write or edit a match report. Closes with a message once saved.
class ReportDialog extends StatefulWidget {
  const ReportDialog({super.key, required this.api, required this.fixtureId, required this.title});

  final MatchResultsApi api;
  final int fixtureId;

  /// e.g. "vs Riverside College"
  final String title;

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  final _summary = TextEditingController();
  MatchReport? _existing;
  bool _loading = true;
  bool _loadFailed = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _summary.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
      _error = null;
    });
    try {
      final report = await widget.api.report(widget.fixtureId);
      if (!mounted) return;
      setState(() {
        _existing = report;
        _summary.text = report?.summary ?? '';
        _loading = false;
      });
    } on ApiException catch (e) {
      // Without knowing what is there, saving could overwrite the other coach's report.
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadFailed = true;
        _error = e.message;
      });
    }
  }

  Future<void> _save() async {
    final text = _summary.text.trim();
    if (text.isEmpty) {
      setState(() => _error = 'Write a few words about the match.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.api.fileReport(widget.fixtureId, text);
      if (mounted) Navigator.pop(context, 'Match report saved.');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = switch (e.code) {
          'FIXTURE_NOT_FINISHED' => 'Record the result before filing the report.',
          'FORBIDDEN' => 'Only the coaches of these two teams can file this report.',
          _ => e.fieldErrors.isNotEmpty ? e.fieldErrors.values.first : e.message,
        };
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final existing = _existing;
    return AlertDialog(
      title: Text('Match report ${widget.title}'),
      content: SizedBox(
        width: 520,
        child: _loading
            ? const SizedBox(height: 120, child: Center(child: CircularProgressIndicator()))
            : _loadFailed
                ? Column(mainAxisSize: MainAxisSize.min, children: [
                    _DialogError(_error!),
                    TextButton(onPressed: _load, child: const Text('Try again')),
                  ])
                : SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          existing == null
                              ? 'Both coaches share one report for the match.'
                              : 'Last saved by ${existing.author ?? 'a coach'}. Saving replaces it for both coaches.',
                          style: const TextStyle(fontSize: 12, color: AppColors.muted),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _summary,
                          minLines: 5,
                          maxLines: 10,
                          maxLength: 5000,
                          decoration: const InputDecoration(labelText: 'What happened?', alignLabelWithHint: true, border: OutlineInputBorder()),
                        ),
                        if (_error != null) _DialogError(_error!),
                      ],
                    ),
                  ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        FilledButton(
          onPressed: _loading || _loadFailed || _saving ? null : _save,
          child: Text(_saving ? 'Saving…' : 'Save report'),
        ),
      ],
    );
  }
}

class _DialogError extends StatelessWidget {
  const _DialogError(this.message);

  final String message;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Text(message, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.red.shade700)),
      );
}
