import 'package:flutter/material.dart';

import '../../../data/models.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/site/site_routes.dart';
import '../../../widgets/site/ui_kit.dart';

class QuickFiltersCard extends StatelessWidget {
  const QuickFiltersCard({super.key, required this.selected, required this.onSelect});

  /// Null means all sports.
  final Sport? selected;
  final ValueChanged<Sport?> onSelect;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Quick filters',
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SportTile(
            icon: Icons.apps,
            label: 'All Sports',
            selected: selected == null,
            onTap: () => onSelect(null),
          ),
          for (final sport in Sport.values)
            _SportTile(
              icon: sport.icon,
              label: sport.label,
              selected: selected == sport,
              onTap: () => onSelect(sport),
            ),
          const SizedBox(height: 8),
          Center(
            child: SiteButton(
              label: 'View all sports',
              small: true,
              // TODO: open the sports directory once that page exists
              onPressed: () => openSiteRoute(context, SiteRoutes.sports),
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _SportTile extends StatelessWidget {
  const _SportTile({
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
    final color = selected ? AppColors.green : AppColors.ink;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.green.withValues(alpha: 0.08) : null,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
