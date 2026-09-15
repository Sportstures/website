import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/site/ui_kit.dart';

/// Month grid for jumping to a day. Days with fixtures get an orange dot.
class MonthCalendarCard extends StatefulWidget {
  const MonthCalendarCard({
    super.key,
    required this.selectedDay,
    required this.markedDays,
    required this.onSelect,
  });

  final DateTime selectedDay;
  final Set<DateTime> markedDays;
  final ValueChanged<DateTime> onSelect;

  @override
  State<MonthCalendarCard> createState() => _MonthCalendarCardState();
}

class _MonthCalendarCardState extends State<MonthCalendarCard> {
  static const _weekdayLabels = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

  late DateTime _month = DateTime(widget.selectedDay.year, widget.selectedDay.month);

  @override
  void didUpdateWidget(MonthCalendarCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!DateUtils.isSameMonth(oldWidget.selectedDay, widget.selectedDay)) {
      _month = DateTime(widget.selectedDay.year, widget.selectedDay.month);
    }
  }

  void _changeMonth(int delta) => setState(() => _month = DateTime(_month.year, _month.month + delta));

  @override
  Widget build(BuildContext context) {
    final leadingDays = DateTime(_month.year, _month.month).weekday - 1;
    final today = DateUtils.dateOnly(DateTime.now());

    return SectionCard(
      title: 'Calendar',
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Previous month',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.chevron_left, size: 18),
                onPressed: () => _changeMonth(-1),
              ),
              Expanded(
                child: Text(
                  '${monthName(_month.month)} ${_month.year}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink),
                ),
              ),
              IconButton(
                tooltip: 'Next month',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.chevron_right, size: 18),
                onPressed: () => _changeMonth(1),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              for (final label in _weekdayLabels)
                Expanded(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.muted),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          for (var week = 0; week < 6; week++)
            Row(
              children: [
                for (var weekday = 0; weekday < 7; weekday++)
                  Expanded(
                    child: _buildDay(
                      DateTime(_month.year, _month.month, 1 - leadingDays + week * 7 + weekday),
                      today,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildDay(DateTime day, DateTime today) {
    final inMonth = day.month == _month.month;
    final selected = DateUtils.isSameDay(day, widget.selectedDay);
    final isToday = DateUtils.isSameDay(day, today);
    final marked = widget.markedDays.contains(day);

    return InkWell(
      onTap: () => widget.onSelect(day),
      customBorder: const CircleBorder(),
      child: SizedBox(
        height: 36,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? AppColors.green : null,
                border: isToday && !selected ? Border.all(color: AppColors.orange) : null,
              ),
              child: Text(
                '${day.day}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                  color: selected
                      ? Colors.white
                      : inMonth
                          ? AppColors.ink
                          : AppColors.muted.withValues(alpha: 0.5),
                ),
              ),
            ),
            const SizedBox(height: 2),
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: marked ? AppColors.orange : Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
