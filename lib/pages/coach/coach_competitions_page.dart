import 'package:flutter/material.dart';

import '../../api/api_exception.dart';
import '../../api/competitions_api.dart';
import '../../api/match_invitations_api.dart';
import '../../api/session.dart';
import '../../theme/app_colors.dart';
import '../../widgets/site/page_hero.dart';
import '../../widgets/site/site_routes.dart';
import '../../widgets/site/site_scaffold.dart';
import '../../widgets/site/ui_kit.dart';
import '../competitions/competition_page.dart';
import 'coach_guard.dart';
import 'table_rules_editor.dart';

/// The competitions a coach organises: set one up and choose how its table is decided.
class CoachCompetitionsPage extends StatelessWidget {
  const CoachCompetitionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CoachGuard(
      currentRoute: SiteRoutes.coachCompetitions,
      title: 'My Competitions',
      subtitle: 'Set up a competition and choose how its table is decided.',
      builder: (context, coach) => _Competitions(teamId: coach.team?['id'] as int?),
    );
  }
}

class _Competitions extends StatefulWidget {
  const _Competitions({required this.teamId});

  final int? teamId;

  @override
  State<_Competitions> createState() => _CompetitionsState();
}

class _CompetitionsState extends State<_Competitions> {
  late final CompetitionsApi _api = CompetitionsApi(SessionScope.read(context).api);

  List<Competition>? _mine;
  String? _loadError;
  String? _notice;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final all = await _api.list();
      if (!mounted) return;
      setState(() {
        _mine = [for (final c in all) if (c.canEdit) c];
        _loadError = null;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _loadError = e.message);
    }
  }

  Future<void> _editRules(Competition c) async {
    final saved = await showDialog<bool>(context: context, builder: (_) => _RulesDialog(api: _api, competition: c));
    if (saved != true || !mounted) return;
    setState(() => _notice = 'Rules saved for ${c.name}. Its table uses them now.');
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final mine = _mine;
    return SiteScaffold(
      currentRoute: SiteRoutes.coachCompetitions,
      children: [
        const PageHero(title: 'My Competitions', breadcrumb: 'My Competitions', subtitle: 'Set up a competition and choose how its table is decided.'),
        ContentWidth(
          child: Padding(
            padding: const EdgeInsets.only(top: 28, bottom: 56),
            child: TwoColumnLayout(
              main: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_notice != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(_notice!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.green)),
                    ),
                  SectionCard(
                    title: 'Competitions you organise',
                    child: _loadError != null
                        ? Column(children: [
                            EmptyState(_loadError!),
                            const SizedBox(height: 8),
                            SiteButton(label: 'TRY AGAIN', small: true, onPressed: _load),
                            const SizedBox(height: 12),
                          ])
                        : mine == null
                            ? const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
                            : mine.isEmpty
                                ? const EmptyState('You have not set up a competition yet.')
                                : DividedColumn(children: [for (final c in mine) _row(c)]),
                  ),
                ],
              ),
              sidebar: _CreateForm(
                api: _api,
                teamId: widget.teamId,
                onCreated: (name) {
                  setState(() => _notice = '$name is set up. Add matches to it when you invite schools.');
                  _load();
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _row(Competition c) {
    const detail = TextStyle(fontSize: 12, color: AppColors.muted, height: 1.45);
    return Padding(
      key: ValueKey('competition-${c.id}'),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(c.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink))),
              StatusPill(c.rules.custom ? 'Own rules' : 'Standard rules', color: c.rules.custom ? AppColors.orange : AppColors.green),
            ],
          ),
          Text(
            [?c.sport, ?c.season, c.teams == 1 ? '1 team' : '${c.teams} teams'].join(' · '),
            style: detail,
          ),
          Text(c.rules.summary, style: detail),
          const SizedBox(height: 4),
          Wrap(
            spacing: 4,
            children: [
              TextButton(onPressed: () => _editRules(c), child: const Text('Edit rules')),
              TextButton(onPressed: () => openSiteRoute(context, CompetitionPage.routeFor(c.id)), child: const Text('View table')),
            ],
          ),
        ],
      ),
    );
  }
}

class _RulesDialog extends StatefulWidget {
  const _RulesDialog({required this.api, required this.competition});

  final CompetitionsApi api;
  final Competition competition;

  @override
  State<_RulesDialog> createState() => _RulesDialogState();
}

class _RulesDialogState extends State<_RulesDialog> {
  late TableRules _rules = widget.competition.rules;
  bool _saving = false;
  String? _error;

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.api.updateRules(widget.competition.id, _rules);
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.code == 'FORBIDDEN' ? 'Only the coach who created this competition can change it.' : e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text('Table rules: ${widget.competition.name}'),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Changing the rules re-orders the table, including matches already played.',
                    style: TextStyle(fontSize: 12, color: AppColors.muted)),
                const SizedBox(height: 12),
                TableRulesEditor(rules: _rules, onChanged: (r) => setState(() => _rules = r)),
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
          FilledButton(onPressed: _saving ? null : _save, child: Text(_saving ? 'Saving…' : 'Save rules')),
        ],
      );
}

class _CreateForm extends StatefulWidget {
  const _CreateForm({required this.api, required this.teamId, required this.onCreated});

  final CompetitionsApi api;
  final int? teamId;
  final void Function(String name) onCreated;

  @override
  State<_CreateForm> createState() => _CreateFormState();
}

class _CreateFormState extends State<_CreateForm> {
  final _name = TextEditingController();
  late final _season = TextEditingController(text: '${DateTime.now().year}');
  TableRules _rules = const TableRules();

  /// The coach's team's sport, which a new competition is for.
  int? _sportId;
  String? _sport;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSport();
  }

  Future<void> _loadSport() async {
    final teamId = widget.teamId;
    if (teamId == null) return;
    try {
      final team = await MatchInvitationsApi(SessionScope.read(context).api).team(teamId);
      if (mounted) {
        setState(() {
          _sportId = team.sportId;
          _sport = team.sport;
        });
      }
    } on ApiException {
      // The competition can still be created without a sport.
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _season.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Give the competition a name.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.api.create(name: name, sportId: _sportId, season: _season.text.trim(), rules: _rules);
      if (!mounted) return;
      setState(() {
        _saving = false;
        _name.clear();
        _rules = const TableRules();
      });
      widget.onCreated(name);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.code == 'COMPETITION_EXISTS'
            ? 'A competition with that name already exists.'
            : (e.fieldErrors.isNotEmpty ? e.fieldErrors.values.first : e.message);
      });
    }
  }

  InputDecoration _input(String label) =>
      InputDecoration(labelText: label, border: const OutlineInputBorder(), isDense: true, counterText: '');

  @override
  Widget build(BuildContext context) => SectionCard(
        title: 'Set up a competition',
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(controller: _name, maxLength: 255, decoration: _input('Competition name')),
              const SizedBox(height: 12),
              TextField(controller: _season, maxLength: 20, decoration: _input('Season')),
              if (_sport != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('Sport: $_sport', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                ),
              const SizedBox(height: 14),
              TableRulesEditor(rules: _rules, onChanged: (r) => setState(() => _rules = r)),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(_error!, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.red.shade700)),
                ),
              const SizedBox(height: 12),
              SiteButton(label: _saving ? 'ONE MOMENT…' : 'CREATE COMPETITION', small: true, onPressed: _saving ? null : _create),
            ],
          ),
        ),
      );
}
