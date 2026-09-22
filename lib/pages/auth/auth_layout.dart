import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../widgets/site/photo_background.dart';
import '../../widgets/site/site_header.dart';

/// Full-page login / sign-up frame: site nav on top, brand panel filling the
/// left, and a scrolling form beside it.
class AuthLayout extends StatelessWidget {
  const AuthLayout({
    super.key,
    required this.panel,
    required this.form,
    this.formMaxWidth = 460,
  });

  final Widget panel;
  final Widget form;
  final double formMaxWidth;

  /// Below this width the panel becomes a banner above the form.
  static const _splitBreakpoint = 900.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      endDrawer: const SiteDrawer(currentRoute: ''),
      body: Column(
        children: [
          const SiteHeader(currentRoute: ''),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth >= _splitBreakpoint) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: 5, child: panel),
                      Expanded(flex: 7, child: _FormArea(maxWidth: formMaxWidth, child: form)),
                    ],
                  );
                }
                // On narrow screens the brand panel would squash, so the form
                // gets the full width; the nav bar still carries the logo.
                return _FormArea(maxWidth: formMaxWidth, child: form);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FormArea extends StatelessWidget {
  const _FormArea({required this.maxWidth, required this.child});

  final double maxWidth;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final padding = EdgeInsets.symmetric(
      horizontal: MediaQuery.sizeOf(context).width < 600 ? 20 : 40,
      vertical: 40,
    );
    final content = Center(
      child: ConstrainedBox(constraints: BoxConstraints(maxWidth: maxWidth), child: child),
    );

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: padding,
        // Centre short forms; taller ones scroll.
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight - padding.vertical),
          child: Center(child: content),
        ),
      ),
    );
  }
}

/// Green panel beside the auth forms: crest top-left, [child] centred,
/// copyright at the bottom.
class AuthBrandPanel extends StatelessWidget {
  const AuthBrandPanel({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      // TODO: add the faint players photo from the design once there is a clean
      // export. stadium_bg.png has the login panel's text baked into it.
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F3D20), Color(0xFF052313)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(36, 28, 36, 24),
      child: Stack(
        children: [
          const Align(alignment: Alignment.topLeft, child: _PanelLogo()),
          Align(
            alignment: Alignment.centerLeft,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(top: 72, bottom: 40),
              child: child,
            ),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Text(
              '© ${DateTime.now().year} Sportstures. All rights reserved.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelLogo extends StatelessWidget {
  const _PanelLogo();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          SiteImages.logo,
          height: 40,
          errorBuilder: (_, _, _) => const SizedBox(height: 40),
        ),
        const SizedBox(width: 10),
        const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sportstures',
              style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
            ),
            Text(
              'HOME OF SPORTS FIXTURES',
              style: TextStyle(
                color: AppColors.orange,
                fontSize: 8,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
