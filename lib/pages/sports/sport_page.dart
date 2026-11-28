import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../data/sports_data.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';
import '../../widgets/site/ai_picks_card.dart';
import '../../widgets/site/ai_summary_cards.dart';
import '../../widgets/site/match_rows.dart';
import '../../widgets/site/match_data_builder.dart';
import '../../widgets/site/page_hero.dart';
import '../../widgets/site/promo_card.dart';
import '../../widgets/site/site_routes.dart';
import '../../widgets/site/site_scaffold.dart';
import '../../widgets/site/ui_kit.dart';

/// Everything happening in one sport: what is coming up, what has just been
/// played, and where the table stands.
///
/// Reached from the footer's sports list and from the sports index. The sport
/// arrives as the route argument; without one it falls back to football rather
/// than showing an empty page.
class SportPage extends StatelessWidget {
  const SportPage({super.key, this.sport});

  final Sport? sport;

  @override
  Widget build(BuildContext context) {
    final requested = ModalRoute.of(context)?.settings.arguments;
    final chosen = sport ?? (requested is Sport ? requested : Sport.football);

    return MatchDataBuilder(
      currentRoute: SiteRoutes.sports,
      title: chosen.label,
      subtitle: 'Fixtures, results and tables.',
      builder: (context, data) => _page(context, data, chosen),
    );
  }

  Widget _page(BuildContext context, SportsData data, Sport chosen) {
    final fixtures =
        data.fixtures.where((f) => f.sport == chosen).toList(growable: false);
    final results =
        data.results.where((r) => r.fixture.sport == chosen).toList(growable: false);
    final standings = SportsData.standingsFor(results);
    final schools =
        data.allSchools.where((s) => s.sports.contains(chosen)).toList(growable: false);

    return SiteScaffold(
      currentRoute: SiteRoutes.sports,
      children: [
        PageHero(
          title: chosen.label,
          breadcrumb: chosen.label,
          subtitle: '${schools.length} schools play ${chosen.label.toLowerCase()} on Sportstures. '
              'Follow every fixture, result and table in one place.',
          trailing: Icon(chosen.icon, size: 72, color: Colors.white.withValues(alpha: 0.25)),
        ),
        ContentWidth(
          child: Padding(
            padding: const EdgeInsets.only(top: 28, bottom: 56),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                StatsBand(
                  valueColor: AppColors.orange,
                  stats: [
                    (chosen.icon, '${schools.length}', 'Schools playing'),
                    (Icons.event_outlined, '${fixtures.length}', 'Fixtures to come'),
                    (Icons.scoreboard_outlined, '${results.length}', 'Matches played'),
                    (
                      Icons.sports_score,
                      formatThousands(
                        results.fold(0, (sum, r) => sum + r.homeScore + r.awayScore),
                      ),
                      chosen.scoreLabel,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                TwoColumnLayout(
                  main: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _UpcomingCard(sport: chosen, fixtures: fixtures),
                      const SizedBox(height: 16),
                      _RecentCard(sport: chosen, results: results),
                      const SizedBox(height: 16),
                      _TableCard(sport: chosen, standings: standings),
                    ],
                  ),
                  sidebar: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AiStandingsReadCard(standings: standings, sport: chosen),
                      const SizedBox(height: 16),
                      AiPicksCard(fixtures: fixtures),
                      const SizedBox(height: 16),
                      _OtherSportsCard(current: chosen),
                      const SizedBox(height: 16),
                      const PromoCard(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _UpcomingCard extends StatelessWidget {
  const _UpcomingCard({required this.sport, required this.fixtures});

  final Sport sport;
  final List<Fixture> fixtures;

  @override
  Widget build(BuildContext context) {
    final shown = fixtures.take(6).toList(growable: false);

    return SectionCard(
      title: 'Upcoming ${sport.label.toLowerCase()}',
      trailing: CardLink(
        label: 'All fixtures',
        onTap: () => openSiteRoute(context, SiteRoutes.fixtures),
      ),
      child: shown.isEmpty
          ? EmptyState('No ${sport.label.toLowerCase()} fixtures are scheduled yet.')
          : DividedColumn(
              children: [for (final fixture in shown) FixtureRow(fixture: fixture)],
            ),
    );
  }
}

class _RecentCard extends StatelessWidget {
  const _RecentCard({required this.sport, required this.results});

  final Sport sport;
  final List<MatchResult> results;

  @override
  Widget build(BuildContext context) {
    final shown = results.take(6).toList(growable: false);

    return SectionCard(
      title: 'Latest results',
      trailing: CardLink(
        label: 'All results',
        onTap: () => openSiteRoute(context, SiteRoutes.results),
      ),
      child: shown.isEmpty
          ? EmptyState('No ${sport.label.toLowerCase()} has been played yet.')
          : DividedColumn(
              children: [for (final result in shown) ResultRow(result: result)],
            ),
    );
  }
}

class _TableCard extends StatelessWidget {
  const _TableCard({required this.sport, required this.standings});

  final Sport sport;
  final List<SchoolStanding> standings;

  @override
  Widget build(BuildContext context) {
    final shown = standings.take(8).toList(growable: false);

    return SectionCard(
      title: '${sport.label} table',
      trailing: CardLink(
        label: 'Full standings',
        onTap: () => openSiteRoute(context, SiteRoutes.standings),
      ),
      padding: EdgeInsets.zero,
      child: shown.isEmpty
          ? EmptyState('The table fills in once matches are played.')
          : SiteTable(
              columns: const [
                SiteTableColumn('#', width: 36),
                SiteTableColumn('School', alignment: Alignment.centerLeft),
                SiteTableColumn('P', width: 40),
                SiteTableColumn('W', width: 40, hideOnNarrow: true),
                SiteTableColumn('D', width: 40, hideOnNarrow: true),
                SiteTableColumn('L', width: 40, hideOnNarrow: true),
                SiteTableColumn('PTS', width: 48),
              ],
              rows: [
                for (final (index, standing) in shown.indexed)
                  [
                    Text('${index + 1}', style: tableCellStyle),
                    SchoolCell(school: standing.school),
                    Text('${standing.played}', style: tableCellStyle),
                    Text('${standing.won}', style: tableCellStyle),
                    Text('${standing.drawn}', style: tableCellStyle),
                    Text('${standing.lost}', style: tableCellStyle),
                    Text('${standing.points}', style: tableStrongStyle),
                  ],
              ],
            ),
    );
  }
}

class _OtherSportsCard extends StatelessWidget {
  const _OtherSportsCard({required this.current});

  final Sport current;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Other sports',
      trailing: CardLink(
        label: 'All sports',
        onTap: () => openSiteRoute(context, SiteRoutes.sports),
      ),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          for (final sport in Sport.values.where((s) => s != current))
            InkWell(
              onTap: () => openSiteRoute(context, SiteRoutes.sport, arguments: sport),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    Icon(sport.icon, size: 16, color: AppColors.green),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        sport.label,
                        style: const TextStyle(fontSize: 12, color: AppColors.ink),
                      ),
                    ),
                    const Icon(Icons.chevron_right, size: 16, color: AppColors.muted),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
