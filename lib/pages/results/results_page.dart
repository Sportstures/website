import 'package:flutter/material.dart';

import '../../data/match_filters.dart';
import '../../data/models.dart';
import '../../data/sports_data.dart';
import '../../utils/formatters.dart';
import '../../widgets/site/filter_bar.dart';
import '../../widgets/site/ai_summary_cards.dart';
import '../../widgets/site/match_rows.dart';
import '../../widgets/site/page_hero.dart';
import '../../widgets/site/promo_card.dart';
import '../../widgets/site/site_routes.dart';
import '../../widgets/site/site_scaffold.dart';
import '../../widgets/site/ui_kit.dart';
import 'widgets/results_period.dart';
import 'widgets/results_summary_card.dart';
import 'widgets/top_standings_card.dart';

class ResultsPage extends StatefulWidget {
  const ResultsPage({super.key});

  @override
  State<ResultsPage> createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  static const _pageSize = 10;

  var _filters = const MatchFilters();
  var _period = ResultsPeriod.all;
  var _visibleCount = _pageSize;
  var _showAllStandings = false;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final matching = SportsData.instance.results
        .where((r) => _filters.matches(r.fixture) && _period.contains(r.fixture.startsAt, now))
        .toList();

    return SiteScaffold(
      currentRoute: SiteRoutes.results,
      children: [
        const PageHero(
          title: 'Results',
          breadcrumb: 'Results',
          subtitle: 'Catch up on the latest school results across South Africa.',
        ),
        ContentWidth(
          child: Padding(
            padding: const EdgeInsets.only(top: 28, bottom: 56),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilterBar(
                  searchLabel: 'Search results',
                  filters: _filters,
                  onApply: (filters) => setState(() {
                    _filters = filters;
                    _visibleCount = _pageSize;
                  }),
                ),
                const SizedBox(height: 20),
                ChoiceTabs<ResultsPeriod>(
                  options: ResultsPeriod.values,
                  labelOf: (period) => period.label,
                  iconOf: (period) => period.icon,
                  selected: _period,
                  onSelect: (period) => setState(() {
                    _period = period;
                    _visibleCount = _pageSize;
                  }),
                ),
                const SizedBox(height: 20),
                TwoColumnLayout(
                  main: _buildResultList(matching),
                  sidebar: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AiResultsRecapCard(results: matching),
                      const SizedBox(height: 16),
                      TopStandingsCard(
                        standings: SportsData.standingsFor(matching),
                        showAll: _showAllStandings,
                        onToggle: () => setState(() => _showAllStandings = !_showAllStandings),
                      ),
                      const SizedBox(height: 16),
                      ResultsSummaryCard(results: matching),
                      const SizedBox(height: 16),
                      const PromoCard(),
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

  Widget _buildResultList(List<MatchResult> matching) {
    if (matching.isEmpty) {
      return SectionCard(
        title: _period.label,
        trailing: const CountLabel(count: 0, noun: 'result'),
        child: const EmptyState('No results match your filters.'),
      );
    }

    final dayCounts = groupByDay(matching, (r) => r.fixture.startsAt);
    final visibleByDay = groupByDay(matching.take(_visibleCount), (r) => r.fixture.startsAt);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final MapEntry(key: day, value: results) in visibleByDay.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: SectionCard(
              title: formatLongDate(day),
              trailing: CountLabel(count: dayCounts[day]!.length, noun: 'result'),
              child: DividedColumn(
                children: [for (final result in results) ResultRow(result: result)],
              ),
            ),
          ),
        if (matching.length > _visibleCount)
          Center(
            child: SiteButton(
              label: 'LOAD MORE RESULTS',
              small: true,
              onPressed: () => setState(() => _visibleCount += _pageSize),
            ),
          ),
      ],
    );
  }
}
