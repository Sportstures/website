import 'package:flutter/material.dart';

import '../../api/api_exception.dart';
import '../../api/coach_api.dart';
import '../../api/fixture_management_api.dart';
import '../../theme/app_colors.dart';

/// Choose who starts and who is on the bench for one match. Closes with a message once saved or withdrawn.
class LineupDialog extends StatefulWidget {
  const LineupDialog({super.key, required this.api, required this.coach, required this.fixture, required this.teamId});

  final FixtureManagementApi api;
  final CoachApi coach;
  final ManagedFixture fixture;
  final int teamId;

  @override
  State<LineupDialog> createState() => _LineupDialogState();
}

class _LineupDialogState extends State<LineupDialog> {
  /// The server's limit for starters, and for the bench.
  static const _max = 25;

  final _formation = TextEditingController();
  final Map<int, LineupSlot> _slots = {};
  List<RosterMember>? _squad;
  bool _submitted = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _formation.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final squad = await widget.coach.roster(widget.teamId);
      final existing = await widget.api.lineup(widget.fixture.id, widget.teamId);
      if (!mounted) return;
      setState(() {
        _squad = squad;
        _submitted = existing != null;
        _formation.text = existing?.formation ?? '';
        // Players who have since left the squad are not carried over.
        for (final p in squad) {
          if (existing?.starters.contains(p.userId) ?? false) _slots[p.userId] = LineupSlot.starter;
          if (existing?.bench.contains(p.userId) ?? false) _slots[p.userId] = LineupSlot.bench;
        }
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  List<int> _in(LineupSlot slot) => [
        for (final p in _squad ?? const <RosterMember>[])
          if (_slots[p.userId] == slot) p.userId,
      ];

  Future<void> _run(Future<void> Function() action, String done) async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await action();
      if (mounted) Navigator.pop(context, done);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = switch (e.code) {
          'FIXTURE_CLOSED' => 'This match is finished or cancelled, so the lineup is closed.',
          'NOT_ON_TEAM' => 'Someone you picked is no longer in the squad. Close this and try again.',
          _ => e.message,
        };
      });
    }
  }

  void _save() {
    final starters = _in(LineupSlot.starter);
    final bench = _in(LineupSlot.bench);
    if (starters.isEmpty) {
      setState(() => _error = 'Pick at least one starter.');
      return;
    }
    if (starters.length > _max || bench.length > _max) {
      setState(() => _error = 'A lineup can have at most $_max starters and $_max on the bench.');
      return;
    }
    _run(
      () => widget.api.submitLineup(widget.fixture.id, widget.teamId,
          starters: starters, bench: bench, formation: _formation.text.trim()),
      'Lineup saved.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final squad = _squad;
    return AlertDialog(
      title: Text('Lineup vs ${widget.fixture.opponentOf(widget.teamId)}'),
      content: SizedBox(
        width: 520,
        height: 440,
        child: squad == null
            ? Center(child: _error == null ? const CircularProgressIndicator() : Text(_error!))
            : squad.isEmpty
                ? const Center(child: Text('Add players to your squad before choosing a lineup.', textAlign: TextAlign.center))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '${_in(LineupSlot.starter).length} starting · ${_in(LineupSlot.bench).length} on the bench',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.green),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _formation,
                        maxLength: 30,
                        decoration: const InputDecoration(
                            labelText: 'Formation (optional)', border: OutlineInputBorder(), isDense: true, counterText: ''),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.separated(
                          itemCount: squad.length,
                          separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.border),
                          itemBuilder: (context, index) {
                            final p = squad[index];
                            final slot = _slots[p.userId] ?? LineupSlot.out;
                            ChoiceChip chip(String label, LineupSlot value) => ChoiceChip(
                                  label: Text(label),
                                  selected: slot == value,
                                  showCheckmark: false,
                                  visualDensity: VisualDensity.compact,
                                  onSelected: (on) => setState(() => _slots[p.userId] = on ? value : LineupSlot.out),
                                );
                            return Padding(
                              key: ValueKey('player-${p.userId}'),
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                children: [
                                  SizedBox(width: 32, child: Text(p.jerseyNumber?.toString() ?? '–')),
                                  Expanded(
                                    child: Text(
                                      [p.name, if (p.position != null && p.position!.isNotEmpty) p.position!].join(' · '),
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 13, color: AppColors.ink),
                                    ),
                                  ),
                                  chip('Start', LineupSlot.starter),
                                  const SizedBox(width: 6),
                                  chip('Bench', LineupSlot.bench),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(_error!, style: TextStyle(fontSize: 12, color: Colors.red.shade700, fontWeight: FontWeight.w600)),
                        ),
                    ],
                  ),
      ),
      actions: [
        if (_submitted)
          TextButton(
            onPressed: _saving
                ? null
                : () => _run(() => widget.api.withdrawLineup(widget.fixture.id, widget.teamId), 'Lineup withdrawn.'),
            child: const Text('Withdraw lineup'),
          ),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        FilledButton(onPressed: _saving || squad == null || squad.isEmpty ? null : _save, child: const Text('Save lineup')),
      ],
    );
  }
}
