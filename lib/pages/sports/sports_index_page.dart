import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../data/sports_data.dart';
import '../../theme/app_colors.dart';
import '../../widgets/site/match_data_builder.dart';
import '../../widgets/site/page_hero.dart';
import '../../widgets/site/promo_card.dart';
import '../../widgets/site/site_routes.dart';
import '../../widgets/site/site_scaffold.dart';
import '../../widgets/site/ui_kit.dart';

/// Every sport on the platform, with how busy each one is.
class SportsIndexPage extends StatelessWidget {
  const SportsIndexPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MatchDataBuilder(
      currentRoute: SiteRoutes.sports,
      title: 'Sports',
      subtitle: 'Every sport played across the Sportstures network.',
      builder: _page,
    );
  }

  Widget _page(BuildContext context, SportsData data) {
    return SiteScaffold(
      currentRoute: SiteRoutes.sports,
      children: [
        const PageHero(
          title: 'Sports',
          breadcrumb: 'Sports',
          subtitle: 'Every sport played across the Sportstures network. Pick one to follow its '
              'fixtures, results and tables.',
        ),
        ContentWidth(
          child: Padding(
            padding: const EdgeInsets.only(top: 28, bottom: 56),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionEyebrow('Choose a sport'),
                const SizedBox(height: 24),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 900
                        ? 4
                        : constraints.maxWidth >= 600
                            ? 3
                            : 2;
                    const gap = 16.0;
                    final width = (constraints.maxWidth - gap * (columns - 1)) / columns;

                    return Wrap(
                      spacing: gap,
                      runSpacing: gap,
                      children: [
                        for (final sport in Sport.values)
                          SizedBox(
                            width: width,
                            child: _SportTile(
                              sport: sport,
                              schools: data.allSchools
                                  .where((s) => s.sports.contains(sport))
                                  .length,
                              fixtures:
                                  data.fixtures.where((f) => f.sport == sport).length,
                              played: data.results
                                  .where((r) => r.fixture.sport == sport)
                                  .length,
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 40),
                const PromoCard(
                  eyebrow: 'Play something else?',
                  title: 'Add your sport',
                  body: 'Register your school and tell us which sports you field. We add new codes '
                      'as schools bring them.',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SportTile extends StatelessWidget {
  const _SportTile({
    required this.sport,
    required this.schools,
    required this.fixtures,
    required this.played,
  });

  final Sport sport;
  final int schools;
  final int fixtures;
  final int played;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => openSiteRoute(context, SiteRoutes.sport, arguments: sport),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.green.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(sport.icon, size: 22, color: AppColors.green),
            ),
            const SizedBox(height: 14),
            Text(
              sport.label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            _Stat(label: 'Schools', value: schools),
            _Stat(label: 'Upcoming', value: fixtures),
            _Stat(label: 'Played', value: played),
            const SizedBox(height: 12),
            const Row(
              children: [
                Text(
                  'VIEW',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: AppColors.green,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward, size: 12, color: AppColors.green),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
          ),
          Text(
            '$value',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}
