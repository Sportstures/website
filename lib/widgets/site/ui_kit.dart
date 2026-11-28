import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

enum SiteButtonVariant { green, orange, dark, outline, outlineOrange, outlineLight }

class SiteButton extends StatelessWidget {
  const SiteButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = SiteButtonVariant.green,
    this.icon,
    this.trailingIcon,
    this.small = false,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final SiteButtonVariant variant;
  final IconData? icon;
  final IconData? trailingIcon;
  final bool small;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final (background, foreground, side) = switch (variant) {
      SiteButtonVariant.green => (AppColors.green, Colors.white, BorderSide.none),
      SiteButtonVariant.orange => (AppColors.orange, Colors.white, BorderSide.none),
      SiteButtonVariant.dark => (AppColors.ink, Colors.white, BorderSide.none),
      SiteButtonVariant.outline =>
        (Colors.transparent, AppColors.green, const BorderSide(color: AppColors.border)),
      SiteButtonVariant.outlineOrange =>
        (Colors.transparent, AppColors.orange, const BorderSide(color: AppColors.orange)),
      SiteButtonVariant.outlineLight =>
        (Colors.transparent, Colors.white, const BorderSide(color: Colors.white70)),
    };
    final iconSize = small ? 14.0 : 16.0;

    final button = TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: background,
        foregroundColor: foreground,
        side: side,
        padding: EdgeInsets.symmetric(horizontal: small ? 16 : 22, vertical: small ? 12 : 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        textStyle: TextStyle(
          fontSize: small ? 11 : 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: iconSize),
            const SizedBox(width: 8),
          ],
          // Flexible so a long label in a narrow slot - a promo button in a
          // grid cell, say - shortens instead of bursting the button open.
          Flexible(
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, softWrap: false),
          ),
          if (trailingIcon != null) ...[
            const SizedBox(width: 8),
            Icon(trailingIcon, size: iconSize),
          ],
        ],
      ),
    );

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// White card with a tinted title bar, used for lists and sidebar panels.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
  });

  final String title;
  final Widget child;
  final Widget? trailing;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                ?trailing,
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}

/// Small "VIEW ALL →" style link for card headers.
class CardLink extends StatelessWidget {
  const CardLink({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.green,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_forward, size: 12, color: AppColors.green),
          ],
        ),
      ),
    );
  }
}

/// e.g. "8 FIXTURES"
class CountLabel extends StatelessWidget {
  const CountLabel({super.key, required this.count, required this.noun});

  final int count;
  final String noun;

  @override
  Widget build(BuildContext context) {
    return Text(
      '$count ${count == 1 ? noun : '$noun${noun.endsWith('ch') ? 'es' : 's'}'}'.toUpperCase(),
      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.muted),
    );
  }
}

/// Section label flanked by short orange rules.
class SectionEyebrow extends StatelessWidget {
  const SectionEyebrow(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final rule = Container(width: 32, height: 2, color: AppColors.orange);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        rule,
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            text.toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
              letterSpacing: 1,
            ),
          ),
        ),
        const SizedBox(width: 10),
        rule,
      ],
    );
  }
}

/// Small uppercase label above a heading, e.g. OUR STORY.
class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key, this.color = AppColors.green});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color, letterSpacing: 1),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill(this.label, {super.key, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: Column(
        children: [
          const Icon(Icons.event_busy_outlined, size: 32, color: AppColors.muted),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

/// Stacks [children] with hairline dividers between them.
class DividedColumn extends StatelessWidget {
  const DividedColumn({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, child) in children.indexed) ...[
          if (i > 0) const Divider(height: 1, color: AppColors.border),
          child,
        ],
      ],
    );
  }
}

/// Row of icon + label chips where one option is selected.
class ChoiceTabs<T> extends StatelessWidget {
  const ChoiceTabs({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelect,
    required this.labelOf,
    required this.iconOf,
  });

  final List<T> options;
  final T selected;
  final ValueChanged<T> onSelect;
  final String Function(T option) labelOf;
  final IconData Function(T option) iconOf;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final option in options)
          _ChoiceChip(
            icon: iconOf(option),
            label: labelOf(option),
            selected: option == selected,
            onTap: () => onSelect(option),
          ),
      ],
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
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
    final color = selected ? Colors.white : AppColors.ink;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.green : Colors.white,
          border: Border.all(color: selected ? AppColors.green : AppColors.border),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              label.toUpperCase(),
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

/// Green band of headline numbers, e.g. "1 248 Registered Schools".
class StatsBand extends StatelessWidget {
  const StatsBand({super.key, required this.stats, this.valueColor = Colors.white});

  /// (icon, value, label)
  final List<(IconData, String, String)> stats;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.green,
        borderRadius: BorderRadius.circular(10),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const gap = 16.0;
          final columns = constraints.maxWidth >= 720 ? stats.length : 2;
          final itemWidth = (constraints.maxWidth - gap * (columns - 1)) / columns;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final (icon, value, label) in stats)
                SizedBox(
                  width: itemWidth,
                  child: Row(
                    children: [
                      Icon(icon, size: 26, color: Colors.white.withValues(alpha: 0.8)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              value,
                              style: TextStyle(color: valueColor, fontSize: 22, fontWeight: FontWeight.w900),
                            ),
                            Text(
                              label,
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class SiteTableColumn {
  const SiteTableColumn(this.label, {this.width, this.alignment = Alignment.center});

  final String label;

  /// Fixed width, or null to take the remaining space.
  final double? width;
  final Alignment alignment;
}

const tableCellStyle = TextStyle(fontSize: 12, color: AppColors.ink);
const tableStrongStyle = TextStyle(fontSize: 12, color: AppColors.ink, fontWeight: FontWeight.w800);

/// Table with a green header row. Scrolls sideways when narrower than
/// [minWidth] so columns never get crushed.
class SiteTable extends StatelessWidget {
  const SiteTable({
    super.key,
    required this.columns,
    required this.rows,
    this.rowMarkers,
    this.minWidth = 560,
  });

  final List<SiteTableColumn> columns;
  final List<List<Widget>> rows;

  /// Optional coloured edge per row, e.g. qualification zones.
  final List<Color?>? rowMarkers;
  final double minWidth;

  Widget _line(List<Widget> cells, {Color? marker, Color? background}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        border: Border(left: BorderSide(color: marker ?? Colors.transparent, width: 3)),
      ),
      child: Row(
        children: [
          for (final (i, column) in columns.indexed)
            if (column.width == null)
              Expanded(child: Align(alignment: column.alignment, child: cells[i]))
            else
              SizedBox(
                width: column.width,
                child: Align(alignment: column.alignment, child: cells[i]),
              ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final table = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _line(
          [
            for (final column in columns)
              Text(
                column.label.toUpperCase(),
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
              ),
          ],
          background: AppColors.green,
        ),
        DividedColumn(
          children: [
            for (final (i, row) in rows.indexed) _line(row, marker: rowMarkers?[i]),
          ],
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= minWidth) return table;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(width: minWidth, child: table),
        );
      },
    );
  }
}

/// ▲ 2 / ▼ 1 / – movement indicator.
class TrendIndicator extends StatelessWidget {
  const TrendIndicator(this.trend, {super.key});

  final int trend;

  @override
  Widget build(BuildContext context) {
    if (trend == 0) {
      return const Text('–', style: TextStyle(fontSize: 12, color: AppColors.muted));
    }
    final up = trend > 0;
    final color = up ? AppColors.greenBright : const Color(0xFFDC2626);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(up ? Icons.arrow_drop_up : Icons.arrow_drop_down, size: 20, color: color),
        Text('${trend.abs()}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }
}
