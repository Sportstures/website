import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../utils/formatters.dart';

/// Week of day tabs with previous/next arrows and the list/calendar toggle.
class DateStrip extends StatelessWidget {
  const DateStrip({
    super.key,
    required this.days,
    required this.selectedDay,
    required this.onSelect,
    required this.onPrevious,
    required this.onNext,
    required this.calendarView,
    required this.onViewChanged,
  });

  final List<DateTime> days;

  /// Null when no single day is highlighted (calendar view).
  final DateTime? selectedDay;
  final ValueChanged<DateTime> onSelect;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final bool calendarView;
  final ValueChanged<bool> onViewChanged;

  @override
  Widget build(BuildContext context) {
    final strip = Row(
      children: [
        IconButton(
          tooltip: 'Previous week',
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.chevron_left, size: 20),
          onPressed: onPrevious,
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final day in days)
                  _DayTab(
                    day: day,
                    selected: selectedDay != null && DateUtils.isSameDay(day, selectedDay),
                    onTap: () => onSelect(day),
                  ),
              ],
            ),
          ),
        ),
        IconButton(
          tooltip: 'Next week',
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.chevron_right, size: 20),
          onPressed: onNext,
        ),
      ],
    );

    final toggle = Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ViewOption(
            icon: Icons.view_list_outlined,
            label: 'List view',
            selected: !calendarView,
            onTap: () => onViewChanged(false),
          ),
          _ViewOption(
            icon: Icons.calendar_view_week_outlined,
            label: 'Calendar view',
            selected: calendarView,
            onTap: () => onViewChanged(true),
          ),
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 820) {
            return Row(children: [Expanded(child: strip), const SizedBox(width: 12), toggle]);
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [strip, const SizedBox(height: 8), Center(child: toggle), const SizedBox(height: 4)],
          );
        },
      ),
    );
  }
}

class _DayTab extends StatelessWidget {
  const _DayTab({required this.day, required this.selected, required this.onTap});

  final DateTime day;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.green : AppColors.muted;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${shortWeekday(day)} ${day.day} ${shortMonth(day)}',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
            ),
            const SizedBox(height: 6),
            Container(
              height: 2,
              width: 44,
              color: selected ? AppColors.green : Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }
}

class _ViewOption extends StatelessWidget {
  const _ViewOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.green : AppColors.muted;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: selected
            ? BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(6),
              )
            : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              label.toUpperCase(),
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
