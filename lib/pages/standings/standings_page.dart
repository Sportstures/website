import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../data/sports_data.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';
import '../../widgets/site/ai_summary_cards.dart';
import '../../widgets/site/filter_controls.dart';
import '../../widgets/site/match_data_builder.dart';
import '../../widgets/site/page_hero.dart';
import '../../widgets/site/promo_card.dart';
import '../../widgets/site/site_routes.dart';
import '../../widgets/site/site_scaffold.dart';
import '../../widgets/site/ui_kit.dart';
import 'widgets/select_table_card.dart';
import 'widgets/standings_tables.dart';
import 'widgets/top_performers_card.dart';

enum StandingsView {
  leagueTable('League table', Icons.emoji_events_outlined),
  homeAway('Home / Away', Icons.home_outlined),
  formGuide('Form guide', Icons.show_chart),
  scoring('Goals', Icons.sports_score),
  cleanSheets('Clean sheets', Icons.shield_outlined);

  const StandingsView(this.label, this.icon);

  final String label;
  final IconData icon;
}

typedef StandingsQuery = ({Sport sport, String? ageGroup, String? region, String? league, int season});

class StandingsPage extends StatelessWidget {
  const StandingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MatchDataBuilder(
      currentRoute: SiteRoutes.standings,
      title: 'Standings',
      subtitle: 'See how schools are performing in their regions and sports this season.',
      builder: (context, data) => _StandingsView(data: data),
    );
  }
}

class _StandingsView extends StatefulWidget {
  const _StandingsView({required this.data});

  final SportsData data;

  @override
  State<_StandingsView> createState() => _StandingsViewState();
}

class _StandingsViewState extends State<_StandingsView> {
  // Draft filter values; they only take effect when FILTER is pressed.
  late var _sport = _defaultSport;
  late String? _ageGroup = _defaultAgeGroup;
  String? _region;
  String? _league;
  late var _season = widget.data.seasonOptions.first;

  /// Football for the sample data. For real data, the sport with the most results, so the
  /// page opens on a table that has something in it.
  Sport get _defaultSport {
    if (widget.data.isSample || widget.data.results.isEmpty) return Sport.football;
    final counts = <Sport, int>{};
    for (final r in widget.data.results) {
      counts.update(r.fixture.sport, (n) => n + 1, ifAbsent: () => 1);
    }
    return (counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).first.key;
  }

  /// U/19 when the opening sport has U/19 results (the sample data always does), otherwise every
  /// age group, so the page does not open on an empty table.
  String? get _defaultAgeGroup {
    if (!widget.data.ageGroupOptions.contains('U/19')) return null;
    if (widget.data.isSample) return 'U/19';
    final sport = _defaultSport;
    return widget.data.results.any((r) => r.fixture.sport == sport && r.fixture.ageGroup == 'U/19') ? 'U/19' : null;
  }

  /// Every (sport, age group) that has results, most results first. Null for the sample data,
  /// whose card keeps its built-in suggestions.
  ({List<(Sport, String)> popular, List<(Sport, String)> all})? get _tables {
    if (widget.data.isSample) return null;
    final counts = <(Sport, String), int>{};
    for (final r in widget.data.results) {
      counts.update((r.fixture.sport, r.fixture.ageGroup), (n) => n + 1, ifAbsent: () => 1);
    }
    final all = (counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).map((e) => e.key).toList();
    return (popular: all.take(5).toList(), all: all);
  }

  late StandingsQuery _applied = _draft;
  var _view = StandingsView.leagueTable;

  StandingsQuery get _draft =>
      (sport: _sport, ageGroup: _ageGroup, region: _region, league: _league, season: _season);

  void _apply() => setState(() => _applied = _draft);

  void _reset() {
    setState(() {
      _sport = _defaultSport;
      _ageGroup = _defaultAgeGroup;
      _region = null;
      _league = null;
      _season = widget.data.seasonOptions.first;
      _applied = _draft;
    });
  }

  void _selectTable(Sport sport, String ageGroup) {
    setState(() {
      _sport = sport;
      _ageGroup = ageGroup;
      _applied = _draft;
    });
  }

  @override
  Widget build(BuildContext context) {
    final query = _applied;
    final results = widget.data.results.where((result) {
      final fixture = result.fixture;
      return fixture.sport == query.sport &&
          (query.ageGroup == null || fixture.ageGroup == query.ageGroup) &&
          (query.league == null || fixture.league == query.league) &&
          (query.region == null ||
              fixture.home.region == query.region ||
              fixture.away.region == query.region) &&
          fixture.startsAt.year == query.season;
    }).toList();

    // With a region filter, only that region's schools appear in the table.
    List<SchoolStanding> standingsFor({TeamSide? side}) {
      final table = SportsData.standingsFor(results, side: side);
      return query.region == null ? table : table.where((s) => s.school.region == query.region).toList();
    }

    final standings = standingsFor();

    return SiteScaffold(
      currentRoute: SiteRoutes.standings,
      children: [
        const PageHero(
          title: 'Standings',
          breadcrumb: 'Standings',
          subtitle: 'See how schools are performing in their regions and sports this season.',
        ),
        ContentWidth(
          child: Padding(
            padding: const EdgeInsets.only(top: 28, bottom: 56),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildFilters(),
                const SizedBox(height: 20),
                TwoColumnLayout(
                  main: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ChoiceTabs<StandingsView>(
                        options: StandingsView.values,
                        selected: _view,
                        onSelect: (view) => setState(() => _view = view),
                        labelOf: (view) =>
                            view == StandingsView.scoring ? query.sport.scoreLabel : view.label,
                        iconOf: (view) => view.icon,
                      ),
                      const SizedBox(height: 16),
                      _buildView(query, results, standings, standingsFor),
                    ],
                  ),
                  sidebar: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AiStandingsReadCard(standings: standings, sport: query.sport),
                      const SizedBox(height: 16),
                      SelectTableCard(
                        sport: query.sport,
                        ageGroup: query.ageGroup,
                        onSelect: _selectTable,
                        popular: _tables?.popular,
                        all: _tables?.all,
                      ),
                      const SizedBox(height: 16),
                      TopPerformersCard(sport: query.sport, standings: standings),
                      const SizedBox(height: 16),
                      const PromoCard(eyebrow: 'Join the champions'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return FilterPanel(
      onApply: _apply,
      onReset: _reset,
      fields: [
        FilterField(
          label: 'Sport',
          child: FilterDropdown<Sport>(
            value: _sport,
            options: Sport.values,
            labelOf: (sport) => sport.label,
            onChanged: (value) => setState(() => _sport = value ?? _sport),
          ),
        ),
        FilterField(
          label: 'Age Group',
          child: FilterDropdown<String>(
            value: _ageGroup,
            options: widget.data.ageGroupOptions,
            labelOf: (age) => age,
            allLabel: 'All Age Groups',
            onChanged: (value) => setState(() => _ageGroup = value),
          ),
        ),
        FilterField(
          label: 'Region',
          child: FilterDropdown<String>(
            value: _region,
            options: widget.data.regionOptions,
            labelOf: (region) => region,
            allLabel: 'All Regions',
            onChanged: (value) => setState(() => _region = value),
          ),
        ),
        FilterField(
          label: 'Competition',
          flex: 3,
          child: FilterDropdown<String>(
            value: _league,
            options: widget.data.leagueOptions,
            labelOf: (league) => league,
            allLabel: 'All Competitions',
            onChanged: (value) => setState(() => _league = value),
          ),
        ),
        FilterField(
          label: 'Season',
          child: FilterDropdown<int>(
            value: _season,
            options: widget.data.seasonOptions,
            labelOf: (year) => '$year Season',
            onChanged: (value) => setState(() => _season = value ?? _season),
          ),
        ),
      ],
    );
  }

  Widget _buildView(
    StandingsQuery query,
    List<MatchResult> results,
    List<SchoolStanding> standings,
    List<SchoolStanding> Function({TeamSide? side}) standingsFor,
  ) {
    final title = '${query.sport.label} ${query.ageGroup ?? 'all ages'} - '
        '${query.league ?? 'all competitions'}';
    final updated = results.isEmpty
        ? null
        : Text(
            'Updated: ${formatShortDate(results.first.fixture.startsAt)}',
            style: const TextStyle(fontSize: 11, color: AppColors.muted),
          );

    if (standings.isEmpty) {
      return SectionCard(
        title: title,
        child: const EmptyState('No results for this table yet. Try another competition or season.'),
      );
    }

    SectionCard card(String cardTitle, Widget table) => SectionCard(
          title: cardTitle,
          trailing: updated,
          padding: EdgeInsets.zero,
          child: table,
        );

    return switch (_view) {
      StandingsView.leagueTable => card(title, LeagueTable(standings: standings)),
      StandingsView.homeAway => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            card('Home record · $title', LeagueTable(standings: standingsFor(side: TeamSide.home))),
            const SizedBox(height: 16),
            card('Away record · $title', LeagueTable(standings: standingsFor(side: TeamSide.away))),
          ],
        ),
      StandingsView.formGuide => card(title, FormGuideTable(standings: standings)),
      StandingsView.scoring => card(
          title,
          ScoringTable(standings: standings, scoreLabel: query.sport.scoreLabel),
        ),
      StandingsView.cleanSheets => card(title, CleanSheetsTable(standings: standings)),
    };
  }
}
