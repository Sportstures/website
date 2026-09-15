import 'package:flutter/material.dart';

import 'models.dart';

class MatchFilters {
  const MatchFilters({this.query = '', this.sport, this.region, this.dateRange});

  final String query;
  final Sport? sport;
  final String? region;
  final DateTimeRange? dateRange;

  MatchFilters withSport(Sport? sport) =>
      MatchFilters(query: query, sport: sport, region: region, dateRange: dateRange);

  bool matches(Fixture fixture) {
    final search = query.trim().toLowerCase();
    if (search.isNotEmpty &&
        ![fixture.home.name, fixture.away.name, fixture.venue]
            .any((text) => text.toLowerCase().contains(search))) {
      return false;
    }
    if (sport != null && fixture.sport != sport) return false;
    if (region != null && fixture.home.region != region && fixture.away.region != region) {
      return false;
    }
    final range = dateRange;
    if (range != null) {
      final day = DateUtils.dateOnly(fixture.startsAt);
      if (day.isBefore(range.start) || day.isAfter(range.end)) return false;
    }
    return true;
  }
}
