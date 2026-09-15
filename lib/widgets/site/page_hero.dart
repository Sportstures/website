import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'photo_background.dart';
import 'site_routes.dart';
import 'site_scaffold.dart';

/// Photo banner with title (and optional breadcrumb) at the top of inner pages.
class PageHero extends StatelessWidget {
  const PageHero({
    super.key,
    required this.title,
    required this.subtitle,
    this.breadcrumb,
    this.trailing,
  });

  final String title;
  final String subtitle;

  /// Current page name shown after "Home >". Hidden when null.
  final String? breadcrumb;

  /// Shown on the right on wide screens, e.g. the crest on Contact Us.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 600;

    return PhotoBackground(
      asset: SiteImages.heroPlayers,
      fallback: const HeroFallback(),
      overlay: heroTextOverlay,
      child: Container(
        constraints: BoxConstraints(minHeight: compact ? 220 : 260),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: ContentWidth(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.toUpperCase(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: compact ? 32 : 40,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                        height: 1.1,
                      ),
                    ),
                    if (breadcrumb != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          InkWell(
                            onTap: () => openSiteRoute(context, SiteRoutes.home),
                            child: Text(
                              'Home',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
                            ),
                          ),
                          Icon(Icons.chevron_right, size: 16, color: Colors.white.withValues(alpha: 0.5)),
                          Text(
                            breadcrumb!,
                            style: const TextStyle(
                              color: AppColors.orange,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 18),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: Text(
                        subtitle,
                        style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null && !compact) ...[const SizedBox(width: 24), trailing!],
            ],
          ),
        ),
      ),
    );
  }
}
