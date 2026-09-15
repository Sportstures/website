import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../widgets/site/photo_background.dart';
import '../../../widgets/site/site_routes.dart';
import '../../../widgets/site/site_scaffold.dart';
import '../../../widgets/site/ui_kit.dart';

/// Orange "Ready to get your school involved?" banner.
class CtaBanner extends StatelessWidget {
  const CtaBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return PhotoBackground(
      asset: SiteImages.ctaCrowd,
      alignment: Alignment.bottomCenter,
      fallback: const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.orange, Color(0xFFE08A00)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      child: ContentWidth(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 36),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final copy = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'READY TO GET YOUR SCHOOL INVOLVED?',
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Be part of a community that brings schools together through sport.',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14),
                  ),
                ],
              );
              final button = SiteButton(
                label: 'Register School Now',
                onPressed: () => openSiteRoute(context, SiteRoutes.signup),
              );

              if (constraints.maxWidth >= 760) {
                return Row(children: [Expanded(child: copy), const SizedBox(width: 24), button]);
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [copy, const SizedBox(height: 16), button],
              );
            },
          ),
        ),
      ),
    );
  }
}
