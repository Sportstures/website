import 'package:flutter/material.dart';

import '../../api/api_exception.dart';
import '../../api/competitions_api.dart';
import '../../api/match_invitations_api.dart';
import '../../api/team_details_api.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';

/// Puts a match that is already agreed straight onto the calendar, with my team at home.
/// Closes with a message once saved.
class AddMatchDialog extends StatefulWidget {
  const AddMatchDialog({super.key, required this.teams, required this.fixtures, required this.competitions, required this.teamId});

  final MatchInvitationsApi teams;
  final TeamDetailsApi fixtures;
  final CompetitionsApi competitions;
  final int teamId;

  @override
  State<AddMatchDialog> createState() => _AddMatchDialogState();
}

class _AddMatchDialogState extends State<AddMatchDialog> {
  final _search = TextEditingController();
  final _venue = TextEditingController();

  int? _sportId;
  List<MatchTeam>? _found;
  MatchTeam? _opponent;
  List<Competition> _competitions = const [];
  int? _competitionId;
  DateTime? _date;
  TimeOfDay _time = const TimeOfDay(hour: 15, minute: 0);
  String _type = 'friendly';
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _search.dispose();
    _venue.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    try {
      _sportId = (await widget.teams.team(widget.teamId)).sportId;
      await _find();
      final all = await widget.competitions.list(sportId: _sportId);
      if (mounted) setState(() => _competitions = [for (final c in all) if (c.status != 'completed') c]);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _find() async {
    try {
      final found = await widget.teams.opponents(sportId: _sportId, query: _search.text.trim());
      if (mounted) setState(() => _found = [for (final t in found) if (t.id != widget.teamId) t]);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _pickDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    // Past dates are allowed, for recording a match already played.
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? today.add(const Duration(days: 7)),
      firstDate: today.subtract(const Duration(days: 365)),
      lastDate: today.add(const Duration(days: 365)),
    );
    if (picked != null && mounted) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null && mounted) setState(() => _time = picked);
  }

  Future<void> _save() async {
    final opponent = _opponent;
    final date = _date;
    if (opponent == null || date == null) {
      setState(() => _error = opponent == null ? 'Choose the team you are playing.' : 'Choose the match date.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.fixtures.createFixture(
        homeTeamId: widget.teamId,
        awayTeamId: opponent.id,
        matchDate: DateTime(date.year, date.month, date.day, _time.hour, _time.minute),
        matchType: _type,
        venue: _venue.text.trim(),
        competitionId: _competitionId,
      );
      if (mounted) Navigator.pop(context, 'Match against ${opponent.school} added.');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = switch (e.code) {
          'SPORT_MISMATCH' => 'Both teams must play the same sport.',
          'FORBIDDEN' => 'You can only add matches for your own team at home.',
          _ => e.fieldErrors.isNotEmpty ? e.fieldErrors.values.first : e.message,
        };
      });
    }
  }

  InputDecoration _input(String label) =>
      InputDecoration(labelText: label, border: const OutlineInputBorder(), isDense: true, counterText: '');

  @override
  Widget build(BuildContext context) {
    const muted = TextStyle(fontSize: 12, color: AppColors.muted, height: 1.5);
    final opponent = _opponent;
    final found = _found;
    return AlertDialog(
      title: const Text('Add a home match'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'For a match already agreed: it goes on both teams\' calendars at once. To ask a school first, send a match invitation instead.',
                style: muted,
              ),
              const SizedBox(height: 12),
              if (opponent != null)
                Row(children: [
                  Expanded(child: Text('Playing ${opponent.school} (${opponent.name})', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
                  TextButton(onPressed: () => setState(() => _opponent = null), child: const Text('Change')),
                ])
              else ...[
                TextField(
                  controller: _search,
                  onSubmitted: (_) => _find(),
                  decoration: _input('Search opponents').copyWith(suffixIcon: IconButton(icon: const Icon(Icons.search), onPressed: _find)),
                ),
                const SizedBox(height: 6),
                if (found == null)
                  const Padding(padding: EdgeInsets.all(8), child: Center(child: CircularProgressIndicator()))
                else if (found.isEmpty)
                  const Text('No teams found for your sport.', style: muted)
                else
                  // A short list; searching narrows it.
                  for (final t in found.take(6))
                    Row(children: [
                      Expanded(child: Text('${t.school} · ${t.name}', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13))),
                      TextButton(onPressed: () => setState(() => _opponent = t), child: const Text('Pick')),
                    ]),
              ],
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: [
                OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.event, size: 16),
                  label: Text(_date == null ? 'Match date' : formatShortDate(_date!)),
                ),
                OutlinedButton.icon(onPressed: _pickTime, icon: const Icon(Icons.schedule, size: 16), label: Text(_time.format(context))),
              ]),
              const SizedBox(height: 12),
              TextField(key: const ValueKey('Venue'), controller: _venue, maxLength: 255, decoration: _input('Venue (optional)')),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: _input('Match type'),
                items: const [
                  DropdownMenuItem(value: 'friendly', child: Text('Friendly')),
                  DropdownMenuItem(value: 'league', child: Text('League')),
                  DropdownMenuItem(value: 'semifinal', child: Text('Semifinal')),
                  DropdownMenuItem(value: 'championship', child: Text('Championship')),
                ],
                onChanged: (v) => setState(() => _type = v ?? _type),
              ),
              if (_competitions.isNotEmpty) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<int?>(
                  initialValue: _competitionId,
                  isExpanded: true,
                  decoration: _input('Competition (optional)'),
                  items: [
                    const DropdownMenuItem<int?>(value: null, child: Text('None')),
                    for (final c in _competitions) DropdownMenuItem<int?>(value: c.id, child: Text(c.name, overflow: TextOverflow.ellipsis)),
                  ],
                  onChanged: (v) => setState(() => _competitionId = v),
                ),
              ],
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(_error!, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.red.shade700)),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        FilledButton(onPressed: _saving ? null : _save, child: Text(_saving ? 'Saving…' : 'Add match')),
      ],
    );
  }
}
