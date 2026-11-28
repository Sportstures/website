import 'package:flutter/material.dart';

import '../../api/api_exception.dart';
import '../../api/competitions_api.dart';
import '../../api/match_invitations_api.dart';
import '../../api/session.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';
import '../../widgets/site/page_hero.dart';
import '../../widgets/site/site_routes.dart';
import '../../widgets/site/site_scaffold.dart';
import '../../widgets/site/ui_kit.dart';
import 'coach_guard.dart';
import 'photo_badge.dart';

/// Invite another school to a match, and answer the invitations they send.
class CoachMatchInvitesPage extends StatelessWidget {
  const CoachMatchInvitesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CoachGuard(
      currentRoute: SiteRoutes.coachMatchInvites,
      title: 'Match Invitations',
      subtitle: 'Arrange matches with other schools.',
      builder: (context, coach) => _Matches(teamId: coach.team?['id'] as int?),
    );
  }
}

const _matchTypes = {
  'friendly': 'Friendly',
  'league': 'League',
  'semifinal': 'Semifinal',
  'championship': 'Championship',
};

String _when(DateTime date) => '${shortWeekday(date)} ${formatShortDate(date)}, ${formatTime(date)}';

class _Matches extends StatefulWidget {
  const _Matches({required this.teamId});

  final int? teamId;

  @override
  State<_Matches> createState() => _MatchesState();
}

class _MatchesState extends State<_Matches> {
  late final MatchInvitationsApi _api = MatchInvitationsApi(SessionScope.read(context).api);

  List<MatchInvitation>? _invitations;
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
    try {
      final list = await _api.list();
      if (!mounted) return;
      setState(() {
        _invitations = list;
        _loadError = null;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _loadError = e.message);
    }
  }

  Future<void> _act(MatchInvitation invitation, Future<void> Function() action, String done) async {
    setState(() {
      _busyId = invitation.id;
      _actionError = null;
      _notice = null;
    });
    try {
      await action();
      if (mounted) setState(() => _notice = done);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _actionError = e.code == 'INVITATION_CLOSED'
            ? 'That invitation has already been answered, withdrawn or has expired.'
            : e.message);
      }
    }
    await _load();
    if (mounted) setState(() => _busyId = null);
  }

  Future<void> _decline(MatchInvitation i) async {
    final reason = await showDialog<String>(context: context, builder: (_) => const _DeclineDialog());
    if (reason == null || !mounted) return;
    await _act(i, () => _api.decline(i.id, message: reason), 'You declined the match with ${i.inviterTeam.school}.');
  }

  @override
  Widget build(BuildContext context) {
    final all = _invitations;
    final waiting = [for (final i in all ?? const <MatchInvitation>[]) if (i.isPending && i.isReceived) i];
    final rest = [for (final i in all ?? const <MatchInvitation>[]) if (!(i.isPending && i.isReceived)) i];

    return SiteScaffold(
      currentRoute: SiteRoutes.coachMatchInvites,
      children: [
        const PageHero(
          title: 'Match Invitations',
          breadcrumb: 'Match Invitations',
          subtitle: 'Invite another school to play. When they accept, the match goes on the fixtures list.',
        ),
        ContentWidth(
          child: Padding(
            padding: const EdgeInsets.only(top: 28, bottom: 56),
            child: TwoColumnLayout(
              main: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_notice != null) _Banner(_notice!),
                  if (_actionError != null) _Banner(_actionError!, error: true),
                  if (waiting.isNotEmpty) ...[
                    SectionCard(
                      title: 'Waiting for your answer',
                      child: DividedColumn(children: [for (final i in waiting) _row(i)]),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (widget.teamId == null)
                    const SectionCard(
                      title: 'Invite a school to a match',
                      child: EmptyState('Your coach account does not have a team yet.'),
                    )
                  else
                    _InviteForm(
                      api: _api,
                      teamId: widget.teamId!,
                      onSent: (school) {
                        setState(() {
                          _notice = 'Invitation sent to $school. We will show their answer here.';
                          _actionError = null;
                        });
                        _load();
                      },
                    ),
                ],
              ),
              sidebar: SectionCard(
                title: 'Your invitations',
                child: _loadError != null
                    ? Column(children: [
                        EmptyState(_loadError!),
                        const SizedBox(height: 8),
                        SiteButton(label: 'TRY AGAIN', small: true, onPressed: _load),
                        const SizedBox(height: 12),
                      ])
                    : all == null
                        ? const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
                        : rest.isEmpty
                            ? const EmptyState('Invitations you send or answer will show here.')
                            : DividedColumn(children: [for (final i in rest) _row(i)]),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _row(MatchInvitation i) {
    final other = i.isReceived ? i.inviterTeam : i.invitedTeam;
    final (label, color) = switch (i.status) {
      'accepted' => ('Accepted', AppColors.green),
      'declined' => ('Declined', Colors.red.shade700),
      'cancelled' => ('Withdrawn', AppColors.muted),
      'expired' => ('Expired', AppColors.muted),
      _ => (i.isReceived ? 'New' : 'Waiting', AppColors.orange),
    };
    // The side of the match the signed-in coach is on.
    final mine = i.isReceived ? i.invitedTeam : i.inviterTeam;
    final home = i.homeTeam.id == mine.id;
    final busy = _busyId == i.id;
    const detail = TextStyle(fontSize: 12, color: AppColors.muted, height: 1.45);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PhotoBadge(url: other.logoUrl, fallback: other.school, size: 40, square: true),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${i.isReceived ? 'From' : 'To'} ${other.school}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.ink),
                      ),
                    ),
                    StatusPill(label, color: color),
                  ],
                ),
                Text(other.name, style: detail),
                Text(
                  [
                    _when(i.matchDate),
                    _matchTypes[i.matchType] ?? i.matchType,
                    home ? 'At home' : 'Away',
                    if (i.venue != null && i.venue!.isNotEmpty) i.venue!,
                  ].join(' · '),
                  style: detail,
                ),
                if (i.message != null && i.message!.isNotEmpty) Text('"${i.message}"', style: detail),
                if (i.responseMessage != null && i.responseMessage!.isNotEmpty)
                  Text('Reply: "${i.responseMessage}"', style: detail),
                if (i.canRespond || i.canCancel) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (i.canRespond && i.isReceived) ...[
                        SiteButton(
                          label: busy ? 'ONE MOMENT…' : 'ACCEPT',
                          small: true,
                          onPressed: busy
                              ? null
                              : () => _act(i, () => _api.accept(i.id), 'Match confirmed with ${i.inviterTeam.school}. It is now on your fixtures.'),
                        ),
                        TextButton(onPressed: busy ? null : () => _decline(i), child: const Text('Decline')),
                      ],
                      if (i.canCancel && !i.isReceived)
                        TextButton(
                          onPressed: busy
                              ? null
                              : () => _act(i, () => _api.withdraw(i.id), 'You withdrew the invitation to ${i.invitedTeam.school}.'),
                          child: const Text('Withdraw'),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Find a team, pick when and where, and send.
class _InviteForm extends StatefulWidget {
  const _InviteForm({required this.api, required this.teamId, required this.onSent});

  final MatchInvitationsApi api;
  final int teamId;
  final void Function(String school) onSent;

  @override
  State<_InviteForm> createState() => _InviteFormState();
}

class _InviteFormState extends State<_InviteForm> {
  final _search = TextEditingController();
  final _venue = TextEditingController();
  final _message = TextEditingController();

  MatchTeam? _mine;
  List<MatchTeam>? _results;
  MatchTeam? _opponent;
  DateTime? _date;
  TimeOfDay _time = const TimeOfDay(hour: 15, minute: 0);
  bool _atHome = true;

  /// Competitions for this sport that the match could count towards.
  List<Competition> _competitions = const [];
  int? _competitionId;
  String _type = 'friendly';
  bool _searching = false;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _find().then((_) => _loadCompetitions());
  }

  Future<void> _loadCompetitions() async {
    final sportId = _mine?.sportId;
    if (!mounted || sportId == null) return;
    try {
      final all = await CompetitionsApi(SessionScope.read(context).api).list(sportId: sportId);
      // Ones I organise first; finished ones are left out.
      final open = [for (final c in all) if (c.status != 'completed') c]..sort((a, b) => (b.canEdit ? 1 : 0) - (a.canEdit ? 1 : 0));
      if (mounted) setState(() => _competitions = open);
    } on ApiException {
      // An invitation can be sent without a competition.
    }
  }

  @override
  void dispose() {
    _search.dispose();
    _venue.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _find() async {
    setState(() {
      _searching = true;
      _error = null;
    });
    try {
      // Only teams playing the same sport can be invited.
      _mine ??= await widget.api.team(widget.teamId);
      final found = await widget.api.opponents(sportId: _mine!.sportId, query: _search.text.trim());
      if (mounted) setState(() => _results = [for (final t in found) if (t.id != widget.teamId) t]);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _pickDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? today.add(const Duration(days: 7)),
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
    );
    if (picked != null && mounted) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null && mounted) setState(() => _time = picked);
  }

  Future<void> _send() async {
    final opponent = _opponent;
    final date = _date;
    if (opponent == null || date == null) {
      setState(() => _error = opponent == null ? 'Choose the team you want to play.' : 'Choose the match date.');
      return;
    }
    final when = DateTime(date.year, date.month, date.day, _time.hour, _time.minute);
    if (!when.isAfter(DateTime.now())) {
      setState(() => _error = 'The match must be in the future.');
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await widget.api.send(
        teamId: widget.teamId,
        opponentTeamId: opponent.id,
        matchDate: when,
        atHome: _atHome,
        matchType: _type,
        venue: _venue.text.trim(),
        message: _message.text.trim(),
        competitionId: _competitionId,
      );
      if (!mounted) return;
      setState(() {
        _opponent = null;
        _date = null;
        _venue.clear();
        _message.clear();
      });
      widget.onSent(opponent.school);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = switch (e.code) {
            'INVITATION_EXISTS' => 'These teams already have an open invitation for that time.',
            'OPPONENT_HAS_NO_COACH' => 'That team has no coach on Sportstures yet. Invite their school first.',
            'MATCH_IN_PAST' => 'The match must be in the future.',
            _ => e.fieldErrors.isNotEmpty ? e.fieldErrors.values.first : e.message,
          });
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  static const _label = TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.ink);
  static const _muted = TextStyle(fontSize: 12, color: AppColors.muted, height: 1.45);

  InputDecoration _input(String label) =>
      InputDecoration(labelText: label, border: const OutlineInputBorder(), isDense: true);

  @override
  Widget build(BuildContext context) {
    final opponent = _opponent;
    return SectionCard(
      title: 'Invite a school to a match',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('1. Who do you want to play?', style: _label),
            const SizedBox(height: 8),
            if (opponent != null)
              Row(
                children: [
                  PhotoBadge(url: opponent.logoUrl, fallback: opponent.school, size: 40, square: true),
                  const SizedBox(width: 12),
                  Expanded(child: Text('${opponent.school}\n${opponent.name}', style: _muted.copyWith(color: AppColors.ink))),
                  TextButton(onPressed: () => setState(() => _opponent = null), child: const Text('Change')),
                ],
              )
            else
              ..._finder(),
            const SizedBox(height: 18),
            const Text('2. When and where?', style: _label),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.event, size: 16),
                  label: Text(_date == null ? 'Choose date' : formatShortDate(_date!)),
                ),
                OutlinedButton.icon(
                  onPressed: _pickTime,
                  icon: const Icon(Icons.schedule, size: 16),
                  label: Text(_time.format(context)),
                ),
                ChoiceChip(label: const Text('We host'), selected: _atHome, onSelected: (_) => setState(() => _atHome = true)),
                ChoiceChip(label: const Text('They host'), selected: !_atHome, onSelected: (_) => setState(() => _atHome = false)),
              ],
            ),
            const SizedBox(height: 12),
            TextField(controller: _venue, maxLength: 255, decoration: _input('Venue (optional)').copyWith(counterText: '')),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: _input('Match type'),
              items: [for (final e in _matchTypes.entries) DropdownMenuItem(value: e.key, child: Text(e.value))],
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
            const SizedBox(height: 12),
            TextField(controller: _message, maxLength: 500, maxLines: 2, decoration: _input('Message to their coach (optional)')),
            if (_error != null) _Banner(_error!, error: true),
            const SizedBox(height: 8),
            SiteButton(
              label: _sending ? 'SENDING…' : 'SEND MATCH INVITATION',
              icon: Icons.send,
              small: true,
              onPressed: _sending ? null : _send,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _finder() {
    final results = _results;
    return [
      TextField(
        controller: _search,
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => _find(),
        decoration: _input('Search by school or team name')
            .copyWith(suffixIcon: IconButton(tooltip: 'Search', icon: const Icon(Icons.search), onPressed: _find)),
      ),
      const SizedBox(height: 8),
      if (_searching)
        const Padding(padding: EdgeInsets.all(12), child: Center(child: CircularProgressIndicator()))
      else if (results != null && results.isEmpty)
        const Text('No teams found for your sport.', style: _muted)
      else if (results != null)
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 260),
          child: SingleChildScrollView(
            child: DividedColumn(
              children: [
                for (final t in results)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        PhotoBadge(url: t.logoUrl, fallback: t.school, size: 32, square: true),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(t.school, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink)),
                              Text(t.hasCoach ? t.name : '${t.name} · no coach on Sportstures yet', style: _muted),
                            ],
                          ),
                        ),
                        if (t.hasCoach)
                          TextButton(onPressed: () => setState(() => _opponent = t), child: const Text('Choose'))
                        else
                          TextButton(
                            onPressed: () => openSiteRoute(context, SiteRoutes.coachInvite),
                            child: const Text('Invite coach'),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
    ];
  }
}

class _DeclineDialog extends StatefulWidget {
  const _DeclineDialog();

  @override
  State<_DeclineDialog> createState() => _DeclineDialogState();
}

class _DeclineDialogState extends State<_DeclineDialog> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Decline this match?'),
        content: SizedBox(
          width: 360,
          child: TextField(
            controller: _reason,
            maxLength: 500,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Reason (optional)', border: OutlineInputBorder()),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Keep it')),
          FilledButton(onPressed: () => Navigator.pop(context, _reason.text.trim()), child: const Text('Decline match')),
        ],
      );
}

class _Banner extends StatelessWidget {
  const _Banner(this.message, {this.error = false});

  final String message;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final color = error ? Colors.red.shade700 : AppColors.green;
    return Container(
      margin: const EdgeInsets.only(top: 10, bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
      child: Text(message, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
    );
  }
}
