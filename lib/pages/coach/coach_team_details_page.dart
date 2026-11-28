import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../api/api_exception.dart';
import '../../api/session.dart';
import '../../api/team_details_api.dart';
import '../../theme/app_colors.dart';
import '../../widgets/site/page_hero.dart';
import '../../widgets/site/site_routes.dart';
import '../../widgets/site/site_scaffold.dart';
import '../../widgets/site/ui_kit.dart';
import 'coach_guard.dart';

/// The coach edits their team's details and their school's location.
class CoachTeamDetailsPage extends StatelessWidget {
  const CoachTeamDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CoachGuard(
      currentRoute: SiteRoutes.coachTeamDetails,
      title: 'Team Details',
      subtitle: 'How your team and school appear to others.',
      builder: (context, coach) => _Details(teamId: coach.team?['id'] as int?),
    );
  }
}

class _Details extends StatefulWidget {
  const _Details({required this.teamId});

  final int? teamId;

  @override
  State<_Details> createState() => _DetailsState();
}

class _DetailsState extends State<_Details> {
  late final TeamDetailsApi _api = TeamDetailsApi(SessionScope.read(context).api);

  TeamDetails? _team;
  String? _error;

  /// Rebuilds the forms from the server's answer after a save.
  var _version = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final id = widget.teamId;
    if (id == null) {
      setState(() => _error = 'Your coach account does not have a team yet.');
      return;
    }
    setState(() => _error = null);
    try {
      final team = await _api.team(id);
      if (mounted) {
        setState(() {
          _team = team;
          _version++;
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _saved(String message) async {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final team = _team;
    return SiteScaffold(
      currentRoute: SiteRoutes.coachTeamDetails,
      children: [
        const PageHero(title: 'Team Details', breadcrumb: 'Team Details', subtitle: 'How your team and school appear to others.'),
        ContentWidth(
          child: Padding(
            padding: const EdgeInsets.only(top: 28, bottom: 56),
            child: team == null
                ? (_error == null
                    ? const Center(child: CircularProgressIndicator())
                    : SectionCard(
                        title: "Couldn't load your team",
                        child: Column(children: [
                          EmptyState(_error!),
                          SiteButton(label: 'TRY AGAIN', small: true, onPressed: _load),
                          const SizedBox(height: 12),
                        ]),
                      ))
                : TwoColumnLayout(
                    main: _TeamForm(key: ValueKey('team-$_version'), api: _api, team: team, onSaved: () => _saved('Team details saved.')),
                    sidebar: team.schoolId == null
                        ? const SectionCard(title: 'School location', child: EmptyState('Your team has no school.'))
                        : _SchoolForm(key: ValueKey('school-$_version'), api: _api, team: team, onSaved: () => _saved('School location saved.')),
                  ),
          ),
        ),
      ],
    );
  }
}

InputDecoration _input(String label) =>
    InputDecoration(labelText: label, border: const OutlineInputBorder(), isDense: true, counterText: '');

Widget _errorText(String? error) => error == null
    ? const SizedBox.shrink()
    : Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Text(error, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.red.shade700)),
      );

/// An empty box clears the field.
String? _orNull(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();

class _TeamForm extends StatefulWidget {
  const _TeamForm({super.key, required this.api, required this.team, required this.onSaved});

  final TeamDetailsApi api;
  final TeamDetails team;
  final VoidCallback onSaved;

  @override
  State<_TeamForm> createState() => _TeamFormState();
}

class _TeamFormState extends State<_TeamForm> {
  late final _name = TextEditingController(text: widget.team.name);
  late final _description = TextEditingController(text: widget.team.description ?? '');
  late final _location = TextEditingController(text: widget.team.location ?? '');
  late final _founded = TextEditingController(text: widget.team.foundedYear?.toString() ?? '');
  late String? _gender = widget.team.genderCategory;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_name, _description, _location, _founded]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final t = widget.team;
    final name = _name.text.trim();
    final founded = _orNull(_founded) == null ? null : int.tryParse(_founded.text.trim());
    if (name.isEmpty) {
      setState(() => _error = 'The team needs a name.');
      return;
    }
    if (founded != null && (founded < 1800 || founded > 2100)) {
      setState(() => _error = 'The year must be between 1800 and 2100.');
      return;
    }
    final changes = <String, Object?>{
      if (name != t.name) 'name': name,
      if (_gender != t.genderCategory) 'genderCategory': _gender,
      if (_orNull(_description) != t.description) 'description': _orNull(_description),
      if (_orNull(_location) != t.location) 'location': _orNull(_location),
      if (founded != t.foundedYear) 'foundedYear': founded,
    };
    if (changes.isEmpty) {
      setState(() => _error = 'Nothing has changed.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.api.updateTeam(t.id, changes);
      if (mounted) widget.onSaved();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.fieldErrors.isNotEmpty ? e.fieldErrors.values.first : e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => SectionCard(
        title: 'Your team',
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(key: const ValueKey('Team name'), controller: _name, maxLength: 255, decoration: _input('Team name')),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  for (final (value, label) in [('boys', 'Boys'), ('girls', 'Girls'), ('mixed', 'Mixed')])
                    ChoiceChip(label: Text(label), selected: _gender == value, onSelected: (on) => setState(() => _gender = on ? value : null)),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                  key: const ValueKey('About the team'),
                  controller: _description,
                  minLines: 3,
                  maxLines: 6,
                  maxLength: 2000,
                  decoration: _input('About the team')),
              const SizedBox(height: 12),
              TextField(
                  key: const ValueKey('Home ground'),
                  controller: _location,
                  maxLength: 255,
                  decoration: _input('Home ground')),
              const SizedBox(height: 12),
              SizedBox(
                width: 160,
                child: TextField(
                  key: const ValueKey('Year founded'),
                  controller: _founded,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
                  decoration: _input('Year founded'),
                ),
              ),
              _errorText(_error),
              const SizedBox(height: 14),
              SiteButton(label: _saving ? 'SAVING…' : 'SAVE TEAM', small: true, onPressed: _saving ? null : _save),
            ],
          ),
        ),
      );
}

class _SchoolForm extends StatefulWidget {
  const _SchoolForm({super.key, required this.api, required this.team, required this.onSaved});

  final TeamDetailsApi api;
  final TeamDetails team;
  final VoidCallback onSaved;

  @override
  State<_SchoolForm> createState() => _SchoolFormState();
}

class _SchoolFormState extends State<_SchoolForm> {
  late final _town = TextEditingController(text: widget.team.town ?? '');
  late String? _province = provinces.contains(widget.team.province) ? widget.team.province : null;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _town.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final t = widget.team;
    final changes = <String, Object?>{
      if (_province != t.province) 'province': _province,
      if (_orNull(_town) != t.town) 'town': _orNull(_town),
    };
    if (changes.isEmpty) {
      setState(() => _error = 'Nothing has changed.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.api.updateSchool(t.schoolId!, changes);
      if (mounted) widget.onSaved();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.fieldErrors.isNotEmpty ? e.fieldErrors.values.first : e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => SectionCard(
        title: 'School location',
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Where ${widget.team.schoolName} is. It affects which province your results count towards.',
                  style: const TextStyle(fontSize: 12, color: AppColors.muted, height: 1.5)),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                initialValue: _province,
                isExpanded: true,
                decoration: _input('Province'),
                items: [
                  const DropdownMenuItem<String?>(value: null, child: Text('Not set')),
                  for (final p in provinces) DropdownMenuItem<String?>(value: p, child: Text(p)),
                ],
                onChanged: (v) => setState(() => _province = v),
              ),
              const SizedBox(height: 12),
              TextField(key: const ValueKey('Town'), controller: _town, maxLength: 100, decoration: _input('Town')),
              _errorText(_error),
              const SizedBox(height: 14),
              SiteButton(label: _saving ? 'SAVING…' : 'SAVE LOCATION', small: true, onPressed: _saving ? null : _save),
            ],
          ),
        ),
      );
}
