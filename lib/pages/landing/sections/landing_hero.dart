import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../widgets/site/photo_background.dart';
import '../../../widgets/site/site_routes.dart';
import '../../../widgets/site/site_scaffold.dart';
import '../../../widgets/site/ui_kit.dart';

class LandingHero extends StatelessWidget {
  const LandingHero({super.key});

  static const _highlights = ['Match fixtures', 'Track results', 'View Standings'];

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 600;

    return PhotoBackground(
      asset: SiteImages.heroPlayers,
      fallback: const HeroFallback(),
      overlay: heroTextOverlay,
      child: ContentWidth(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: compact ? 48 : 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: compact ? 38 : 56,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                  ),
                  children: const [
                    TextSpan(text: 'THE HOME OF\n'),
                    TextSpan(
                      text: 'SCHOOL SPORTS\n',
                      style: TextStyle(color: AppColors.greenBright),
                    ),
                    TextSpan(text: 'FIXTURES.'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 20,
                runSpacing: 8,
                children: [
                  for (final label in _highlights)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle, size: 16, color: AppColors.greenBright),
                        const SizedBox(width: 6),
                        Text(label, style: const TextStyle(color: Colors.white, fontSize: 13)),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 32),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SiteButton(
                    label: 'Register School Now',
                    onPressed: () => openSiteRoute(context, SiteRoutes.signup),
                  ),
                  SiteButton(
                    label: 'View Fixtures',
                    icon: Icons.calendar_month_outlined,
                    variant: SiteButtonVariant.outlineLight,
                    onPressed: () => openSiteRoute(context, SiteRoutes.fixtures),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
