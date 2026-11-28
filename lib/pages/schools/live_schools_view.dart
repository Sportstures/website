import 'package:flutter/material.dart';

import '../../api/api_client.dart';
import '../../api/rankings_api.dart';
import '../../api/schools_api.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';
import '../../widgets/site/filter_controls.dart';
import '../../widgets/site/page_hero.dart';
import '../../widgets/site/promo_card.dart';
import '../../widgets/site/site_routes.dart';
import '../../widgets/site/site_scaffold.dart';
import '../../widgets/site/ui_kit.dart';
import '../coach/photo_badge.dart';

/// Where a school's page lives, so it can be refreshed or shared.
String schoolRoute(int id) => '${SiteRoutes.school}?id=$id';

/// The Schools page on the backend's list.
class LiveSchoolsView extends StatefulWidget {
  const LiveSchoolsView({super.key, required this.api});

  final ApiClient api;

  @override
  State<LiveSchoolsView> createState() => _LiveSchoolsViewState();
}

class _LiveSchoolsViewState extends State<LiveSchoolsView> {
  static const _pageSize = 12;

  late final SchoolsApi _api = SchoolsApi(widget.api);

  // Draft filter values; the search and dropdowns take effect when FILTER is pressed.
  final _search = TextEditingController();
  String? _province;
  int? _sportId;

  ({String search, String? province, int? sportId}) _applied = (search: '', province: null, sportId: null);

  List<LiveSchool>? _schools;
  int _total = 0;

  /// Every school, from the last unfiltered answer.
  int? _registered;
  bool _hasMore = false;
  bool _loadingMore = false;
  bool _failed = false;
  SchoolFilters _filters = const SchoolFilters();
  List<RankingRow> _top = const [];

  /// Only the answer to the newest search is shown.
  var _request = 0;

  @override
  void initState() {
    super.initState();
    _load();
    _loadSides();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load({bool more = false}) async {
    final request = more ? _request : ++_request;
    final q = _applied;
    setState(() {
      _failed = false;
      if (more) {
        _loadingMore = true;
      } else {
        _schools = null;
        _loadingMore = false;
      }
    });
    try {
      final page = await _api.list(
        query: q.search,
        province: q.province,
        sportId: q.sportId,
        limit: _pageSize,
        offset: more ? _schools!.length : 0,
      );
      if (!mounted || request != _request) return;
      setState(() {
        _schools = [if (more) ..._schools!, ...page.schools];
        _total = page.total;
        if (q.search.isEmpty && q.province == null && q.sportId == null) _registered = page.total;
        _hasMore = page.hasMore;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted || request != _request) return;
      setState(() {
        _loadingMore = false;
        if (!more) _failed = true;
      });
    }
  }

  /// The filter choices and the ranking card. The list works without either.
  Future<void> _loadSides() async {
    try {
      final filters = await _api.filters();
      if (mounted) setState(() => _filters = filters);
    } catch (_) {}
    try {
      final top = await RankingsApi(widget.api).rankings(type: 'schools', limit: 5);
      if (mounted) setState(() => _top = top.rows);
    } catch (_) {}
  }

  void _apply() {
    _applied = (search: _search.text.trim(), province: _province, sportId: _sportId);
    _load();
    if (_filters.provinces.isEmpty) _loadSides();
  }

  void _reset() {
    _search.clear();
    _province = null;
    _sportId = null;
    _apply();
  }

  @override
  Widget build(BuildContext context) {
    final withSchools = [for (final p in _filters.provinces) if (p.count > 0) p];

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
                _filterPanel(),
                const SizedBox(height: 20),
                if (_filters.provinces.isNotEmpty) ...[
                  StatsBand(stats: [
                    if (_registered != null) (Icons.emoji_events_outlined, formatThousands(_registered!), 'Registered Schools'),
                    (Icons.location_on_outlined, '${withSchools.length}', 'Provinces'),
                    (Icons.sports_outlined, '${_filters.sports.length}', 'Sports'),
                  ]),
                  const SizedBox(height: 20),
                ],
                TwoColumnLayout(
                  main: _list(),
                  sidebar: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (withSchools.isNotEmpty) _provinceCard(withSchools),
                      if (_top.isNotEmpty) ...[const SizedBox(height: 16), _topCard()],
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

  Widget _filterPanel() {
    final provinces = [for (final p in _filters.provinces) p.name];
    if (_province != null && !provinces.contains(_province)) provinces.add(_province!);
    return FilterPanel(
      onApply: _apply,
      onReset: _reset,
      fields: [
        FilterField(
          label: 'Search Schools',
          flex: 3,
          wide: true,
          child: FilterSearchField(controller: _search, hint: 'Search by school name or town...', onSubmitted: (_) => _apply()),
        ),
        FilterField(
          label: 'Province',
          child: FilterDropdown<String>(
            value: _province,
            options: provinces,
            labelOf: (p) => p,
            allLabel: 'All Provinces',
            onChanged: (value) => setState(() => _province = value),
          ),
        ),
        FilterField(
          label: 'Sport',
          child: FilterDropdown<int>(
            value: _sportId,
            options: [for (final s in _filters.sports) s.id],
            labelOf: (id) => _filters.sports.where((s) => s.id == id).map((s) => s.name).firstOrNull ?? 'Sport',
            allLabel: 'All Sports',
            onChanged: (value) => setState(() => _sportId = value),
          ),
        ),
      ],
    );
  }

  Widget _boxed(Widget child) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: child,
      );

  Widget _list() {
    final schools = _schools;
    if (_failed) {
      return _boxed(Column(children: [
        const EmptyState("Schools couldn't be loaded."),
        SiteButton(label: 'TRY AGAIN', small: true, onPressed: _apply),
        const SizedBox(height: 20),
      ]));
    }
    if (schools == null) return const Padding(padding: EdgeInsets.all(48), child: Center(child: CircularProgressIndicator()));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _total == 0 ? 'No schools found' : 'Showing ${schools.length} of ${formatThousands(_total)} schools',
          style: const TextStyle(fontSize: 12, color: AppColors.muted),
        ),
        const SizedBox(height: 12),
        if (schools.isEmpty)
          _boxed(const EmptyState('No schools match your filters.'))
        else
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = 12.0;
              final columns = constraints.maxWidth >= 720 ? 3 : (constraints.maxWidth >= 460 ? 2 : 1);
              final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [for (final s in schools) SizedBox(width: width, height: 250, child: _card(s))],
              );
            },
          ),
        if (_hasMore) ...[
          const SizedBox(height: 16),
          Center(
            child: SiteButton(
              label: _loadingMore ? 'LOADING…' : 'LOAD MORE SCHOOLS',
              small: true,
              onPressed: _loadingMore ? null : () => _load(more: true),
            ),
          ),
        ],
        const SizedBox(height: 28),
        const PromoCard(
          eyebrow: 'Register your school',
          title: 'Join the Sportstures family',
          body: 'Register your school to manage your teams, fixtures, results and more.',
          buttonLabel: 'REGISTER YOUR SCHOOL',
        ),
      ],
    );
  }

  Widget _card(LiveSchool s) {
    const muted = TextStyle(fontSize: 12, color: AppColors.muted);
    return _boxed(Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          PhotoBadge(fallback: s.name, size: 52, square: true),
          const SizedBox(height: 10),
          Text(s.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink)),
          if (s.location.isNotEmpty) Text(s.location, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: muted),
          const SizedBox(height: 6),
          Text(s.sports.isEmpty ? 'No teams yet' : s.sports.join(' · '),
              textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: muted),
          const Spacer(),
          Text(s.played == 0 ? 'No matches yet' : '${s.played} played · ${s.winRate ?? 0}% won',
              style: muted.copyWith(fontWeight: FontWeight.w700, color: AppColors.green)),
          const SizedBox(height: 10),
          SiteButton(
            label: 'VIEW PROFILE',
            variant: SiteButtonVariant.outline,
            small: true,
            expand: true,
            onPressed: () => openSiteRoute(context, schoolRoute(s.id)),
          ),
        ],
      ),
    ));
  }

  Widget _provinceCard(List<({String name, int count})> provinces) => SectionCard(
        title: 'Browse by province',
        child: DividedColumn(
          children: [
            for (final p in provinces)
              InkWell(
                onTap: () {
                  // A second tap on the chosen province shows every school again.
                  _province = _applied.province == p.name ? null : p.name;
                  _apply();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(p.name,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.ink,
                              fontWeight: _applied.province == p.name ? FontWeight.w900 : FontWeight.w500,
                            )),
                      ),
                      CountLabel(count: p.count, noun: 'school'),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );

  Widget _topCard() => SectionCard(
        title: 'Top ranked schools',
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final r in _top)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      SizedBox(width: 22, child: Text('${r.position}', style: tableStrongStyle)),
                      Expanded(child: Text(r.name, style: tableCellStyle, overflow: TextOverflow.ellipsis)),
                      Text('${formatThousands(r.points)} pts', style: tableStrongStyle),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              SiteButton(
                label: 'FULL RANKINGS',
                variant: SiteButtonVariant.outline,
                small: true,
                onPressed: () => openSiteRoute(context, SiteRoutes.rankings),
              ),
            ],
          ),
        ),
      );
}
