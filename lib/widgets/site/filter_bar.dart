import 'package:flutter/material.dart';

import '../../data/match_filters.dart';
import '../../data/models.dart';
import '../../data/sports_data.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';
import 'filter_controls.dart';

/// Search, sport, region and date filters for match lists. Edits are a draft
/// until FILTER is pressed (or search is submitted), then [onApply] receives them.
class FilterBar extends StatefulWidget {
  const FilterBar({
    super.key,
    required this.searchLabel,
    required this.filters,
    required this.onApply,
    this.regions,
  });

  final String searchLabel;
  final MatchFilters filters;
  final ValueChanged<MatchFilters> onApply;

  /// The regions to offer. Defaults to the sample data's regions.
  final List<String>? regions;

  @override
  State<FilterBar> createState() => _FilterBarState();
}

class _FilterBarState extends State<FilterBar> {
  late final _search = TextEditingController(text: widget.filters.query);
  late Sport? _sport = widget.filters.sport;
  late String? _region = widget.filters.region;
  late DateTimeRange? _dateRange = widget.filters.dateRange;

  @override
  void didUpdateWidget(FilterBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The page can change filters too (e.g. quick filters), so follow along.
    if (!identical(oldWidget.filters, widget.filters)) {
      _search.text = widget.filters.query;
      _sport = widget.filters.sport;
      _region = widget.filters.region;
      _dateRange = widget.filters.dateRange;
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _apply() {
    widget.onApply(MatchFilters(
      query: _search.text.trim(),
      sport: _sport,
      region: _region,
      dateRange: _dateRange,
    ));
  }

  void _reset() {
    setState(() {
      _search.clear();
      _sport = null;
      _region = null;
      _dateRange = null;
    });
    widget.onApply(const MatchFilters());
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: _dateRange,
      builder: (context, child) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440, maxHeight: 680),
          child: child,
        ),
      ),
    );
    if (picked != null && mounted) setState(() => _dateRange = picked);
  }

  @override
  Widget build(BuildContext context) {
    return FilterPanel(
      onApply: _apply,
      onReset: _reset,
      fields: [
        FilterField(
          label: widget.searchLabel,
          flex: 4,
          wide: true,
          child: FilterSearchField(
            controller: _search,
            hint: 'Search by team, school or venue...',
            onSubmitted: (_) => _apply(),
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
          label: 'Region',
          child: FilterDropdown<String>(
            value: _region,
            options: widget.regions ?? SportsData.regions,
            labelOf: (region) => region,
            allLabel: 'All Regions',
            onChanged: (value) => setState(() => _region = value),
          ),
        ),
        FilterField(
          label: 'Date Range',
          flex: 3,
          wide: true,
          child: InkWell(
            onTap: _pickDateRange,
            borderRadius: BorderRadius.circular(6),
            child: FilterBox(
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.muted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _dateRange == null ? 'Any date' : formatDateRange(_dateRange!),
                      style: filterInputText,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down, size: 18, color: AppColors.muted),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
