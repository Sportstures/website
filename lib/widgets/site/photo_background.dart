import 'package:flutter/material.dart';

abstract final class SiteImages {
  static const logo = 'assets/images/logo.png';

  // Photos from the design. Export them into assets/images/ with these exact
  // names and they appear automatically; until then each section falls back to
  // a gradient.
  static const heroPlayers = 'assets/images/hero_players.jpg';
  static const ctaCrowd = 'assets/images/cta_crowd.png';
  static const appSection = 'assets/images/app_section.jpg';
  static const appPhones = 'assets/images/app_phones.png';
  static const promoBall = 'assets/images/promo_ball.jpg';
  static const contactMap = 'assets/images/contact_map.png';
}

/// Lays [child] over a cover photo, drawing [fallback] while the photo is
/// missing or loading.
class PhotoBackground extends StatelessWidget {
  const PhotoBackground({
    super.key,
    required this.asset,
    required this.fallback,
    required this.child,
    this.overlay,
    this.alignment = Alignment.center,
  });

  final String asset;
  final Widget fallback;
  final Widget child;

  /// Darkening layer between the photo and [child], for text contrast.
  final Gradient? overlay;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: fallback),
        Positioned.fill(
          child: Image.asset(
            asset,
            fit: BoxFit.cover,
            alignment: alignment,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
        ),
        if (overlay != null)
          Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: overlay))),
        child,
      ],
    );
  }
}

/// Dark hero backdrop used until the players photo is exported.
class HeroFallback extends StatelessWidget {
  const HeroFallback({super.key});

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF05080C), Color(0xFF0B2A18), Color(0xFF102F5C)],
          stops: [0.0, 0.6, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }
}

const heroTextOverlay = LinearGradient(
  colors: [Color(0xE6000000), Color(0x59000000)],
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
);
