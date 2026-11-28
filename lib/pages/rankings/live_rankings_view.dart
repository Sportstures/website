import 'package:flutter/material.dart';

import '../../api/api_client.dart';
import '../../api/rankings_api.dart';
import '../../data/models.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';
import '../../widgets/site/filter_controls.dart';
import '../../widgets/site/page_hero.dart';
import '../../widgets/site/site_routes.dart';
import '../../widgets/site/site_scaffold.dart';
import '../../widgets/site/ui_kit.dart';
import '../coach/photo_badge.dart';

typedef _Query = ({RankingType type, int? sportId, String? ageGroup, String? province, int? season});

/// The Rankings page on the backend's figures.
class LiveRankingsView extends StatefulWidget {
  const LiveRankingsView({super.key, required this.api, this.initialType = RankingType.schools});

  final ApiClient api;
  final RankingType initialType;

  @override
  State<LiveRankingsView> createState() => _LiveRankingsViewState();
}

class _LiveRankingsViewState extends State<LiveRankingsView> {
  static const _top = 10;

  /// The most rows the server gives at once.
  static const _all = 100;

  late final RankingsApi _api = RankingsApi(widget.api);

  // Draft filter values; they take effect when FILTER is pressed.
  late var _type = widget.initialType;
  int? _sportId;
  String? _ageGroup;
  String? _province;
  int? _season;

  late _Query _applied = _draft;
  var _showAll = false;

  RankingResult? _result;
  RankingOverview? _overview;
  RankingFilters _filters = const RankingFilters();
  bool _failed = false;

  /// Only the answer to the newest request is shown.
  var _request = 0;

  _Query get _draft => (type: _type, sportId: _sportId, ageGroup: _ageGroup, province: _province, season: _season);

  @override
  void initState() {
    super.initState();
    _load();
    _loadSeason();
  }

  Future<void> _load() async {
    final request = ++_request;
    final q = _applied;
    setState(() {
      _result = null;
      _failed = false;
    });
    try {
      final result = await _api.rankings(
        type: q.type.name,
        sportId: q.sportId,
        ageGroup: q.ageGroup,
        province: q.province,
        season: q.season,
        limit: _showAll ? _all : _top,
      );
      if (mounted && request == _request) setState(() => _result = result);
    } catch (_) {
      if (mounted && request == _request) setState(() => _failed = true);
    }
  }

  /// The side cards and filter choices, which depend only on the season.
  Future<void> _loadSeason() async {
    final season = _applied.season;
    try {
      final overview = await _api.overview(season: season);
      final filters = await _api.filters(season: season);
      if (!mounted || season != _applied.season) return;
      setState(() {
        _overview = overview;
        _filters = filters;
      });
    } catch (_) {
      // The table still works; the cards stay empty until a retry.
    }
  }

  void _use({bool showAll = false}) {
    final seasonChanged = _applied.season != _season;
    _applied = _draft;
    _showAll = showAll;
    _load();
    if (seasonChanged || _overview == null) _loadSeason();
  }

  void _reset() {
    _type = RankingType.schools;
    _sportId = null;
    _ageGroup = null;
    _province = null;
    _season = null;
    _use();
  }

  @override
  Widget build(BuildContext context) {
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
                _filterPanel(),
                const SizedBox(height: 20),
                TwoColumnLayout(
                  main: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ChoiceTabs<RankingType>(
                        options: RankingType.values,
                        selected: _applied.type,
                        onSelect: (type) {
                          _type = type;
                          _use();
                        },
                        labelOf: (type) => '${type.label} ranking',
                        iconOf: (type) => type.icon,
                      ),
                      const SizedBox(height: 16),
                      _table(),
                      if (_overview != null && _overview!.regionLeaders.isNotEmpty) ...[
                        const SizedBox(height: 28),
                        _regions(_overview!.regionLeaders),
                      ],
                    ],
                  ),
                  sidebar: _sidebar(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _filterPanel() {
    // A chosen value stays selectable even if the new season's list no longer has it.
    final sports = [for (final s in _filters.sports) s.id];
    if (_sportId != null && !sports.contains(_sportId)) sports.add(_sportId!);
    List<T> including<T>(List<T> list, T? chosen) => [...list, if (chosen != null && !list.contains(chosen)) chosen];
    final seasons = including(_filters.seasons.isEmpty ? [DateTime.now().year] : _filters.seasons, _season);

    return FilterPanel(
      onApply: _use,
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
          child: FilterDropdown<int>(
            value: _sportId,
            options: sports,
            labelOf: (id) => _filters.sports.where((s) => s.id == id).map((s) => s.name).firstOrNull ?? 'Sport',
            allLabel: 'All Sports',
            onChanged: (value) => setState(() => _sportId = value),
          ),
        ),
        FilterField(
          label: 'Age Group',
          child: FilterDropdown<String>(
            value: _ageGroup,
            options: including(_filters.ageGroups, _ageGroup),
            labelOf: (age) => age,
            allLabel: 'All Age Groups',
            onChanged: (value) => setState(() => _ageGroup = value),
          ),
        ),
        FilterField(
          label: 'Region',
          flex: 3,
          child: FilterDropdown<String>(
            value: _province,
            options: including(_filters.provinces, _province),
            labelOf: (province) => province,
            allLabel: 'All Regions',
            onChanged: (value) => setState(() => _province = value),
          ),
        ),
        FilterField(
          label: 'Season',
          child: FilterDropdown<int>(
            value: _season ?? seasons.first,
            options: seasons,
            labelOf: (year) => '$year Season',
            onChanged: (value) => setState(() => _season = value),
          ),
        ),
      ],
    );
  }

  Widget _table() {
    final type = _applied.type;
    final result = _result;
    final (title, description) = switch (type) {
      RankingType.schools => ('Top schools overall', 'Overall performance across all sports and age groups.'),
      RankingType.teams => ('Top teams', 'Each school team ranked by sport and age group.'),
      RankingType.athletes => ('Top athletes', 'Individual athletes ranked by their season performance.'),
      RankingType.regions => ('Top regions', 'Combined performance of every school in each region.'),
    };

    return SectionCard(
      title: title,
      trailing: result?.updatedAt == null
          ? null
          : Text('Updated: ${formatShortDate(result!.updatedAt!)}', style: const TextStyle(fontSize: 11, color: AppColors.muted)),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Text(description, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          ),
          if (_failed) ...[
            const EmptyState("Rankings couldn't be loaded."),
            Center(child: SiteButton(label: 'TRY AGAIN', small: true, onPressed: _use)),
            const SizedBox(height: 16),
          ] else if (result == null)
            const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
          else if (result.rows.isEmpty)
            EmptyState(type == RankingType.athletes
                ? 'Athlete rankings appear once coaches name scorers and lineups.'
                : 'No rankings match your filters yet.')
          else ...[
            _rows(type, result.rows),
            if (result.total > _top)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Center(
                  child: SiteButton(
                    label: _showAll ? 'SHOW TOP 10' : 'VIEW FULL RANKINGS',
                    variant: SiteButtonVariant.outline,
                    small: true,
                    onPressed: () {
                      _showAll = !_showAll;
                      _load();
                    },
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _rows(RankingType type, List<RankingRow> rows) {
    final middle = switch (type) {
      RankingType.regions => 'Schools',
      RankingType.schools => 'Sports played',
      _ => 'Played',
    };
    return SiteTable(
      minWidth: 600,
      columns: [
        const SiteTableColumn('#', width: 36, alignment: Alignment.centerLeft),
        SiteTableColumn(
          switch (type) {
            RankingType.schools => 'School',
            RankingType.teams => 'Team',
            RankingType.athletes => 'Athlete',
            RankingType.regions => 'Region',
          },
          alignment: Alignment.centerLeft,
        ),
        if (type != RankingType.regions)
          const SiteTableColumn('Region', width: 120, alignment: Alignment.centerLeft, hideOnNarrow: true),
        SiteTableColumn(middle, width: 90, hideOnNarrow: true),
        const SiteTableColumn('Points', width: 70),
        const SiteTableColumn('Trend', width: 60),
      ],
      rows: [
        for (final row in rows)
          [
            Text('${row.position}', style: tableStrongStyle),
            Row(
              children: [
                PhotoBadge(url: row.logoUrl, fallback: row.name, size: 28, square: true),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(row.name, style: tableStrongStyle, overflow: TextOverflow.ellipsis),
                      if (row.detail != null)
                        Text(row.detail!, style: const TextStyle(fontSize: 11, color: AppColors.muted), overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
            if (type != RankingType.regions) Text(row.province ?? '–', style: tableCellStyle, overflow: TextOverflow.ellipsis),
            Text(
              '${switch (type) {
                RankingType.regions => row.schoolsRanked ?? 0,
                RankingType.schools => row.sportsPlayed ?? 0,
                _ => row.played,
              }}',
              style: tableCellStyle,
            ),
            Text(formatThousands(row.points), style: tableStrongStyle),
            row.trend == null
                ? const Text('NEW', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.orange))
                : TrendIndicator(row.trend!),
          ],
      ],
    );
  }

  Widget _regions(List<RegionLeader> leaders) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('TOP SCHOOLS BY REGION', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.ink)),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            const gap = 12.0;
            final columns = constraints.maxWidth >= 640 ? 4 : 2;
            final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final leader in leaders)
                  Container(
                    width: width,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(leader.province.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.muted)),
                        const SizedBox(height: 10),
                        PhotoBadge(fallback: leader.name, size: 40, square: true),
                        const SizedBox(height: 8),
                        Text(leader.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.ink)),
                        const SizedBox(height: 2),
                        Text('${formatThousands(leader.points)} pts',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.orange)),
                        const SizedBox(height: 10),
                        SiteButton(
                          label: 'VIEW TOP 10',
                          variant: SiteButtonVariant.outline,
                          small: true,
                          expand: true,
                          onPressed: () {
                            _type = RankingType.schools;
                            _province = leader.province;
                            _use();
                          },
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _sidebar() {
    final overview = _overview;
    if (overview == null) return const SizedBox.shrink();
    Widget line(Widget leading, Widget trailing) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(children: [Expanded(child: leading), const SizedBox(width: 8), trailing]),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionCard(
          title: 'Ranking breakdown',
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            children: [
              for (final w in overview.weights)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(children: [
                        Expanded(child: Text(w.label, style: tableCellStyle)),
                        Text('${w.percent}%', style: tableStrongStyle),
                      ]),
                      const SizedBox(height: 5),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(value: w.percent / 100, minHeight: 5, color: AppColors.orange, backgroundColor: AppColors.border),
                      ),
                      const SizedBox(height: 3),
                      Text(w.description, style: const TextStyle(fontSize: 11, color: AppColors.muted, height: 1.4)),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: 'Top performing sports',
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
          child: overview.topSports.isEmpty
              ? const EmptyState('No results yet.')
              : Column(
                  children: [
                    for (final s in overview.topSports)
                      line(
                        Text([s.label, ?s.school].join(' · '), style: tableCellStyle),
                        Text('${formatThousands(s.points)} pts', style: tableStrongStyle),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: 'Top rise this season',
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
          child: overview.risers.isEmpty
              ? const EmptyState('No schools have climbed the rankings this week.')
              : Column(
                  children: [for (final r in overview.risers) line(Text(r.name, style: tableCellStyle), TrendIndicator(r.trend))],
                ),
        ),
      ],
    );
  }
}
