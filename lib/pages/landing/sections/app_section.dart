import 'package:flutter/material.dart';

import '../../../data/sports_data.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/site/photo_background.dart';
import '../../../widgets/site/site_routes.dart';
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
      overlay: const LinearGradient(colors: [Color(0x59000000), Color(0x59000000)]),
      child: ContentWidth(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 56),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final phones = Image.asset(
                SiteImages.appPhones,
                height: 320,
                errorBuilder: (_, _, _) => const _PhoneMockups(),
              );

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
                      _StoreButton(icon: Icons.apple, caption: 'Download App On', store: 'APP STORE'),
                      _StoreButton(
                        icon: Icons.play_arrow_rounded,
                        caption: 'Get The App On',
                        store: 'GOOGLE PLAY STORE',
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

class _StoreButton extends StatelessWidget {
  const _StoreButton({required this.icon, required this.caption, required this.store});

  final IconData icon;
  final String caption;
  final String store;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      // TODO: link to the App Store / Google Play listings once published
      onTap: () => openSiteRoute(context, null),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black,
          border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 26),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(caption, style: const TextStyle(color: Colors.white70, fontSize: 9)),
                Text(
                  store,
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Drawn stand-in for the phone screenshots until the image is exported.
class _PhoneMockups extends StatelessWidget {
  const _PhoneMockups();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 300,
      height: 320,
      child: Stack(
        children: [
          Positioned(left: 10, top: 24, child: _Phone(angle: -0.12, firstSchool: 0)),
          Positioned(right: 10, top: 0, child: _Phone(angle: 0.08, firstSchool: 4)),
        ],
      ),
    );
  }
}

class _Phone extends StatelessWidget {
  const _Phone({required this.angle, required this.firstSchool});

  final double angle;
  final int firstSchool;

  @override
  Widget build(BuildContext context) {
    final schools = SportsData.schools;

    return Transform.rotate(
      angle: angle,
      child: Container(
        width: 140,
        height: 280,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(26),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 20)],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: ColoredBox(
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  color: AppColors.green,
                  padding: const EdgeInsets.fromLTRB(10, 18, 10, 10),
                  child: const Text(
                    'Sportstures',
                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      for (var i = 0; i < 5; i++)
                        Container(
                          height: 30,
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              _dot(schools[(firstSchool + i * 2) % schools.length].color),
                              Expanded(
                                child: Container(
                                  height: 5,
                                  margin: const EdgeInsets.symmetric(horizontal: 6),
                                  color: AppColors.border,
                                ),
                              ),
                              _dot(schools[(firstSchool + i * 2 + 1) % schools.length].color),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _dot(Color color) => Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}
