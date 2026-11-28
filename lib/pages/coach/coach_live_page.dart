import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../api/api_exception.dart';
import '../../api/coach_api.dart';
import '../../api/live_scoring_api.dart';
import '../../api/session.dart';
import '../../theme/app_colors.dart';
import '../../widgets/site/page_hero.dart';
import '../../widgets/site/site_routes.dart';
import '../../widgets/site/site_scaffold.dart';
import '../../widgets/site/ui_kit.dart';
import 'coach_guard.dart';

/// Score a match as it happens. Opened as `/coach/live?fixture=<id>`, so a page refresh keeps the match.
class CoachLivePage extends StatelessWidget {
  const CoachLivePage({super.key});

  static String routeFor(int fixtureId) => '${SiteRoutes.coachLive}?fixture=$fixtureId';

  @override
  Widget build(BuildContext context) {
    final name = ModalRoute.of(context)?.settings.name;
    final id = int.tryParse(Uri.tryParse(name ?? '')?.queryParameters['fixture'] ?? '');
    return CoachGuard(
      currentRoute: SiteRoutes.coachLive,
      title: 'Live Scoring',
      subtitle: 'Score your match as it happens.',
      builder: (context, coach) => _Live(fixtureId: id, teamId: coach.team?['id'] as int?),
    );
  }
}

/// How often the page asks for the other coach's changes.
const livePollInterval = Duration(seconds: 15);

class _Live extends StatefulWidget {
  const _Live({required this.fixtureId, required this.teamId});

  final int? fixtureId;
  final int? teamId;

  @override
  State<_Live> createState() => _LiveState();
}

class _LiveState extends State<_Live> {
  late final LiveScoringApi _api = LiveScoringApi(SessionScope.read(context).api);

  LiveMatch? _match;
  String? _loadError;
  String? _error;
  bool _busy = false;
  Timer? _poll;

  /// Counts the changes this page made, so a slower poll cannot put older data back.
  int _version = 0;

  @override
  void initState() {
    super.initState();
    _refresh();
    _poll = Timer.periodic(livePollInterval, (_) {
      // Nothing changes by itself before kick-off ends or after full time, except the other coach starting it.
      if (_match?.fixture.status != 'finished' && !_busy) _refresh();
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    final id = widget.fixtureId;
    if (id == null) {
      setState(() => _loadError = 'Choose a match from My Matches.');
      return;
    }
    final version = _version;
    try {
      final match = await _api.match(id);
      if (!mounted || version != _version) return;
      setState(() {
        _match = match;
        _loadError = null;
      });
    } on ApiException catch (e) {
      // A failed poll keeps what is on screen; the next one tries again.
      if (mounted && _match == null) setState(() => _loadError = e.message);
    }
  }

  Future<bool> _run(Future<LiveMatch> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    _version++;
    try {
      final match = await action();
      if (!mounted) return false;
      setState(() {
        _match = match;
        _busy = false;
      });
      return true;
    } on ApiException catch (e) {
      if (!mounted) return false;
      setState(() {
        _busy = false;
        _error = switch (e.code) {
          'TOO_EARLY' => 'You can start the match from 60 minutes before kick-off.',
          'MATCH_NOT_LIVE' || 'MATCH_NOT_STARTED' => 'The match is not live. The page has been updated.',
          'ALREADY_CONFIRMED' => 'That one is already confirmed.',
          'GOAL_NOT_PENDING' || 'GOAL_NOT_FOUND' => 'That score has changed. The page has been updated.',
          'NOT_ON_TEAM' => 'That player is no longer in the squad.',
          'FORBIDDEN' => 'Only the coaches of these two teams can do that.',
          _ => e.fieldErrors.isNotEmpty ? e.fieldErrors.values.first : e.message,
        };
      });
      await _refresh();
      return false;
    }
  }

  Future<void> _dispute(LiveGoal goal) async {
    final reason = await showDialog<String>(context: context, builder: (_) => const _DisputeDialog());
    if (reason == null || !mounted) return;
    await _run(() => _api.dispute(widget.fixtureId!, goal.id, reason: reason));
  }

  Future<void> _finish() async {
    final m = _match!;
    final waiting = m.homePending + m.awayPending;
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Full time?'),
        content: SizedBox(
          width: 360,
          child: Text(waiting == 0
              ? 'This saves the result. Scores cannot be added afterwards.'
              : 'This saves the result. Scores still waiting for confirmation ($waiting) will be counted. Disputed ones will not.'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep playing')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('End match')),
        ],
      ),
    );
    if (yes == true && mounted) await _run(() => _api.finish(widget.fixtureId!));
  }

  @override
  Widget build(BuildContext context) {
    final match = _match;
    return SiteScaffold(
      currentRoute: SiteRoutes.coachLive,
      children: [
        const PageHero(
          title: 'Live Scoring',
          breadcrumb: 'Live Scoring',
          subtitle: 'The other coach confirms each score you add, and you confirm theirs.',
        ),
        ContentWidth(
          child: Padding(
            padding: const EdgeInsets.only(top: 28, bottom: 56),
            child: match == null
                ? (_loadError == null
                    ? const Padding(padding: EdgeInsets.all(48), child: Center(child: CircularProgressIndicator()))
                    : SectionCard(
                        title: "Couldn't open the match",
                        child: Column(children: [
                          EmptyState(_loadError!),
                          const SizedBox(height: 8),
                          SiteButton(label: 'MY MATCHES', small: true, onPressed: () => openSiteRoute(context, SiteRoutes.coachMatches)),
                          const SizedBox(height: 12),
                        ]),
                      ))
                : _content(match),
          ),
        ),
      ],
    );
  }

  Widget _content(LiveMatch m) {
    final status = m.fixture.status;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Scoreboard(match: m),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(_error!, style: TextStyle(fontSize: 13, color: Colors.red.shade700, fontWeight: FontWeight.w700)),
          ),
        const SizedBox(height: 16),
        if (status == 'scheduled')
          SectionCard(
            title: 'Kick-off',
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Start the match when play begins. Either coach can do this.',
                      style: TextStyle(fontSize: 13, color: AppColors.muted)),
                  const SizedBox(height: 12),
                  SiteButton(
                    label: _busy ? 'STARTING…' : 'START MATCH',
                    icon: Icons.play_arrow,
                    small: true,
                    onPressed: _busy ? null : () => _run(() => _api.start(widget.fixtureId!)),
                  ),
                ],
              ),
            ),
          )
        else if (status == 'postponed' || status == 'cancelled')
          SectionCard(title: 'Not being played', child: EmptyState('This match is $status.'))
        else ...[
          if (status == 'live' && widget.teamId != null) ...[
            _AddScore(
              match: m,
              teamId: widget.teamId!,
              busy: _busy,
              onAdd: (teamId, points, minute, playerId) => _run(
                  () => _api.addGoal(widget.fixtureId!, teamId: teamId, points: points, minute: minute, playerId: playerId)),
            ),
            const SizedBox(height: 16),
          ],
          SectionCard(
            title: 'Scores',
            child: m.goals.isEmpty
                ? const EmptyState('No scores yet.')
                : DividedColumn(children: [for (final g in m.goals) _goal(g)]),
          ),
          if (status == 'live') ...[
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: SiteButton(label: 'FULL TIME', icon: Icons.flag, variant: SiteButtonVariant.outline, onPressed: _busy ? null : _finish),
            ),
          ],
        ],
      ],
    );
  }

  Widget _goal(LiveGoal g) {
    final (label, color) = switch (g.status) {
      'confirmed' => ('Confirmed', AppColors.green),
      'disputed' => ('Disputed', Colors.red.shade700),
      _ => ('Waiting', AppColors.orange),
    };
    const detail = TextStyle(fontSize: 12, color: AppColors.muted, height: 1.45);
    return Padding(
      key: ValueKey('goal-${g.id}'),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 48,
            child: Text(g.minute == null ? '–' : "${g.minute}'",
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.ink)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  [g.teamName, if (g.points > 1) '${g.points} points', ?g.playerName].join(' · '),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink),
                ),
                if (g.addedBy != null) Text('Added by ${g.addedBy}', style: detail),
                if (g.status == 'disputed' && g.disputeReason != null) Text('Disputed: "${g.disputeReason}"', style: detail),
                if (g.autoConfirmed) const Text('Counted at full time', style: detail),
                if (g.canConfirm || g.canDispute || g.canDelete)
                  Wrap(
                    spacing: 4,
                    children: [
                      if (g.canConfirm)
                        TextButton(onPressed: _busy ? null : () => _run(() => _api.confirm(widget.fixtureId!, g.id)), child: const Text('Confirm')),
                      if (g.canDispute) TextButton(onPressed: _busy ? null : () => _dispute(g), child: const Text('Dispute')),
                      if (g.canDelete)
                        TextButton(onPressed: _busy ? null : () => _run(() => _api.delete(widget.fixtureId!, g.id)), child: const Text('Remove')),
                    ],
                  ),
              ],
            ),
          ),
          StatusPill(label, color: color),
        ],
      ),
    );
  }
}

class _Scoreboard extends StatelessWidget {
  const _Scoreboard({required this.match});

  final LiveMatch match;

  @override
  Widget build(BuildContext context) {
    final f = match.fixture;
    final state = switch (f.status) {
      'live' => 'LIVE',
      'finished' => 'FULL TIME',
      'scheduled' => 'NOT STARTED',
      _ => f.status.toUpperCase(),
    };
    Widget team(String name, int pending) => Expanded(
          child: Column(
            children: [
              Text(name, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
              if (pending > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('$pending waiting', style: const TextStyle(color: AppColors.orange, fontSize: 12, fontWeight: FontWeight.w800)),
                ),
            ],
          ),
        );
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(color: AppColors.green, borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          Text(state, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
          const SizedBox(height: 12),
          Row(
            children: [
              team(f.homeName, match.homePending),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('${match.homeScore} - ${match.awayScore}',
                    key: const ValueKey('score'),
                    style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900)),
              ),
              team(f.awayName, match.awayPending),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddScore extends StatefulWidget {
  const _AddScore({required this.match, required this.teamId, required this.busy, required this.onAdd});

  final LiveMatch match;
  final int teamId;
  final bool busy;
  final Future<bool> Function(int teamId, int points, int? minute, int? playerId) onAdd;

  @override
  State<_AddScore> createState() => _AddScoreState();
}

class _AddScoreState extends State<_AddScore> {
  final _minute = TextEditingController();
  late int _team = widget.teamId;
  int _points = 1;
  int? _player;
  List<RosterMember> _squad = const [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSquad();
  }

  Future<void> _loadSquad() async {
    try {
      final squad = await CoachApi(SessionScope.read(context).api).roster(widget.teamId);
      if (mounted) setState(() => _squad = squad);
    } on ApiException {
      // The scorer is optional, so scoring works without the list.
    }
  }

  @override
  void dispose() {
    _minute.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final text = _minute.text.trim();
    final minute = int.tryParse(text);
    if (text.isNotEmpty && (minute == null || minute > 200)) {
      setState(() => _error = 'The minute must be between 0 and 200.');
      return;
    }
    setState(() => _error = null);
    // Only my own players can be named: the page has my squad, not theirs.
    final added = await widget.onAdd(_team, _points, minute, _team == widget.teamId ? _player : null);
    if (added && mounted) {
      setState(() {
        _minute.clear();
        _player = null;
      });
    }
  }

  InputDecoration _input(String label) => InputDecoration(labelText: label, border: const OutlineInputBorder(), isDense: true);

  @override
  Widget build(BuildContext context) {
    final f = widget.match.fixture;
    return SectionCard(
      title: 'Add a score',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (id, name) in [(f.homeTeamId, f.homeName), (f.awayTeamId, f.awayName)])
                  ChoiceChip(label: Text('$name scored'), selected: _team == id, onSelected: (_) => setState(() => _team = id)),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: 110,
                  child: TextField(
                    controller: _minute,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: _input('Minute'),
                  ),
                ),
                SizedBox(
                  width: 110,
                  child: DropdownButtonFormField<int>(
                    initialValue: _points,
                    decoration: _input('Points'),
                    items: [for (var p = 1; p <= 10; p++) DropdownMenuItem(value: p, child: Text('$p'))],
                    onChanged: (v) => setState(() => _points = v ?? 1),
                  ),
                ),
                if (_team == widget.teamId && _squad.isNotEmpty)
                  SizedBox(
                    width: 240,
                    child: DropdownButtonFormField<int?>(
                      key: ValueKey('scorer-${_player ?? 'none'}'),
                      initialValue: _player,
                      isExpanded: true,
                      decoration: _input('Scorer (optional)'),
                      items: [
                        const DropdownMenuItem<int?>(value: null, child: Text('Not named')),
                        for (final p in _squad)
                          DropdownMenuItem<int?>(value: p.userId, child: Text(p.name, overflow: TextOverflow.ellipsis)),
                      ],
                      onChanged: (v) => setState(() => _player = v),
                    ),
                  ),
              ],
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_error!, style: TextStyle(fontSize: 12, color: Colors.red.shade700, fontWeight: FontWeight.w600)),
              ),
            const SizedBox(height: 12),
            SiteButton(label: widget.busy ? 'ONE MOMENT…' : 'ADD SCORE', icon: Icons.add, small: true, onPressed: widget.busy ? null : _add),
          ],
        ),
      ),
    );
  }
}

class _DisputeDialog extends StatefulWidget {
  const _DisputeDialog();

  @override
  State<_DisputeDialog> createState() => _DisputeDialogState();
}

class _DisputeDialogState extends State<_DisputeDialog> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Dispute this score?'),
        content: SizedBox(
          width: 360,
          child: TextField(
            controller: _reason,
            maxLength: 500,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Why? (optional)', border: OutlineInputBorder()),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          FilledButton(onPressed: () => Navigator.pop(context, _reason.text.trim()), child: const Text('Dispute score')),
        ],
      );
}
