import 'package:flutter/material.dart';

import '../../../data/models.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/site/ui_kit.dart';

/// Shortcuts to other sport / age group tables.
class SelectTableCard extends StatefulWidget {
  const SelectTableCard({
    super.key,
    required this.sport,
    required this.ageGroup,
    required this.onSelect,
  });

  final Sport sport;
  final String? ageGroup;
  final void Function(Sport sport, String ageGroup) onSelect;

  @override
  State<SelectTableCard> createState() => _SelectTableCardState();
}

class _SelectTableCardState extends State<SelectTableCard> {
  static const _popular = [
    (Sport.football, 'U/19'),
    (Sport.rugby, 'U/19'),
    (Sport.netball, 'U/19'),
    (Sport.basketball, 'U/16'),
    (Sport.hockey, 'U/19'),
  ];

  var _showAll = false;

  @override
  Widget build(BuildContext context) {
    final tables = _showAll ? [for (final sport in Sport.values) (sport, 'U/19')] : _popular;

    return SectionCard(
      title: 'Select another table',
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (sport, ageGroup) in tables)
            _TableTile(
              sport: sport,
              ageGroup: ageGroup,
              selected: sport == widget.sport && ageGroup == widget.ageGroup,
              onTap: () => widget.onSelect(sport, ageGroup),
            ),
          const SizedBox(height: 4),
          Center(
            child: SiteButton(
              label: _showAll ? 'Show popular tables' : 'View all sports',
              small: true,
              onPressed: () => setState(() => _showAll = !_showAll),
            ),
          ),
        ],
      ),
    );
  }
}

class _TableTile extends StatelessWidget {
  const _TableTile({
    required this.sport,
    required this.ageGroup,
    required this.selected,
    required this.onTap,
  });

  final Sport sport;
  final String ageGroup;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.green : AppColors.ink;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.green.withValues(alpha: 0.06) : Colors.white,
            border: Border.all(color: selected ? AppColors.green : AppColors.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(sport.icon, size: 16, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${sport.label} $ageGroup',
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, size: 18, color: color),
            ],
          ),
        ),
      ),
    );
  }
}
