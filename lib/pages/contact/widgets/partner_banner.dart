import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../widgets/site/site_routes.dart';
import '../../../widgets/site/ui_kit.dart';

/// "Partner with us" / "Join the movement" split banner.
class PartnerBanner extends StatelessWidget {
  const PartnerBanner({super.key, required this.onLearnMore});

  final VoidCallback onLearnMore;

  @override
  Widget build(BuildContext context) {
    final partner = _BannerHalf(
      background: const Color(0xFF1B1B1B),
      icon: Icons.handshake_outlined,
      iconColor: Colors.white24,
      eyebrow: 'Partner with us',
      eyebrowColor: AppColors.orange,
      text: 'We welcome partnerships that help grow school sports and create opportunities for young athletes.',
      textColor: Colors.white,
      button: SiteButton(
        label: 'LEARN MORE',
        trailingIcon: Icons.arrow_forward,
        variant: SiteButtonVariant.outlineOrange,
        small: true,
        onPressed: onLearnMore,
      ),
    );

    final join = _BannerHalf(
      background: AppColors.orange,
      icon: Icons.emoji_events,
      iconColor: AppColors.ink,
      eyebrow: 'Join the movement',
      eyebrowColor: AppColors.ink,
      text: "Register your school today and be part of South Africa's leading school sports network.",
      textColor: AppColors.ink,
      button: SiteButton(
        label: 'REGISTER YOUR SCHOOL',
        trailingIcon: Icons.arrow_forward,
        variant: SiteButtonVariant.dark,
        small: true,
        onPressed: () => openSiteRoute(context, SiteRoutes.signup),
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 760) {
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [Expanded(child: partner), Expanded(child: join)],
              ),
            );
          }
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [partner, join]);
        },
      ),
    );
  }
}

class _BannerHalf extends StatelessWidget {
  const _BannerHalf({
    required this.background,
    required this.icon,
    required this.iconColor,
    required this.eyebrow,
    required this.eyebrowColor,
    required this.text,
    required this.textColor,
    required this.button,
  });

  final Color background;
  final IconData icon;
  final Color iconColor;
  final String eyebrow;
  final Color eyebrowColor;
  final String text;
  final Color textColor;
  final Widget button;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: background,
      padding: const EdgeInsets.all(28),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 44, color: iconColor),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Eyebrow(eyebrow, color: eyebrowColor),
                const SizedBox(height: 10),
                Text(
                  text,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textColor, height: 1.5),
                ),
                const SizedBox(height: 18),
                button,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
