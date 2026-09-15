import 'package:flutter/material.dart';

import '../../data/match_filters.dart';
import '../../data/models.dart';
import '../../data/sports_data.dart';
import '../../utils/formatters.dart';
import '../../widgets/site/filter_bar.dart';
import '../../widgets/site/match_rows.dart';
import '../../widgets/site/page_hero.dart';
import '../../widgets/site/promo_card.dart';
import '../../widgets/site/site_routes.dart';
import '../../widgets/site/site_scaffold.dart';
import '../../widgets/site/ui_kit.dart';
import 'widgets/date_strip.dart';
import 'widgets/month_calendar_card.dart';
import 'widgets/quick_filters_card.dart';

class FixturesPage extends StatefulWidget {
  const FixturesPage({super.key});

  @override
  State<FixturesPage> createState() => _FixturesPageState();
}

class _FixturesPageState extends State<FixturesPage> {
  static const _pageSize = 8;
  static const _stripLength = 7;

  var _filters = const MatchFilters();
  late DateTime _stripStart = DateUtils.dateOnly(DateTime.now());

  /// Starts on the first day that still has fixtures, so the list isn't empty
  /// when today's matches are already over.
  late DateTime _selectedDay = SportsData.instance.fixtures.isEmpty
      ? _stripStart
      : DateUtils.dateOnly(SportsData.instance.fixtures.first.startsAt);

  /// Calendar view lists the whole week in the strip instead of one day.
  var _calendarView = false;
  var _visibleCount = _pageSize;

  static DateTime _addDays(DateTime day, int days) => DateTime(day.year, day.month, day.day + days);

  void _applyFilters(MatchFilters filters) {
    setState(() {
      _filters = filters;
      _visibleCount = _pageSize;
      final range = filters.dateRange;
      if (range != null) {
        _stripStart = range.start;
        _selectedDay = range.start;
      }
    });
  }

  void _selectDay(DateTime day) {
    setState(() {
      _selectedDay = day;
      _calendarView = false;
      _visibleCount = _pageSize;
      if (day.isBefore(_stripStart) || day.isAfter(_addDays(_stripStart, _stripLength - 1))) {
        _stripStart = day;
      }
    });
  }

  void _shiftStrip(int days) {
    setState(() {
      _stripStart = _addDays(_stripStart, days);
      _selectedDay = _stripStart;
      _visibleCount = _pageSize;
    });
  }

  void _selectSport(Sport? sport) {
    setState(() {
      _filters = _filters.withSport(sport);
      _visibleCount = _pageSize;
    });
  }

  @override
  Widget build(BuildContext context) {
    final matching = SportsData.instance.fixtures.where(_filters.matches).toList();
    final stripDays = [for (var i = 0; i < _stripLength; i++) _addDays(_stripStart, i)];
    final shown = matching.where((fixture) {
      final day = DateUtils.dateOnly(fixture.startsAt);
      return _calendarView
          ? !day.isBefore(stripDays.first) && !day.isAfter(stripDays.last)
          : DateUtils.isSameDay(day, _selectedDay);
    }).toList();

    return SiteScaffold(
      currentRoute: SiteRoutes.fixtures,
      children: [
        const PageHero(
          title: 'Fixtures',
          breadcrumb: 'Fixtures',
          subtitle: 'Find upcoming school fixtures across South Africa.',
        ),
        ContentWidth(
          child: Padding(
            padding: const EdgeInsets.only(top: 28, bottom: 56),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilterBar(
                  searchLabel: 'Search fixtures',
                  filters: _filters,
                  onApply: _applyFilters,
                ),
                const SizedBox(height: 20),
                DateStrip(
                  days: stripDays,
                  selectedDay: _calendarView ? null : _selectedDay,
                  onSelect: _selectDay,
                  onPrevious: () => _shiftStrip(-_stripLength),
                  onNext: () => _shiftStrip(_stripLength),
                  calendarView: _calendarView,
                  onViewChanged: (value) => setState(() {
                    _calendarView = value;
                    _visibleCount = _pageSize;
                  }),
                ),
                const SizedBox(height: 20),
                TwoColumnLayout(
                  main: _buildFixtureList(shown),
                  sidebar: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      MonthCalendarCard(
                        selectedDay: _selectedDay,
                        markedDays: {for (final f in matching) DateUtils.dateOnly(f.startsAt)},
                        onSelect: _selectDay,
                      ),
                      const SizedBox(height: 16),
                      QuickFiltersCard(selected: _filters.sport, onSelect: _selectSport),
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

  Widget _buildFixtureList(List<Fixture> shown) {
    if (shown.isEmpty) {
      return SectionCard(
        title: _calendarView ? 'This week' : formatLongDate(_selectedDay),
        trailing: const CountLabel(count: 0, noun: 'fixture'),
        child: EmptyState(
          _calendarView
              ? 'No fixtures match your filters this week.'
              : 'No fixtures match your filters on this day.',
        ),
      );
    }

    final dayCounts = groupByDay(shown, (f) => f.startsAt);
    final visibleByDay = groupByDay(shown.take(_visibleCount), (f) => f.startsAt);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final MapEntry(key: day, value: fixtures) in visibleByDay.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: SectionCard(
              title: formatLongDate(day),
              trailing: CountLabel(count: dayCounts[day]!.length, noun: 'fixture'),
              child: DividedColumn(
                children: [for (final fixture in fixtures) FixtureRow(fixture: fixture)],
              ),
            ),
          ),
        if (shown.length > _visibleCount)
          Center(
            child: SiteButton(
              label: 'LOAD MORE FIXTURES',
              small: true,
              onPressed: () => setState(() => _visibleCount += _pageSize),
            ),
          ),
      ],
    );
  }
}
