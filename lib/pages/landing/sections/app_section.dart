import 'package:flutter/material.dart';

import '../../../config/site_links.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/site/photo_background.dart';
import '../../../widgets/site/site_scaffold.dart';

/// "Sportstures App" download section.
class AppSection extends StatelessWidget {
  const AppSection({super.key});

  static const _appFeatures = ['Fixtures', 'Match results', 'Standings & Rankings'];

  @override
  Widget build(BuildContext context) {
    return PhotoBackground(
      asset: SiteImages.appSection,
      fallback: const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF07140C), Color(0xFF123D22)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      // Darker on the right so the copy stays legible over the lit ball.
      overlay: const LinearGradient(colors: [Color(0x66000000), Color(0xA6000000)]),
      child: ContentWidth(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 56),
          child: LayoutBuilder(
            builder: (context, constraints) {
              const phones = _AppPhones();

              final copy = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sportstures App',
                    style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 16),
                  for (final feature in _appFeatures)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(color: AppColors.orange, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            feature,
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),
                  const Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _StoreButton(
                        icon: Icons.apple,
                        caption: 'Download App On',
                        store: 'APP STORE',
                        url: SiteLinks.appStore,
                      ),
                      _StoreButton(
                        icon: Icons.play_arrow_rounded,
                        caption: 'Get The App On',
                        store: 'GOOGLE PLAY STORE',
                        url: SiteLinks.playStore,
                      ),
                    ],
                  ),
                ],
              );

              if (constraints.maxWidth >= 760) {
                return Row(
                  children: [
                    Expanded(child: Center(child: phones)),
                    const SizedBox(width: 40),
                    Expanded(child: copy),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [Center(child: phones), const SizedBox(height: 32), copy],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Store badge. Opens the listing once there is one; until then it says the
/// app is on its way, which is true, instead of looking like a broken button.
class _StoreButton extends StatelessWidget {
  const _StoreButton({
    required this.icon,
    required this.caption,
    required this.store,
    required this.url,
  });

  final IconData icon;
  final String caption;
  final String store;
  final String? url;

  @override
  Widget build(BuildContext context) {
    final live = SiteLinks.has(url);

    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(color: Colors.white.withValues(alpha: live ? 0.4 : 0.22)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: live ? 1 : 0.65), size: 26),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                live ? caption : 'Coming soon to',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: live ? 0.7 : 0.55),
                  fontSize: 9,
                ),
              ),
              Text(
                store,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: live ? 1 : 0.65),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (!live) return Semantics(label: '$store: coming soon', child: badge);

    return InkWell(
      onTap: () => openExternal(context, Uri.parse(url!)),
      borderRadius: BorderRadius.circular(8),
      child: badge,
    );
  }
}

/// The two app screenshots from the design, overlapping like the mockup.
class _AppPhones extends StatelessWidget {
  const _AppPhones();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      height: 352,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 38,
            child: Image.asset(
              SiteImages.appPhoneFront,
              height: 264,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            child: Image.asset(
              SiteImages.appPhoneAngled,
              height: 340,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}
