import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../api/api_exception.dart';
import '../../api/coach_api.dart';
import '../../api/session.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';
import '../../widgets/site/page_hero.dart';
import '../../widgets/site/site_routes.dart';
import '../../widgets/site/site_scaffold.dart';
import '../../widgets/site/ui_kit.dart';
import 'coach_guard.dart';
import 'coach_photos_card.dart';

/// The coach's squad: approve join requests, set numbers and positions, add and remove players.
class CoachTeamPage extends StatelessWidget {
  const CoachTeamPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CoachGuard(
      currentRoute: SiteRoutes.coachTeam,
      title: 'My Squad',
      subtitle: 'Manage who plays for your team.',
      builder: (context, coach) => _Squad(coach: coach),
    );
  }
}

class _Squad extends StatefulWidget {
  const _Squad({required this.coach});

  final AppUser coach;

  @override
  State<_Squad> createState() => _SquadState();
}

class _SquadState extends State<_Squad> {
  late final CoachApi _api = CoachApi(SessionScope.read(context).api);

  int? get _teamId => widget.coach.team?['id'] as int?;

  List<RosterMember> _squad = const [];
  List<RosterMember> _requests = const [];
  List<Candidate> _candidates = const [];
  final _search = TextEditingController();
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final teamId = _teamId;
    if (teamId == null) {
      setState(() {
        _loading = false;
        _error = 'Your coach account does not have a team yet.';
      });
      return;
    }
    try {
      final results = await Future.wait([
        _api.roster(teamId),
        _api.roster(teamId, pending: true),
        _api.candidates(teamId, query: _search.text),
      ]);
      if (!mounted) return;
      setState(() {
        _squad = results[0] as List<RosterMember>;
        _requests = results[1] as List<RosterMember>;
        _candidates = results[2] as List<Candidate>;
        _loading = false;
        _error = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    }
  }

  /// Runs a change, tells the coach how it went, and refreshes the lists.
  Future<void> _run(Future<void> Function() action, String done) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(done)));
    } on ApiException catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(_friendly(e))));
    }
    await _reload();
  }

  static String _friendly(ApiException e) => switch (e.code) {
        'JERSEY_TAKEN' => 'That jersey number is already taken by another player.',
        'SCHOOL_MISMATCH' => "That learner isn't at your school.",
        'ALREADY_MEMBER' => 'That player is already on your team.',
        _ => e.message,
      };

  Future<void> _approve(RosterMember m, int? jersey) =>
      _run(() => _api.addPlayer(_teamId!, m.userId, jerseyNumber: jersey), '${m.name} is now on the team.');

  Future<void> _reject(RosterMember m) async {
    if (!await _confirm('Decline ${m.name}?', "They won't be added to your team.", 'Decline')) return;
    await _run(() => _api.removePlayer(_teamId!, m.userId), "${m.name}'s request was declined.");
  }

  Future<void> _remove(RosterMember m) async {
    if (!await _confirm('Remove ${m.name}?', 'They will be taken off your squad.', 'Remove')) return;
    await _run(() => _api.removePlayer(_teamId!, m.userId), '${m.name} was removed.');
  }

  Future<void> _edit(RosterMember m) async {
    final result = await showDialog<_PlayerDetails>(
      context: context,
      builder: (_) => _PlayerDialog(title: 'Edit ${m.name}', action: 'Save', jersey: m.jerseyNumber, position: m.position),
    );
    if (result == null) return;
    await _run(
      () => _api.updatePlayer(_teamId!, m.userId, jerseyNumber: result.jersey, clearJersey: result.jersey == null, position: result.position),
      'Saved.',
    );
  }

  Future<void> _add(Candidate c) async {
    final result = await showDialog<_PlayerDetails>(
      context: context,
      builder: (_) => _PlayerDialog(title: 'Add ${c.name}', action: 'Add to team', jersey: c.declaredJersey),
    );
    if (result == null) return;
    await _run(() => _api.addPlayer(_teamId!, c.userId, jerseyNumber: result.jersey, position: result.position), '${c.name} was added.');
  }

  Future<bool> _confirm(String title, String message, String action) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(action)),
        ],
      ),
    );
    return yes ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return SiteScaffold(
      currentRoute: SiteRoutes.coachTeam,
      children: [
        const PageHero(title: 'My Squad', breadcrumb: 'My Squad', subtitle: 'Manage who plays for your team.'),
        ContentWidth(
          child: Padding(
            padding: const EdgeInsets.only(top: 28, bottom: 56),
            child: _loading
                ? const Padding(padding: EdgeInsets.symmetric(vertical: 48), child: Center(child: CircularProgressIndicator()))
                : _error != null && _squad.isEmpty && _requests.isEmpty
                    ? SectionCard(
                        title: "Couldn't load your squad",
                        child: Column(
                          children: [
                            EmptyState(_error!),
                            const SizedBox(height: 12),
                            SiteButton(label: 'TRY AGAIN', small: true, onPressed: () {
                              setState(() => _loading = true);
                              _reload();
                            }),
                            const SizedBox(height: 12),
                          ],
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          CoachPhotosCard(
                            teamId: _teamId,
                            teamName: '${widget.coach.team?['name'] ?? 'Team'}',
                            coachName: [widget.coach.firstName, widget.coach.lastName].whereType<String>().join(' '),
                          ),
                          const SizedBox(height: 16),
                          if (_requests.isNotEmpty) ...[
                            _Requests(requests: _requests, onApprove: _approve, onReject: _reject),
                            const SizedBox(height: 16),
                          ],
                          _SquadTable(squad: _squad, onEdit: _edit, onRemove: _remove),
                          const SizedBox(height: 16),
                          _AddPlayers(controller: _search, candidates: _candidates, onSearch: _reload, onAdd: _add),
                        ],
                      ),
          ),
        ),
      ],
    );
  }
}

class _PlayerDetails {
  const _PlayerDetails(this.jersey, this.position);

  final int? jersey;
  final String position;
}

class _PlayerDialog extends StatefulWidget {
  const _PlayerDialog({required this.title, required this.action, this.jersey, this.position});

  final String title;
  final String action;
  final int? jersey;
  final String? position;

  @override
  State<_PlayerDialog> createState() => _PlayerDialogState();
}

class _PlayerDialogState extends State<_PlayerDialog> {
  late final _jersey = TextEditingController(text: widget.jersey?.toString() ?? '');
  late final _position = TextEditingController(text: widget.position ?? '');

  @override
  void dispose() {
    _jersey.dispose();
    _position.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 340,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _jersey,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)],
              decoration: const InputDecoration(labelText: 'Jersey number (optional)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _position,
              maxLength: 50,
              decoration: const InputDecoration(labelText: 'Position (optional)', hintText: 'e.g. Guard'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.pop(context, _PlayerDetails(int.tryParse(_jersey.text.trim()), _position.text.trim())),
          child: Text(widget.action),
        ),
      ],
    );
  }
}

class _Requests extends StatelessWidget {
  const _Requests({required this.requests, required this.onApprove, required this.onReject});

  final List<RosterMember> requests;
  final Future<void> Function(RosterMember, int?) onApprove;
  final Future<void> Function(RosterMember) onReject;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Join requests',
      trailing: CountLabel(count: requests.length, noun: 'request'),
      child: DividedColumn(
        children: [for (final m in requests) _RequestRow(key: ValueKey(m.userId), member: m, onApprove: onApprove, onReject: onReject)],
      ),
    );
  }
}

class _RequestRow extends StatefulWidget {
  const _RequestRow({super.key, required this.member, required this.onApprove, required this.onReject});

  final RosterMember member;
  final Future<void> Function(RosterMember, int?) onApprove;
  final Future<void> Function(RosterMember) onReject;

  @override
  State<_RequestRow> createState() => _RequestRowState();
}

class _RequestRowState extends State<_RequestRow> {
  late final _jersey = TextEditingController(text: widget.member.jerseyNumber?.toString() ?? '');

  @override
  void dispose() {
    _jersey.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.member;
    final asked = m.requestedAt == null ? null : 'Asked ${formatShortDate(m.requestedAt!)}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 240,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink)),
                Text([m.gradeLabel, ?asked].where((s) => s.isNotEmpty).join(' · '), style: const TextStyle(fontSize: 12, color: AppColors.muted)),
              ],
            ),
          ),
          SizedBox(
            width: 110,
            child: TextField(
              controller: _jersey,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)],
              decoration: const InputDecoration(labelText: 'Jersey #', isDense: true),
            ),
          ),
          SiteButton(label: 'APPROVE', small: true, onPressed: () => widget.onApprove(m, int.tryParse(_jersey.text.trim()))),
          SiteButton(label: 'DECLINE', small: true, variant: SiteButtonVariant.outline, onPressed: () => widget.onReject(m)),
        ],
      ),
    );
  }
}

class _SquadTable extends StatelessWidget {
  const _SquadTable({required this.squad, required this.onEdit, required this.onRemove});

  final List<RosterMember> squad;
  final Future<void> Function(RosterMember) onEdit;
  final Future<void> Function(RosterMember) onRemove;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Squad',
      trailing: CountLabel(count: squad.length, noun: 'player'),
      padding: EdgeInsets.zero,
      child: squad.isEmpty
          ? const Padding(padding: EdgeInsets.all(16), child: EmptyState('No players yet. Add learners from your school below.'))
          : SiteTable(
              minWidth: 640,
              columns: const [
                SiteTableColumn('#', width: 56),
                SiteTableColumn('Player', alignment: Alignment.centerLeft),
                SiteTableColumn('Grade', width: 130),
                SiteTableColumn('Position', width: 130),
                SiteTableColumn('', width: 150),
              ],
              rows: [
                for (final m in squad)
                  [
                    Text(m.jerseyNumber?.toString() ?? '–', style: tableStrongStyle),
                    Text(m.name, style: tableStrongStyle),
                    Text(m.gradeLabel.isEmpty ? '–' : m.gradeLabel, style: tableCellStyle),
                    Text(m.position ?? '–', style: tableCellStyle),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(tooltip: 'Edit ${m.name}', icon: const Icon(Icons.edit_outlined, size: 18), onPressed: () => onEdit(m)),
                        IconButton(tooltip: 'Remove ${m.name}', icon: const Icon(Icons.person_remove_outlined, size: 18), onPressed: () => onRemove(m)),
                      ],
                    ),
                  ],
              ],
            ),
    );
  }
}

class _AddPlayers extends StatelessWidget {
  const _AddPlayers({required this.controller, required this.candidates, required this.onSearch, required this.onAdd});

  final TextEditingController controller;
  final List<Candidate> candidates;
  final Future<void> Function() onSearch;
  final Future<void> Function(Candidate) onAdd;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Add players from your school',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    onSubmitted: (_) => onSearch(),
                    decoration: const InputDecoration(hintText: 'Search by name', isDense: true, prefixIcon: Icon(Icons.search, size: 18)),
                  ),
                ),
                const SizedBox(width: 12),
                SiteButton(label: 'SEARCH', small: true, onPressed: onSearch),
              ],
            ),
            const SizedBox(height: 8),
            if (candidates.isEmpty)
              const EmptyState('No learners from your school are available to add.')
            else
              DividedColumn(
                children: [
                  for (final c in candidates)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(c.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink)),
                                Text(
                                  [c.gradeLabel, if (c.declaredSport != null) 'Plays ${c.declaredSport}'].where((s) => s.isNotEmpty).join(' · '),
                                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                                ),
                              ],
                            ),
                          ),
                          SiteButton(label: 'ADD', small: true, onPressed: () => onAdd(c)),
                        ],
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
