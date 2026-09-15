import 'package:flutter/material.dart';

const _weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
const _months = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

String weekdayName(DateTime date) => _weekdays[date.weekday - 1];

/// e.g. SAT
String shortWeekday(DateTime date) => weekdayName(date).substring(0, 3).toUpperCase();

String monthName(int month) => _months[month - 1];

/// e.g. MAY
String shortMonth(DateTime date) => monthName(date.month).substring(0, 3).toUpperCase();

/// e.g. SATURDAY, 24 MAY 2026
String formatLongDate(DateTime date) =>
    '${weekdayName(date)}, ${date.day} ${monthName(date.month)} ${date.year}'.toUpperCase();

/// e.g. 24 May 2026
String formatShortDate(DateTime date) =>
    '${date.day} ${monthName(date.month).substring(0, 3)} ${date.year}';

/// e.g. 10:00 AM
String formatTime(DateTime time) {
  final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute ${time.hour < 12 ? 'AM' : 'PM'}';
}

/// e.g. 24 May – 31 May 2026
String formatDateRange(DateTimeRange range) {
  String dayMonth(DateTime d) => '${d.day} ${monthName(d.month).substring(0, 3)}';
  final start = range.start;
  final end = range.end;
  return start.year == end.year
      ? '${dayMonth(start)} – ${dayMonth(end)} ${end.year}'
      : '${dayMonth(start)} ${start.year} – ${dayMonth(end)} ${end.year}';
}

/// e.g. 1520 -> 1 520
String formatThousands(int value) =>
    value.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ' ');

/// Groups [items] by calendar day, keeping their existing order.
Map<DateTime, List<T>> groupByDay<T>(Iterable<T> items, DateTime Function(T item) dateOf) {
  final groups = <DateTime, List<T>>{};
  for (final item in items) {
    groups.putIfAbsent(DateUtils.dateOnly(dateOf(item)), () => []).add(item);
  }
  return groups;
}
