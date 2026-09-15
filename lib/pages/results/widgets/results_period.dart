import 'package:flutter/material.dart';

enum ResultsPeriod {
  all('All results', Icons.format_list_bulleted),
  today('Today', Icons.today_outlined),
  yesterday('Yesterday', Icons.history),
  thisWeek('This week', Icons.date_range_outlined),
  thisMonth('This month', Icons.calendar_month_outlined);

  const ResultsPeriod(this.label, this.icon);

  final String label;
  final IconData icon;

  bool contains(DateTime time, DateTime now) {
    final day = DateUtils.dateOnly(time);
    final today = DateUtils.dateOnly(now);
    return switch (this) {
      ResultsPeriod.all => true,
      ResultsPeriod.today => day == today,
      ResultsPeriod.yesterday => day == DateTime(today.year, today.month, today.day - 1),
      ResultsPeriod.thisWeek =>
        !day.isBefore(DateTime(today.year, today.month, today.day - (today.weekday - 1))),
      ResultsPeriod.thisMonth => DateUtils.isSameMonth(day, today),
    };
  }
}
