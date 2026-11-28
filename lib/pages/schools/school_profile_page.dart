import 'package:flutter/material.dart';

import '../../ai/ai_provider.dart';
import '../../ai/ai_service.dart';
import '../../data/match_store.dart';
import '../../data/models.dart';
import '../../data/sports_data.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';
import '../../widgets/site/match_rows.dart';
import '../../widgets/site/page_hero.dart';
import '../../widgets/site/promo_card.dart';
import '../../widgets/site/site_routes.dart';
import '../../widgets/site/site_scaffold.dart';
import '../../widgets/site/ui_kit.dart';
import 'live_school_profile_view.dart';

/// One school's record: who they are, what they play, how they are going.
///
/// The school arrives as the route argument; without one it falls back to the
/// first registered school rather than showing an empty page.
class SchoolProfilePage extends StatelessWidget {
  const SchoolProfilePage({super.key, this.school});

  final School? school;

  @override
  Widget build(BuildContext context) {
    final requested = ModalRoute.of(context)?.settings.arguments;

    // With a backend the page is `/school?id=<id>`; a School passed along is looked up by its name.
    final api = MatchScope.maybeOf(context)?.api;
    if (api != null) {
      final id = int.tryParse(Uri.tryParse(ModalRoute.of(context)?.settings.name ?? '')?.queryParameters['id'] ?? '');
      final name = school?.name ?? (requested is School ? requested.name : null);
      return LiveSchoolProfileView(key: ValueKey((id, name)), api: api, schoolId: id, schoolName: name);
    }

    final chosen = school ?? (requested is School ? requested : SportsData.schools.first);

    final data = SportsData.instance;
    final fixtures = data.fixtures
        .where((f) => f.home == chosen || f.away == chosen)
        .toList(growable: false);
    final results = data.results
        .where((r) => r.fixture.home == chosen || r.fixture.away == chosen)
        .toList(growable: false);

    var won = 0;
    var drawn = 0;
    for (final result in results) {
      final forScore = result.fixture.home == chosen ? result.homeScore : result.awayScore;
      final against = result.fixture.home == chosen ? result.awayScore : result.homeScore;
      if (forScore > against) {
        won++;
      } else if (forScore == against) {
        drawn++;
      }
    }

    return SiteScaffold(
      currentRoute: SiteRoutes.schools,
      children: [
        PageHero(
          title: chosen.name,
          breadcrumb: chosen.name,
          subtitle: '${chosen.type.label} school in ${chosen.location}, competing in '
              '${chosen.region}.',
          trailing: TeamCrest(school: chosen, size: 76),
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
                    (Icons.groups_outlined, formatThousands(chosen.athletes), 'Student athletes'),
                    (Icons.sports, '${chosen.sports.length}', 'Sports played'),
                    (Icons.scoreboard_outlined, '${results.length}', 'Matches played'),
                    (Icons.emoji_events_outlined, '$won', 'Wins'),
                  ],
                ),
                const SizedBox(height: 24),
                TwoColumnLayout(
                  main: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SportsCard(school: chosen),
                      const SizedBox(height: 16),
                      _FixturesCard(school: chosen, fixtures: fixtures),
                      const SizedBox(height: 16),
                      _ResultsCard(school: chosen, results: results),
                    ],
                  ),
                  sidebar: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _RecordCard(
                        played: results.length,
                        won: won,
                        drawn: drawn,
                        lost: results.length - won - drawn,
                      ),
                      const SizedBox(height: 16),
                      _AiFormCard(school: chosen, results: results),
                      const SizedBox(height: 16),
                      _DetailsCard(school: chosen),
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

class _SportsCard extends StatelessWidget {
  const _SportsCard({required this.school});

  final School school;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Sports played',
      trailing: CountLabel(count: school.sports.length, noun: 'sport'),
      padding: const EdgeInsets.all(14),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final sport in school.sports)
            InkWell(
              onTap: () => openSiteRoute(context, SiteRoutes.sport, arguments: sport),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(sport.icon, size: 14, color: AppColors.green),
                    const SizedBox(width: 7),
                    Text(
                      sport.label,
                      style: const TextStyle(fontSize: 12, color: AppColors.ink),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FixturesCard extends StatelessWidget {
  const _FixturesCard({required this.school, required this.fixtures});

  final School school;
  final List<Fixture> fixtures;

  @override
  Widget build(BuildContext context) {
    final shown = fixtures.take(5).toList(growable: false);

    return SectionCard(
      title: 'Upcoming fixtures',
      trailing: CardLink(
        label: 'All fixtures',
        onTap: () => openSiteRoute(context, SiteRoutes.fixtures),
      ),
      child: shown.isEmpty
          ? EmptyState('${school.name} have nothing scheduled right now.')
          : DividedColumn(
              children: [for (final fixture in shown) FixtureRow(fixture: fixture)],
            ),
    );
  }
}

class _ResultsCard extends StatelessWidget {
  const _ResultsCard({required this.school, required this.results});

  final School school;
  final List<MatchResult> results;

  @override
  Widget build(BuildContext context) {
    final shown = results.take(6).toList(growable: false);

    return SectionCard(
      title: 'Recent results',
      trailing: CardLink(
        label: 'All results',
        onTap: () => openSiteRoute(context, SiteRoutes.results),
      ),
      child: shown.isEmpty
          ? EmptyState('${school.name} have not played yet.')
          : DividedColumn(
              children: [for (final result in shown) ResultRow(result: result)],
            ),
    );
  }
}

class _RecordCard extends StatelessWidget {
  const _RecordCard({
    required this.played,
    required this.won,
    required this.drawn,
    required this.lost,
  });

  final int played;
  final int won;
  final int drawn;
  final int lost;

  @override
  Widget build(BuildContext context) {
    final tiles = [
      ('Played', played, AppColors.ink),
      ('Won', won, AppColors.green),
      ('Drawn', drawn, AppColors.muted),
      ('Lost', lost, const Color(0xFFDC2626)),
    ];

    return SectionCard(
      title: 'Season record',
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          for (final (label, value, color) in tiles)
            Expanded(
              child: Column(
                children: [
                  Text(
                    '$value',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color),
                  ),
                  const SizedBox(height: 2),
                  Text(label, style: const TextStyle(fontSize: 10, color: AppColors.muted)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// The AI recap, narrowed to this school's own matches.
class _AiFormCard extends StatefulWidget {
  const _AiFormCard({required this.school, required this.results});

  final School school;
  final List<MatchResult> results;

  @override
  State<_AiFormCard> createState() => _AiFormCardState();
}

class _AiFormCardState extends State<_AiFormCard> {
  late Future<AiSummary> _summary = aiService.summarizeResults(widget.results);

  @override
  void didUpdateWidget(_AiFormCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.school != widget.school) {
      _summary = aiService.summarizeResults(widget.results);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'AI read',
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: FutureBuilder<AiSummary>(
        future: _summary,
        builder: (context, snapshot) {
          final summary = snapshot.data;
          if (summary == null || summary.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text(
                '${widget.school.name} have not played enough for a read yet.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, color: AppColors.muted, height: 1.4),
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.auto_awesome, size: 14, color: AppColors.green),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      summary.headline,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              for (final insight in summary.insights.take(3))
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(insight.icon, size: 12, color: AppColors.muted),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          insight.headline,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.ink,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.school});

  final School school;

  @override
  Widget build(BuildContext context) {
    final rows = [
      (Icons.location_on_outlined, 'Location', school.location),
      (Icons.map_outlined, 'Region', school.region),
      (Icons.account_balance_outlined, 'Type', school.type.label),
      (Icons.groups_outlined, 'Athletes', formatThousands(school.athletes)),
      (
        Icons.calendar_today_outlined,
        'On Sportstures',
        '${(school.joinedDaysAgo / 30).round()} months',
      ),
    ];

    return SectionCard(
      title: 'School details',
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: DividedColumn(
        children: [
          for (final (icon, label, value) in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Icon(icon, size: 14, color: AppColors.muted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(fontSize: 11, color: AppColors.muted),
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
