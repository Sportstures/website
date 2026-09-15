import 'package:flutter/material.dart';

import '../../../data/models.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/site/match_rows.dart';
import '../../../widgets/site/site_routes.dart';
import '../../../widgets/site/ui_kit.dart';

class SchoolCard extends StatelessWidget {
  const SchoolCard({super.key, required this.school});

  static const _sportsShown = 3;

  final School school;

  @override
  Widget build(BuildContext context) {
    final hiddenSports = school.sports.length - _sportsShown;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              TeamCrest(school: school, size: 48),
              if (school.featured)
                const Positioned(
                  right: -6,
                  top: -4,
                  child: Icon(Icons.star, size: 16, color: AppColors.orange),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            school.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.ink),
          ),
          const SizedBox(height: 2),
          Text(school.location, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 6,
            children: [
              for (final sport in school.sports.take(_sportsShown))
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(sport.icon, size: 12, color: AppColors.muted),
                    const SizedBox(width: 3),
                    Text(sport.label, style: const TextStyle(fontSize: 10, color: AppColors.ink)),
                  ],
                ),
            ],
          ),
          if (hiddenSports > 0) ...[
            const SizedBox(height: 6),
            Text('+$hiddenSports more', style: const TextStyle(fontSize: 10, color: AppColors.muted)),
          ],
          const Spacer(),
          SiteButton(
            label: 'VIEW PROFILE',
            variant: SiteButtonVariant.outline,
            small: true,
            expand: true,
            // TODO: open the school profile page once it's designed
            onPressed: () => openSiteRoute(context, null),
          ),
        ],
      ),
    );
  }
}
