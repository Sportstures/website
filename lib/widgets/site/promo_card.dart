import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'photo_background.dart';
import 'site_routes.dart';
import 'ui_kit.dart';

/// Dark "Add your school" card that sends visitors to sign-up.
class PromoCard extends StatelessWidget {
  const PromoCard({
    super.key,
    this.eyebrow = 'GET MORE VISIBILITY',
    this.title = 'ADD YOUR SCHOOL',
    this.body = 'Register your school and get access to powerful tools, fixture '
        'management and performance insights.',
    this.buttonLabel = 'REGISTER SCHOOL',
    this.compact = false,
  });

  final String eyebrow;
  final String title;
  final String body;
  final String buttonLabel;

  /// Smaller title for tight spots like a grid cell.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: PhotoBackground(
        asset: SiteImages.promoBall,
        fallback: Stack(
          children: [
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0B1220), Color(0xFF0F3A20)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            Positioned(
              right: -30,
              bottom: -30,
              child: Icon(
                Icons.sports_soccer,
                size: 160,
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
          ],
        ),
        overlay: const LinearGradient(
          colors: [Color(0xCC000000), Color(0x33000000)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.orange,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: compact ? 19 : 24,
                  fontWeight: FontWeight.w900,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                body,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              SiteButton(
                label: buttonLabel,
                variant: SiteButtonVariant.orange,
                small: true,
                onPressed: () => openSiteRoute(context, SiteRoutes.signup),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
