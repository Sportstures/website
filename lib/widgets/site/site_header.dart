import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'photo_background.dart';
import 'site_routes.dart';
import 'site_scaffold.dart';

class SiteHeader extends StatelessWidget {
  const SiteHeader({super.key, required this.currentRoute});

  /// Below this width the nav links move into the drawer.
  static const compactBreakpoint = 1100.0;

  final String currentRoute;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < compactBreakpoint;

    return Container(
      height: 72,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: ContentWidth(
        child: Row(
          children: [
            const SiteLogo(),
            const Spacer(),
            if (compact)
              IconButton(
                tooltip: 'Menu',
                icon: const Icon(Icons.menu, color: AppColors.ink),
                onPressed: () => Scaffold.of(context).openEndDrawer(),
              )
            else ...[
              for (final item in siteNavItems)
                _NavLink(item: item, active: item.route == currentRoute),
              const SizedBox(width: 16),
              const _AuthButtons(),
            ],
          ],
        ),
      ),
    );
  }
}

class SiteDrawer extends StatelessWidget {
  const SiteDrawer({super.key, required this.currentRoute});

  final String currentRoute;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Align(alignment: Alignment.centerLeft, child: SiteLogo()),
            const Divider(height: 32),
            for (final item in siteNavItems)
              ListTile(
                title: Text(item.label),
                selected: item.route == currentRoute,
                selectedColor: AppColors.green,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                onTap: () {
                  Navigator.of(context).pop();
                  openSiteRoute(context, item.route);
                },
              ),
            const SizedBox(height: 16),
            const _AuthButtons(),
          ],
        ),
      ),
    );
  }
}

class SiteLogo extends StatelessWidget {
  const SiteLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => openSiteRoute(context, SiteRoutes.home),
      borderRadius: BorderRadius.circular(6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            SiteImages.logo,
            height: 44,
            errorBuilder: (_, _, _) => const SizedBox(height: 44),
          ),
          const SizedBox(width: 8),
          const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SPORTSTURES',
                style: TextStyle(
                  color: AppColors.green,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                'HOME OF SPORTS FIXTURES',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NavLink extends StatelessWidget {
  const _NavLink({required this.item, required this.active});

  final NavItem item;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => openSiteRoute(context, item.route),
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              item.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active ? AppColors.green : AppColors.ink,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              height: 2,
              width: 20,
              color: active ? AppColors.green : Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthButtons extends StatelessWidget {
  const _AuthButtons();

  @override
  Widget build(BuildContext context) {
    const shape = StadiumBorder();
    const padding = EdgeInsets.symmetric(horizontal: 18);
    const textStyle = TextStyle(fontSize: 12, fontWeight: FontWeight.w700);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilledButton(
          onPressed: () => openSiteRoute(context, SiteRoutes.login),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.green,
            shape: shape,
            padding: padding,
            minimumSize: const Size(0, 36),
            textStyle: textStyle,
          ),
          child: const Text('LOGIN'),
        ),
        OutlinedButton(
          onPressed: () => openSiteRoute(context, SiteRoutes.signup),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.ink,
            side: const BorderSide(color: AppColors.ink),
            shape: shape,
            padding: padding,
            minimumSize: const Size(0, 36),
            textStyle: textStyle,
          ),
          child: const Text('Register School'),
        ),
      ],
    );
  }
}
