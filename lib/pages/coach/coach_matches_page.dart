import 'package:flutter/material.dart';

import '../../api/api_exception.dart';
import '../../api/coach_api.dart';
import '../../api/fixture_management_api.dart';
import '../../api/session.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';
import '../../widgets/site/page_hero.dart';
import '../../widgets/site/site_routes.dart';
import '../../widgets/site/site_scaffold.dart';
import '../../widgets/site/ui_kit.dart';
import 'coach_guard.dart';
import 'coach_live_page.dart';
import 'lineup_dialog.dart';

/// The coach's upcoming matches: edit, postpone, cancel and set the lineup.
class CoachMatchesPage extends StatelessWidget {
  const CoachMatchesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CoachGuard(
      currentRoute: SiteRoutes.coachMatches,
      title: 'My Matches',
      subtitle: 'Change your fixtures and choose who plays.',
      builder: (context, coach) => _MyMatches(teamId: coach.team?['id'] as int?),
    );
  }
}

const _matchTypes = {
  'friendly': 'Friendly',
  'league': 'League',
  'semifinal': 'Semifinal',
  'championship': 'Championship',
};

class _MyMatches extends StatefulWidget {
  const _MyMatches({required this.teamId});

  final int? teamId;

  @override
  State<_MyMatches> createState() => _MyMatchesState();
}

class _MyMatchesState extends State<_MyMatches> {
  late final FixtureManagementApi _api = FixtureManagementApi(SessionScope.read(context).api);
  late final CoachApi _coach = CoachApi(SessionScope.read(context).api);

  List<ManagedFixture>? _fixtures;
  String? _loadError;
  String? _actionError;
  String? _notice;
  int? _busyId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final teamId = widget.teamId;
    if (teamId == null) {
      setState(() => _loadError = 'Your coach account does not have a team yet.');
      return;
    }
    try {
      final list = await _api.upcoming(teamId);
      if (!mounted) return;
      setState(() {
        _fixtures = list;
        _loadError = null;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _loadError = e.message);
    }
  }

  Future<void> _change(ManagedFixture f, Future<void> Function() action, String done) async {
    setState(() {
      _busyId = f.id;
      _notice = null;
      _actionError = null;
    });
    try {
      await action();
      if (mounted) setState(() => _notice = done);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _actionError = e.code == 'FIXTURE_LOCKED'
            ? 'That match has started or finished, so it can no longer be changed.'
            : (e.fieldErrors.isNotEmpty ? e.fieldErrors.values.first : e.message));
      }
    }
    await _load();
    if (mounted) setState(() => _busyId = null);
  }

  Future<bool> _confirm(String title, String message, String action) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SizedBox(width: 360, child: Text(message)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep it')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(action)),
        ],
      ),
    );
    return yes == true && mounted;
  }

  Future<void> _postpone(ManagedFixture f) async {
    final opponent = f.opponentOf(widget.teamId!);
    if (!await _confirm('Postpone this match?', 'The other coach, players and followers are told.', 'Postpone match')) return;
    await _change(f, () => _api.update(f.id, status: 'postponed'), 'Match against $opponent postponed.');
  }

  Future<void> _cancel(ManagedFixture f) async {
    final opponent = f.opponentOf(widget.teamId!);
    if (!await _confirm('Cancel this match?', 'The match against $opponent will be called off. The other coach, players and followers are told.', 'Cancel match')) {
      return;
    }
    await _change(f, () => _api.update(f.id, status: 'cancelled'), 'Match against $opponent cancelled.');
  }

  /// Edit a match; for a postponed or cancelled one this also puts it back on.
  Future<void> _edit(ManagedFixture f) async {
    final changes = await showDialog<_Changes>(context: context, builder: (_) => _EditDialog(fixture: f));
    if (changes == null || !mounted) return;
    await _change(
      f,
      () => _api.update(
        f.id,
        matchDate: changes.date,
        venue: changes.venue,
        matchType: changes.matchType,
        status: f.status == 'scheduled' ? null : 'scheduled',
      ),
      f.status == 'scheduled' ? 'Match updated.' : 'Match is back on.',
    );
  }

  Future<void> _lineup(ManagedFixture f) async {
    final message = await showDialog<String>(
      context: context,
      builder: (_) => LineupDialog(api: _api, coach: _coach, fixture: f, teamId: widget.teamId!),
    );
    if (message == null || !mounted) return;
    setState(() {
      _notice = message;
      _actionError = null;
    });
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final fixtures = _fixtures;
    return SiteScaffold(
      currentRoute: SiteRoutes.coachMatches,
      children: [
        const PageHero(title: 'My Matches', breadcrumb: 'My Matches', subtitle: 'Change your fixtures and choose who plays.'),
        ContentWidth(
          child: Padding(
            padding: const EdgeInsets.only(top: 28, bottom: 56),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_notice != null) _Banner(_notice!),
                if (_actionError != null) _Banner(_actionError!, error: true),
                SectionCard(
                  title: 'Upcoming matches',
                  trailing: TextButton(
                    onPressed: () => openSiteRoute(context, SiteRoutes.coachMatchInvites),
                    child: const Text('Invite a school'),
                  ),
                  child: _loadError != null
                      ? Column(children: [
                          EmptyState(_loadError!),
                          const SizedBox(height: 8),
                          SiteButton(label: 'TRY AGAIN', small: true, onPressed: _load),
                          const SizedBox(height: 12),
                        ])
                      : fixtures == null
                          ? const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
                          : fixtures.isEmpty
                              ? const EmptyState('No upcoming matches. Invite a school to arrange one.')
                              : DividedColumn(children: [for (final f in fixtures) _row(f)]),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _row(ManagedFixture f) {
    final teamId = widget.teamId!;
    final busy = _busyId == f.id;
    final (label, color) = switch (f.status) {
      'postponed' => ('Postponed', AppColors.orange),
      'cancelled' => ('Cancelled', Colors.red.shade700),
      'live' => ('Live', Colors.red),
      _ => ('Scheduled', AppColors.green),
    };
    const detail = TextStyle(fontSize: 12, color: AppColors.muted, height: 1.45);
    TextButton action(String text, VoidCallback onPressed) => TextButton(onPressed: busy ? null : onPressed, child: Text(text));

    return Padding(
      key: ValueKey('fixture-${f.id}'),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${f.isHome(teamId) ? 'vs' : 'at'} ${f.opponentOf(teamId)}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink),
                ),
              ),
              StatusPill(label, color: color),
            ],
          ),
          Text(
            [
              '${shortWeekday(f.startsAt)} ${formatShortDate(f.startsAt)}, ${formatTime(f.startsAt)}',
              f.competition ?? _matchTypes[f.matchType] ?? f.matchType,
              if (f.venue != null && f.venue!.isNotEmpty) f.venue!,
            ].join(' · '),
            style: detail,
          ),
          if (f.takesLineup)
            Text(f.lineupIn(teamId) ? 'Lineup submitted' : 'No lineup yet',
                style: detail.copyWith(color: f.lineupIn(teamId) ? AppColors.green : AppColors.orange, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 4,
            children: [
              // Scoring opens an hour before kick-off, as the server allows.
              if (f.status == 'live' || (f.status == 'scheduled' && f.startsAt.difference(DateTime.now()) <= const Duration(hours: 1)))
                action(f.status == 'live' ? 'Open live match' : 'Start scoring', () => openSiteRoute(context, CoachLivePage.routeFor(f.id))),
              if (f.takesLineup) action(f.lineupIn(teamId) ? 'Edit lineup' : 'Set lineup', () => _lineup(f)),
              if (f.status == 'scheduled') ...[
                action('Edit', () => _edit(f)),
                action('Postpone', () => _postpone(f)),
              ],
              if (f.status == 'postponed') action('Set new date', () => _edit(f)),
              if (f.status == 'cancelled') action('Put back on', () => _edit(f)),
              if (f.status == 'scheduled' || f.status == 'postponed') action('Cancel match', () => _cancel(f)),
            ],
          ),
        ],
      ),
    );
  }
}

/// What the edit dialog changed. Null means "leave it".
class _Changes {
  const _Changes({this.date, this.venue, this.matchType});

  final DateTime? date;
  final String? venue;
  final String? matchType;
}

class _EditDialog extends StatefulWidget {
  const _EditDialog({required this.fixture});

  final ManagedFixture fixture;

  @override
  State<_EditDialog> createState() => _EditDialogState();
}

class _EditDialogState extends State<_EditDialog> {
  late DateTime _date = DateUtils.dateOnly(widget.fixture.startsAt);
  late TimeOfDay _time = TimeOfDay.fromDateTime(widget.fixture.startsAt);
  late final _venue = TextEditingController(text: widget.fixture.venue ?? '');
  late String _type = _matchTypes.containsKey(widget.fixture.matchType) ? widget.fixture.matchType : 'friendly';
  String? _error;

  @override
  void dispose() {
    _venue.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.isBefore(today) ? today : _date,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
    );
    if (picked != null && mounted) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null && mounted) setState(() => _time = picked);
  }

  void _save() {
    final f = widget.fixture;
    final when = DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute);
    // Compared to the minute: the pickers cannot show seconds.
    final was = f.startsAt;
    final moved = when != DateTime(was.year, was.month, was.day, was.hour, was.minute);
    // A match going back on needs a time still to come.
    if ((moved || f.status != 'scheduled') && !when.isAfter(DateTime.now())) {
      setState(() => _error = 'Choose a date and time in the future.');
      return;
    }
    final venue = _venue.text.trim();
    Navigator.pop(
      context,
      _Changes(
        date: moved ? when : null,
        venue: venue == (f.venue ?? '') ? null : venue,
        matchType: _type == f.matchType ? null : _type,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.fixture.status == 'scheduled' ? 'Edit match' : 'Put the match back on'),
      content: SizedBox(
        width: 380,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(onPressed: _pickDate, icon: const Icon(Icons.event, size: 16), label: Text(formatShortDate(_date))),
                  OutlinedButton.icon(onPressed: _pickTime, icon: const Icon(Icons.schedule, size: 16), label: Text(_time.format(context))),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _venue,
                maxLength: 255,
                decoration: const InputDecoration(labelText: 'Venue', border: OutlineInputBorder(), isDense: true, counterText: ''),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Match type', border: OutlineInputBorder(), isDense: true),
                items: [for (final e in _matchTypes.entries) DropdownMenuItem(value: e.key, child: Text(e.value))],
                onChanged: (v) => setState(() => _type = v ?? _type),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(_error!, style: TextStyle(fontSize: 12, color: Colors.red.shade700, fontWeight: FontWeight.w600)),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        FilledButton(onPressed: _save, child: const Text('Save changes')),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner(this.message, {this.error = false});

  final String message;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final color = error ? Colors.red.shade700 : AppColors.green;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
      child: Text(message, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
    );
  }
}
