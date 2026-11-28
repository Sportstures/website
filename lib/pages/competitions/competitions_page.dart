import 'package:flutter/material.dart';

import '../../api/api_client.dart';
import '../../api/api_exception.dart';
import '../../api/competitions_api.dart';
import '../../api/session.dart';
import '../../theme/app_colors.dart';
import '../../widgets/site/filter_controls.dart';
import '../../widgets/site/page_hero.dart';
import '../../widgets/site/site_routes.dart';
import '../../widgets/site/site_scaffold.dart';
import '../../widgets/site/ui_kit.dart';
import 'competition_page.dart';

enum CompetitionTab {
  all('All', Icons.emoji_events_outlined, null),
  ongoing('Ongoing', Icons.play_circle_outline, 'ongoing'),
  upcoming('Upcoming', Icons.event_outlined, 'upcoming'),
  completed('Completed', Icons.flag_outlined, 'completed');

  const CompetitionTab(this.label, this.icon, this.status);

  final String label;
  final IconData icon;

  /// What the backend calls it; null means every status.
  final String? status;
}

/// Every competition, each leading to its table. Public.
class CompetitionsPage extends StatelessWidget {
  const CompetitionsPage({super.key});

  @override
  Widget build(BuildContext context) => _Competitions(api: SessionScope.read(context).api);
}

class _Competitions extends StatefulWidget {
  const _Competitions({required this.api});

  final ApiClient api;

  @override
  State<_Competitions> createState() => _CompetitionsState();
}

class _CompetitionsState extends State<_Competitions> {
  List<Competition>? _all;
  String? _error;

  final _search = TextEditingController();
  String? _sport;
  String? _region;
  String _query = '';
  String? _appliedSport;
  String? _appliedRegion;
  var _tab = CompetitionTab.all;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// The whole list is small, so it is fetched once and filtered here.
  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final all = await CompetitionsApi(widget.api).list(auth: false);
      if (mounted) setState(() => _all = all);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  void _apply() => setState(() {
        _query = _search.text.trim().toLowerCase();
        _appliedSport = _sport;
        _appliedRegion = _region;
      });

  void _reset() {
    _search.clear();
    _sport = null;
    _region = null;
    _tab = CompetitionTab.all;
    _apply();
  }

  static List<String> _distinct(Iterable<String?> values) => {for (final v in values) ?v}.toList()..sort();

  @override
  Widget build(BuildContext context) {
    final all = _all;
    final matching = [
      for (final c in all ?? const <Competition>[])
        if ((_query.isEmpty || c.name.toLowerCase().contains(_query)) &&
            (_appliedSport == null || c.sport == _appliedSport) &&
            (_appliedRegion == null || c.region == _appliedRegion))
          c,
    ];
    final shown = [for (final c in matching) if (_tab.status == null || c.status == _tab.status) c];

    return SiteScaffold(
      currentRoute: SiteRoutes.competitions,
      children: [
        const PageHero(title: 'Competitions', breadcrumb: 'Competitions', subtitle: 'Leagues and cups on Sportstures, with their tables.'),
        ContentWidth(
          child: Padding(
            padding: const EdgeInsets.only(top: 28, bottom: 56),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilterPanel(
                  onApply: _apply,
                  onReset: _reset,
                  fields: [
                    FilterField(
                      label: 'Search competitions',
                      flex: 3,
                      wide: true,
                      child: FilterSearchField(controller: _search, hint: 'Search by name...', onSubmitted: (_) => _apply()),
                    ),
                    FilterField(
                      label: 'Sport',
                      child: FilterDropdown<String>(
                        value: _sport,
                        options: _distinct((all ?? const <Competition>[]).map((c) => c.sport)),
                        labelOf: (s) => s,
                        allLabel: 'All Sports',
                        onChanged: (v) => setState(() => _sport = v),
                      ),
                    ),
                    FilterField(
                      label: 'Region',
                      child: FilterDropdown<String>(
                        value: _region,
                        options: _distinct((all ?? const <Competition>[]).map((c) => c.region)),
                        labelOf: (r) => r,
                        allLabel: 'All Regions',
                        onChanged: (v) => setState(() => _region = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ChoiceTabs<CompetitionTab>(
                  options: CompetitionTab.values,
                  selected: _tab,
                  onSelect: (tab) => setState(() => _tab = tab),
                  labelOf: (tab) {
                    final n = tab.status == null ? matching.length : matching.where((c) => c.status == tab.status).length;
                    return all == null ? tab.label : '${tab.label} ($n)';
                  },
                  iconOf: (tab) => tab.icon,
                ),
                const SizedBox(height: 16),
                if (_error != null)
                  SectionCard(
                    title: "Couldn't load competitions",
                    child: Column(children: [
                      EmptyState(_error!),
                      SiteButton(label: 'TRY AGAIN', small: true, onPressed: _load),
                      const SizedBox(height: 12),
                    ]),
                  )
                else if (all == null)
                  const Padding(padding: EdgeInsets.all(48), child: Center(child: CircularProgressIndicator()))
                else if (shown.isEmpty)
                  SectionCard(title: 'Competitions', child: EmptyState(all.isEmpty ? 'No competitions yet.' : 'No competitions match your filters.'))
                else
                  LayoutBuilder(
                    builder: (context, constraints) {
                      const gap = 12.0;
                      final columns = constraints.maxWidth >= 900 ? 3 : (constraints.maxWidth >= 580 ? 2 : 1);
                      final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
                      return Wrap(
                        spacing: gap,
                        runSpacing: gap,
                        children: [for (final c in shown) SizedBox(width: width, child: _card(c))],
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _card(Competition c) {
    const muted = TextStyle(fontSize: 12, color: AppColors.muted, height: 1.45);
    final (label, color) = switch (c.status) {
      'ongoing' => ('Ongoing', AppColors.green),
      'upcoming' => ('Upcoming', AppColors.orange),
      _ => ('Completed', AppColors.muted),
    };
    return Container(
      key: ValueKey('competition-${c.id}'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatusPill(label, color: color),
          const SizedBox(height: 10),
          // Two lines for every name keeps the cards the same height.
          SizedBox(
            height: 40,
            child: Text(c.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink, height: 1.35)),
          ),
          Text([?c.sport, ?c.ageGroup, ?c.region].join(' · '), maxLines: 1, overflow: TextOverflow.ellipsis, style: muted),
          Text(
            [
              c.teams == 1 ? '1 team' : '${c.teams} teams',
              if (c.totalRounds > 0) 'Round ${c.roundsPlayed} of ${c.totalRounds}',
            ].join(' · '),
            style: muted,
          ),
          Text(
            c.leader == null ? 'No results yet' : '${c.status == 'completed' ? 'Champion' : 'Leader'}: ${c.leader}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: muted.copyWith(fontWeight: FontWeight.w700, color: AppColors.green),
          ),
          const SizedBox(height: 12),
          SiteButton(
            label: 'VIEW TABLE',
            variant: SiteButtonVariant.outline,
            small: true,
            expand: true,
            onPressed: () => openSiteRoute(context, CompetitionPage.routeFor(c.id)),
          ),
        ],
      ),
    );
  }
}
