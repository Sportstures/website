import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../widgets/site/site_scaffold.dart';
import '../../../widgets/site/ui_kit.dart';

class FeaturesSection extends StatelessWidget {
  const FeaturesSection({super.key});

  static const _features = [
    (Icons.calendar_month_outlined, 'Fixtures', 'Create, edit and manage all your school sport fixtures.'),
    (Icons.emoji_events_outlined, 'Live Scores', 'Update scores in real time and keep everyone informed.'),
    (Icons.bar_chart_rounded, 'Standings', 'Automatic standings and grouping by performance.'),
    (Icons.location_on_outlined, 'Regional Rankings', 'Compete against schools in your region for the top spot.'),
    (Icons.groups_outlined, 'Player Stats', 'Track goals, tries, points and player performance.'),
    (Icons.verified_user_outlined, 'Secure & Reliable', 'Trusted by schools across South Africa. Always secure.'),
  ];

  @override
  Widget build(BuildContext context) {
    return ContentWidth(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            const SectionEyebrow('Everything your school needs'),
            const SizedBox(height: 28),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 960
                    ? 6
                    : constraints.maxWidth >= 560
                        ? 3
                        : 2;
                const gap = 12.0;
                final tileWidth = (constraints.maxWidth - gap * (columns - 1)) / columns;

                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (final (icon, title, description) in _features)
                      SizedBox(
                        width: tileWidth,
                        height: 200,
                        child: _FeatureTile(icon: icon, title: title, description: description),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({required this.icon, required this.title, required this.description});

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: AppColors.ink),
          const SizedBox(height: 14),
          Text(
            title.toUpperCase(),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.ink),
          ),
          const SizedBox(height: 8),
          // The tile is a fixed height, so cap the copy rather than let it run
          // past the bottom. At the sizes these render at nothing is clipped.
          Flexible(
            child: Text(
              description,
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: AppColors.muted, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
