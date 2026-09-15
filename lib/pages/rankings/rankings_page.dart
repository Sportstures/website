import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../data/sports_data.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';
import '../../widgets/site/filter_controls.dart';
import '../../widgets/site/match_rows.dart';
import '../../widgets/site/page_hero.dart';
import '../../widgets/site/site_routes.dart';
import '../../widgets/site/site_scaffold.dart';
import '../../widgets/site/ui_kit.dart';
import 'widgets/ranking_sidebar_cards.dart';
import 'widgets/top_by_region.dart';

typedef RankingsQuery = ({RankingType type, Sport? sport, String? ageGroup, String? region, int season});

class RankingsPage extends StatefulWidget {
  const RankingsPage({super.key});

  @override
  State<RankingsPage> createState() => _RankingsPageState();
}

class _RankingsPageState extends State<RankingsPage> {
  static const _collapsedRows = 10;

  // Draft filter values; they only take effect when FILTER is pressed.
  var _type = RankingType.schools;
  Sport? _sport;
  String? _ageGroup;
  String? _region;
  var _season = SportsData.instance.seasons.first;

  late RankingsQuery _applied = _draft;
  var _showAll = false;
  var _readArguments = false;

  RankingsQuery get _draft =>
      (type: _type, sport: _sport, ageGroup: _ageGroup, region: _region, season: _season);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Other pages can open a specific ranking, e.g. regions from the landing page.
    if (_readArguments) return;
    _readArguments = true;
    final requested = ModalRoute.of(context)?.settings.arguments;
    if (requested is RankingType) {
      _type = requested;
      _applied = _draft;
    }
  }

  void _apply() => setState(() {
        _applied = _draft;
        _showAll = false;
      });

  void _reset() {
    setState(() {
      _type = RankingType.schools;
      _sport = null;
      _ageGroup = null;
      _region = null;
      _season = SportsData.instance.seasons.first;
      _applied = _draft;
      _showAll = false;
    });
  }

  void _selectType(RankingType type) => setState(() {
        _type = type;
        _applied = _draft;
        _showAll = false;
      });

  void _selectRegion(String region) => setState(() {
        _type = RankingType.schools;
        _region = region;
        _applied = _draft;
        _showAll = false;
      });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final query = _applied;
    final results = SportsData.instance.results.where((result) {
      final fixture = result.fixture;
      return (query.sport == null || fixture.sport == query.sport) &&
          (query.ageGroup == null || fixture.ageGroup == query.ageGroup) &&
          fixture.startsAt.year == query.season;
    }).toList();

    final schoolRankings = SportsData.rankingsFor(results, RankingType.schools, now: now);
    final ranked = query.type == RankingType.schools
        ? schoolRankings
        : SportsData.rankingsFor(results, query.type, now: now);
    final entries = query.region == null ? ranked : ranked.where((e) => e.region == query.region).toList();

    return SiteScaffold(
      currentRoute: SiteRoutes.rankings,
      children: [
        const PageHero(
          title: 'Rankings',
          breadcrumb: 'Rankings',
          subtitle: 'Discover the top schools, teams and athletes across South Africa.',
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
                      ChoiceTabs<RankingType>(
                        options: RankingType.values,
                        selected: query.type,
                        onSelect: _selectType,
                        labelOf: (type) => '${type.label} ranking',
                        iconOf: (type) => type.icon,
                      ),
                      const SizedBox(height: 16),
                      _buildRankingCard(query, entries, results),
                      const SizedBox(height: 28),
                      TopByRegion(rankings: schoolRankings, onViewRegion: _selectRegion),
                    ],
                  ),
                  sidebar: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const RankingBreakdownCard(),
                      const SizedBox(height: 16),
                      TopSportsCard(pointsBySport: SportsData.pointsBySport(results)),
                      const SizedBox(height: 16),
                      TopRisesCard(rankings: schoolRankings),
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
          label: 'Ranking Type',
          child: FilterDropdown<RankingType>(
            value: _type,
            options: RankingType.values,
            labelOf: (type) => type.label,
            onChanged: (value) => setState(() => _type = value ?? _type),
          ),
        ),
        FilterField(
          label: 'Sport',
          child: FilterDropdown<Sport>(
            value: _sport,
            options: Sport.values,
            labelOf: (sport) => sport.label,
            allLabel: 'All Sports',
            onChanged: (value) => setState(() => _sport = value),
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
          flex: 3,
          child: FilterDropdown<String>(
            value: _region,
            options: SportsData.regions,
            labelOf: (region) => region,
            allLabel: 'All Regions',
            onChanged: (value) => setState(() => _region = value),
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

  Widget _buildRankingCard(RankingsQuery query, List<RankingEntry> entries, List<MatchResult> results) {
    final (title, description) = switch (query.type) {
      RankingType.schools => ('Top schools overall', 'Overall performance across all sports and age groups.'),
      RankingType.teams => ('Top teams', 'Each school team ranked by sport and age group.'),
      RankingType.athletes => ('Top athletes', 'Individual athletes ranked by their season performance.'),
      RankingType.regions => ('Top regions', 'Combined performance of every school in each region.'),
    };
    final shown = _showAll ? entries : entries.take(_collapsedRows).toList();

    return SectionCard(
      title: title,
      trailing: results.isEmpty
          ? null
          : Text(
              'Updated: ${formatShortDate(results.first.fixture.startsAt)}',
              style: const TextStyle(fontSize: 11, color: AppColors.muted),
            ),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Text(description, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          ),
          if (query.type == RankingType.athletes)
            // TODO: rank athletes once the backend records player stats
            const EmptyState('Athlete rankings will appear once schools start recording player stats.')
          else if (entries.isEmpty)
            const EmptyState('No rankings match your filters yet.')
          else ...[
            _buildTable(query.type, shown),
            if (entries.length > _collapsedRows)
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Center(
                  child: SiteButton(
                    label: _showAll ? 'SHOW TOP 10' : 'VIEW FULL RANKINGS',
                    variant: SiteButtonVariant.outline,
                    small: true,
                    onPressed: () => setState(() => _showAll = !_showAll),
                  ),
                ),
              ),
          ],
          const _HowRankingsWork(),
        ],
      ),
    );
  }

  Widget _buildTable(RankingType type, List<RankingEntry> entries) {
    final middleColumns = switch (type) {
      RankingType.regions => const [
          SiteTableColumn('Schools', width: 70),
          SiteTableColumn('Matches', width: 70),
        ],
      RankingType.teams => const [
          SiteTableColumn('Region', width: 120, alignment: Alignment.centerLeft),
          SiteTableColumn('Played', width: 60),
        ],
      _ => const [
          SiteTableColumn('Region', width: 120, alignment: Alignment.centerLeft),
          SiteTableColumn('Sports played', width: 90),
        ],
    };

    return SiteTable(
      minWidth: 600,
      columns: [
        const SiteTableColumn('#', width: 36, alignment: Alignment.centerLeft),
        SiteTableColumn(
          switch (type) {
            RankingType.regions => 'Region',
            RankingType.teams => 'Team',
            _ => 'School',
          },
          alignment: Alignment.centerLeft,
        ),
        ...middleColumns,
        const SiteTableColumn('Points', width: 70),
        const SiteTableColumn('Trend', width: 60),
      ],
      rows: [
        for (final (i, entry) in entries.indexed)
          [
            Text('${i + 1}', style: tableStrongStyle),
            if (entry.school != null)
              SchoolCell(school: entry.school!, subtitle: entry.subtitle)
            else
              Text(entry.title, style: tableStrongStyle),
            ...switch (type) {
              RankingType.regions => [
                  Text('${entry.schools.length}', style: tableCellStyle),
                  Text('${entry.played}', style: tableCellStyle),
                ],
              RankingType.teams => [
                  Text(entry.region, style: tableCellStyle, overflow: TextOverflow.ellipsis),
                  Text('${entry.played}', style: tableCellStyle),
                ],
              _ => [
                  Text(entry.region, style: tableCellStyle, overflow: TextOverflow.ellipsis),
                  Text('${entry.sports.length}', style: tableCellStyle),
                ],
            },
            Text(formatThousands(entry.points), style: tableStrongStyle),
            TrendIndicator(entry.trend),
          ],
      ],
    );
  }
}

class _HowRankingsWork extends StatelessWidget {
  const _HowRankingsWork();

  void _showDetails(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('How rankings work'),
        content: const SizedBox(width: 360, child: RankingWeightsList()),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.emoji_events_outlined, size: 22, color: AppColors.orange),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How rankings work',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.ink),
                ),
                SizedBox(height: 2),
                Text(
                  'Rankings are calculated with a points system based on match results, strength '
                  'of opposition, goals scored and overall consistency.',
                  style: TextStyle(fontSize: 11, color: AppColors.muted, height: 1.4),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _showDetails(context),
            style: TextButton.styleFrom(foregroundColor: AppColors.green),
            child: const Text('Learn more →', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
