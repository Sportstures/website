import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../data/sports_data.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';
import '../../widgets/site/page_hero.dart';
import '../../widgets/site/platform_stats.dart';
import '../../widgets/site/site_routes.dart';
import '../../widgets/site/site_scaffold.dart';
import '../../widgets/site/ui_kit.dart';

/// What a school actually gets once it registers.
///
/// The footer points five separate links here - manage teams, create a match,
/// post results, manage fixtures, match history - because they are all parts of
/// the same set of tools rather than five destinations.
class ForSchoolsPage extends StatelessWidget {
  const ForSchoolsPage({super.key});

  static const _tools = [
    (
      Icons.groups_outlined,
      'Manage teams',
      'Set up every team your school fields, by sport and age group. Add squads, assign '
          'coaches and keep the roster current through the season.',
      ['Squad lists by sport and age group', 'Coach and manager accounts', 'Player profiles and numbers'],
    ),
    (
      Icons.add_circle_outline,
      'Create a match',
      'Arrange a fixture against any school on the platform. The other school is notified, '
          'confirms, and it appears on both calendars at once.',
      ['Invite any registered school', 'Agree venue, date and age group', 'Both calendars update together'],
    ),
    (
      Icons.edit_calendar_outlined,
      'Manage fixtures',
      'Move, postpone or cancel a fixture and everyone following it sees the change '
          'immediately - no phone calls, no out-of-date printouts.',
      ['Reschedule in a couple of clicks', 'Postponements flagged automatically', 'Season calendar in one view'],
    ),
    (
      Icons.scoreboard_outlined,
      'Post results',
      'Enter the score when the whistle goes. Tables, form guides and rankings update '
          'themselves from it.',
      ['Score entry from any device', 'Tables and rankings recalculate', 'Corrections tracked'],
    ),
    (
      Icons.history,
      'Match history',
      'Every match your school has played, searchable by sport, season and opponent, with '
          'the head-to-head record against anyone you meet.',
      ['Full record by sport and season', 'Head-to-head against any school', 'Export for newsletters'],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final data = SportsData.instance;

    return SiteScaffold(
      currentRoute: SiteRoutes.forSchools,
      children: [
        const PageHero(
          title: 'For Schools',
          breadcrumb: 'For Schools',
          subtitle: 'Everything your sports office needs to run a season: teams, fixtures, '
              'results and the record that comes out of them.',
        ),
        ContentWidth(
          child: Padding(
            padding: const EdgeInsets.only(top: 28, bottom: 56),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PlatformStats(
                  sample: StatsBand(
                    valueColor: AppColors.orange,
                    stats: [
                      (Icons.school_outlined, '${SportsData.schools.length}', 'Schools on board'),
                      (
                        Icons.calendar_month_outlined,
                        formatThousands(data.fixtures.length + data.results.length),
                        'Fixtures managed',
                      ),
                      (Icons.sports, '${Sport.values.length}', 'Sports supported'),
                      (Icons.payments_outlined, 'Free', 'To register'),
                    ],
                  ),
                  live: (counts) => StatsBand(
                    valueColor: AppColors.orange,
                    stats: [
                      (Icons.school_outlined, formatThousands(counts.schools), 'Schools on board'),
                      (Icons.scoreboard_outlined, formatThousands(counts.matches), 'Matches played'),
                      (Icons.sports, '${counts.sports}', 'Sports played'),
                      (Icons.payments_outlined, 'Free', 'To register'),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
                const SectionEyebrow('What you get'),
                const SizedBox(height: 28),
                for (final (index, tool) in _tools.indexed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: _ToolSection(
                      icon: tool.$1,
                      title: tool.$2,
                      body: tool.$3,
                      points: tool.$4,
                      flip: index.isOdd,
                    ),
                  ),
                const SizedBox(height: 28),
                const _GettingStarted(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ToolSection extends StatelessWidget {
  const _ToolSection({
    required this.icon,
    required this.title,
    required this.body,
    required this.points,
    required this.flip,
  });

  final IconData icon;
  final String title;
  final String body;
  final List<String> points;

  /// Alternate the icon panel left and right so the page does not read as a
  /// single column of identical blocks.
  final bool flip;

  @override
  Widget build(BuildContext context) {
    final panel = Container(
      height: 150,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.greenDark, AppColors.green],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 54, color: Colors.white.withValues(alpha: 0.9)),
    );

    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: AppColors.ink,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          body,
          style: const TextStyle(fontSize: 12, color: AppColors.muted, height: 1.6),
        ),
        const SizedBox(height: 12),
        for (final point in points)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 1),
                  child: Icon(Icons.check_circle, size: 13, color: AppColors.greenBright),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    point,
                    style: const TextStyle(fontSize: 11.5, color: AppColors.ink, height: 1.45),
                  ),
                ),
              ],
            ),
          ),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 680) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [panel, const SizedBox(height: 16), copy],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: flip
                ? [Expanded(flex: 3, child: copy), const SizedBox(width: 24), Expanded(flex: 2, child: panel)]
                : [Expanded(flex: 2, child: panel), const SizedBox(width: 24), Expanded(flex: 3, child: copy)],
          );
        },
      ),
    );
  }
}

class _GettingStarted extends StatelessWidget {
  const _GettingStarted();

  static const _steps = [
    ('1', 'Register', 'Tell us about your school, the sports you field and who runs them.'),
    ('2', 'Add your teams', 'Set up squads by sport and age group, and invite your coaches.'),
    ('3', 'Start playing', 'Arrange fixtures, post results, and let the tables build themselves.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.greenDark, AppColors.green],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'GETTING STARTED',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Registration is free, and most schools are set up the same day.',
            style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.85)),
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final steps = [
                for (final (number, title, body) in _steps)
                  _Step(number: number, title: title, body: body),
              ];
              if (constraints.maxWidth < 680) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final step in steps)
                      Padding(padding: const EdgeInsets.only(bottom: 18), child: step),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final (index, step) in steps.indexed) ...[
                    if (index > 0) const SizedBox(width: 24),
                    Expanded(child: step),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SiteButton(
                label: 'REGISTER YOUR SCHOOL',
                variant: SiteButtonVariant.orange,
                onPressed: () => openSiteRoute(context, SiteRoutes.signup),
              ),
              SiteButton(
                label: 'TALK TO US',
                variant: SiteButtonVariant.outlineLight,
                onPressed: () => openSiteRoute(context, SiteRoutes.contact),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.title, required this.body});

  final String number;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: const BoxDecoration(color: AppColors.orange, shape: BoxShape.circle),
          child: Text(
            number,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          title,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white),
        ),
        const SizedBox(height: 4),
        Text(
          body,
          style: TextStyle(
            fontSize: 11.5,
            color: Colors.white.withValues(alpha: 0.8),
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
