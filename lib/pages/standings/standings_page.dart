import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../data/sports_data.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';
import '../../widgets/site/ai_summary_cards.dart';
import '../../widgets/site/filter_controls.dart';
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

class StandingsPage extends StatefulWidget {
  const StandingsPage({super.key});

  @override
  State<StandingsPage> createState() => _StandingsPageState();
}

class _StandingsPageState extends State<StandingsPage> {
  // Draft filter values; they only take effect when FILTER is pressed.
  var _sport = Sport.football;
  String? _ageGroup = 'U/19';
  String? _region;
  String? _league;
  var _season = SportsData.instance.seasons.first;

  late StandingsQuery _applied = _draft;
  var _view = StandingsView.leagueTable;

  StandingsQuery get _draft =>
      (sport: _sport, ageGroup: _ageGroup, region: _region, league: _league, season: _season);

  void _apply() => setState(() => _applied = _draft);

  void _reset() {
    setState(() {
      _sport = Sport.football;
      _ageGroup = 'U/19';
      _region = null;
      _league = null;
      _season = SportsData.instance.seasons.first;
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
    final results = SportsData.instance.results.where((result) {
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
            options: SportsData.ageGroups,
            labelOf: (age) => age,
            allLabel: 'All Age Groups',
            onChanged: (value) => setState(() => _ageGroup = value),
          ),
        ),
        FilterField(
          label: 'Region',
          child: FilterDropdown<String>(
            value: _region,
            options: SportsData.regions,
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
            options: SportsData.leagues,
            labelOf: (league) => league,
            allLabel: 'All Competitions',
            onChanged: (value) => setState(() => _league = value),
          ),
        ),
        FilterField(
          label: 'Season',
          child: FilterDropdown<int>(
            value: _season,
            options: SportsData.instance.seasons,
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
            card('Home record · $title', LeagueTable(standings: standingsFor(side: TeamSide.home), showZones: false)),
            const SizedBox(height: 16),
            card('Away record · $title', LeagueTable(standings: standingsFor(side: TeamSide.away), showZones: false)),
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
