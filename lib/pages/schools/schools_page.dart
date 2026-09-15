import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../data/sports_data.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';
import '../../widgets/site/filter_controls.dart';
import '../../widgets/site/page_hero.dart';
import '../../widgets/site/promo_card.dart';
import '../../widgets/site/site_routes.dart';
import '../../widgets/site/site_scaffold.dart';
import '../../widgets/site/ui_kit.dart';
import 'widgets/browse_by_region_card.dart';
import 'widgets/school_card.dart';
import 'widgets/top_schools_card.dart';

enum SchoolsTab {
  all('All schools', Icons.school_outlined),
  featured('Featured schools', Icons.star_outline),
  newlyAdded('Newly added', Icons.fiber_new_outlined);

  const SchoolsTab(this.label, this.icon);

  final String label;
  final IconData icon;
}

enum SchoolSort {
  nameAscending('Name A–Z'),
  nameDescending('Name Z–A'),
  topRanked('Top ranked'),
  newest('Newest');

  const SchoolSort(this.label);

  final String label;
}

typedef SchoolsQuery = ({String search, String? region, String? province, SchoolType? type, Sport? sport});

class SchoolsPage extends StatefulWidget {
  const SchoolsPage({super.key});

  @override
  State<SchoolsPage> createState() => _SchoolsPageState();
}

class _SchoolsPageState extends State<SchoolsPage> {
  static const _pageSize = 11;

  /// Schools that joined within this many days count as newly added.
  static const _newWithinDays = 60;

  // Draft filter values; they only take effect when FILTER is pressed.
  final _search = TextEditingController();
  String? _region;
  String? _province;
  SchoolType? _type;
  Sport? _sport;

  late SchoolsQuery _applied = _draft;
  var _tab = SchoolsTab.all;
  var _sort = SchoolSort.nameAscending;
  var _visibleCount = _pageSize;

  SchoolsQuery get _draft =>
      (search: _search.text.trim(), region: _region, province: _province, type: _type, sport: _sport);

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _apply() => setState(() {
        _applied = _draft;
        _visibleCount = _pageSize;
      });

  void _reset() {
    setState(() {
      _search.clear();
      _region = null;
      _province = null;
      _type = null;
      _sport = null;
      _applied = _draft;
      _visibleCount = _pageSize;
    });
  }

  void _selectRegion(String? region) => setState(() {
        _region = region;
        _applied = _draft;
        _visibleCount = _pageSize;
      });

  bool _matches(School school, SchoolsQuery query) {
    final search = query.search.toLowerCase();
    return (search.isEmpty ||
            school.name.toLowerCase().contains(search) ||
            school.town.toLowerCase().contains(search)) &&
        (query.region == null || school.region == query.region) &&
        (query.province == null || school.province == query.province) &&
        (query.type == null || school.type == query.type) &&
        (query.sport == null || school.sports.contains(query.sport)) &&
        switch (_tab) {
          SchoolsTab.all => true,
          SchoolsTab.featured => school.featured,
          SchoolsTab.newlyAdded => school.joinedDaysAgo <= _newWithinDays,
        };
  }

  @override
  Widget build(BuildContext context) {
    final data = SportsData.instance;
    final rankings = SportsData.rankingsFor(data.results, RankingType.schools, now: DateTime.now());
    final rankOf = {for (final (i, entry) in rankings.indexed) entry.school!: i};

    final schools = SportsData.schools.where((s) => _matches(s, _applied)).toList()
      ..sort((a, b) => switch (_sort) {
            SchoolSort.nameAscending => a.name.compareTo(b.name),
            SchoolSort.nameDescending => b.name.compareTo(a.name),
            SchoolSort.topRanked => (rankOf[a] ?? 999).compareTo(rankOf[b] ?? 999),
            SchoolSort.newest => a.joinedDaysAgo.compareTo(b.joinedDaysAgo),
          });
    final shown = schools.take(_visibleCount).toList();

    return SiteScaffold(
      currentRoute: SiteRoutes.schools,
      children: [
        const PageHero(
          title: 'Schools',
          breadcrumb: 'For Schools',
          subtitle: 'Discover schools, view profiles, sports offered, fixtures, results and achievements.',
        ),
        ContentWidth(
          child: Padding(
            padding: const EdgeInsets.only(top: 28, bottom: 56),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildFilters(),
                const SizedBox(height: 20),
                StatsBand(
                  stats: [
                    (Icons.emoji_events_outlined, formatThousands(SportsData.schools.length), 'Registered Schools'),
                    (Icons.location_on_outlined, '${SportsData.provinces.length}', 'Provinces'),
                    (Icons.sports_outlined, '${Sport.values.length}', 'Sports'),
                    (
                      Icons.groups_outlined,
                      formatThousands(SportsData.schools.fold(0, (sum, s) => sum + s.athletes)),
                      'Student Athletes',
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TwoColumnLayout(
                  main: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ChoiceTabs<SchoolsTab>(
                        options: SchoolsTab.values,
                        selected: _tab,
                        onSelect: (tab) => setState(() {
                          _tab = tab;
                          _visibleCount = _pageSize;
                        }),
                        labelOf: (tab) => tab.label,
                        iconOf: (tab) => tab.icon,
                      ),
                      const SizedBox(height: 16),
                      _buildListHeader(shown.length, schools.length),
                      const SizedBox(height: 12),
                      _buildGrid(shown),
                      if (schools.length > _visibleCount) ...[
                        const SizedBox(height: 16),
                        Center(
                          child: SiteButton(
                            label: 'LOAD MORE SCHOOLS',
                            small: true,
                            onPressed: () => setState(() => _visibleCount += _pageSize),
                          ),
                        ),
                      ],
                    ],
                  ),
                  sidebar: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      BrowseByRegionCard(selectedRegion: _applied.region, onSelect: _selectRegion),
                      const SizedBox(height: 16),
                      TopSchoolsCard(rankings: rankings),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                const _AdminBanner(),
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
          label: 'Search Schools',
          flex: 3,
          wide: true,
          child: FilterSearchField(
            controller: _search,
            hint: 'Search by school name or town...',
            onSubmitted: (_) => _apply(),
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
          label: 'Province',
          child: FilterDropdown<String>(
            value: _province,
            options: SportsData.provinces,
            labelOf: (province) => province,
            allLabel: 'All Provinces',
            onChanged: (value) => setState(() => _province = value),
          ),
        ),
        FilterField(
          label: 'School Type',
          child: FilterDropdown<SchoolType>(
            value: _type,
            options: SchoolType.values,
            labelOf: (type) => type.label,
            allLabel: 'All Types',
            onChanged: (value) => setState(() => _type = value),
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
      ],
    );
  }

  Widget _buildListHeader(int shownCount, int total) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: [
        Text(
          total == 0 ? 'No schools found' : 'Showing 1 - $shownCount of ${formatThousands(total)} schools',
          style: const TextStyle(fontSize: 12, color: AppColors.muted),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Sort by:', style: TextStyle(fontSize: 12, color: AppColors.muted)),
            const SizedBox(width: 8),
            SizedBox(
              width: 150,
              child: FilterDropdown<SchoolSort>(
                value: _sort,
                options: SchoolSort.values,
                labelOf: (sort) => sort.label,
                onChanged: (value) => setState(() => _sort = value ?? _sort),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGrid(List<School> shown) {
    if (shown.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const EmptyState('No schools match your filters.'),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 12.0;
        const cardHeight = 272.0;
        final columns = constraints.maxWidth >= 720
            ? 3
            : constraints.maxWidth >= 460
                ? 2
                : 1;
        final cardWidth = (constraints.maxWidth - gap * (columns - 1)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final school in shown)
              SizedBox(width: cardWidth, height: cardHeight, child: SchoolCard(school: school)),
            SizedBox(
              width: cardWidth,
              height: cardHeight,
              child: const PromoCard(
                eyebrow: 'Register your school',
                title: 'Join the Sportstures family',
                body: 'Register your school to manage your teams, fixtures, results and more.',
                buttonLabel: 'REGISTER YOUR SCHOOL',
                compact: true,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AdminBanner extends StatelessWidget {
  const _AdminBanner();

  @override
  Widget build(BuildContext context) {
    final button = SiteButton(
      label: 'REGISTER SCHOOL NOW',
      variant: SiteButtonVariant.dark,
      trailingIcon: Icons.arrow_forward,
      small: true,
      onPressed: () => openSiteRoute(context, SiteRoutes.signup),
    );
    const copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Are you a school administrator?',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink),
        ),
        SizedBox(height: 2),
        Text(
          'Register your school today and get full access to manage fixtures, results, teams and athlete statistics.',
          style: TextStyle(fontSize: 12, color: AppColors.ink, height: 1.4),
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFC21A),
        borderRadius: BorderRadius.circular(10),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 640) {
            return Row(
              children: [
                const Icon(Icons.admin_panel_settings_outlined, size: 30, color: AppColors.ink),
                const SizedBox(width: 14),
                const Expanded(child: copy),
                const SizedBox(width: 16),
                button,
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [copy, const SizedBox(height: 12), button],
          );
        },
      ),
    );
  }
}
