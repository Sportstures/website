import 'package:flutter/material.dart';

import '../../data/sports_data.dart';
import '../../config/site_links.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';
import '../../widgets/site/page_hero.dart';
import '../../widgets/site/platform_stats.dart';
import '../../widgets/site/site_routes.dart';
import '../../widgets/site/site_scaffold.dart';
import '../../widgets/site/ui_kit.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final data = SportsData.instance;

    return SiteScaffold(
      currentRoute: SiteRoutes.about,
      children: [
        const PageHero(
          title: 'About\nSportstures',
          subtitle: 'Sportstures is the home of school sports fixtures in South Africa. We connect '
              'schools, teams, athletes and communities through the love of sport.',
        ),
        ContentWidth(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 56),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _OurStory(),
                const SizedBox(height: 48),
                PlatformStats(
                  sample: StatsBand(
                    valueColor: AppColors.orange,
                    stats: [
                      (Icons.school_outlined, formatThousands(SportsData.schools.length), 'Registered Schools'),
                      (Icons.location_on_outlined, '${SportsData.provinces.length}', 'Provinces'),
                      (
                        Icons.calendar_month_outlined,
                        formatThousands(data.fixtures.length + data.results.length),
                        'Fixtures Managed',
                      ),
                      (
                        Icons.groups_outlined,
                        formatThousands(SportsData.schools.fold(0, (sum, s) => sum + s.athletes)),
                        'Student Athletes',
                      ),
                    ],
                  ),
                  live: (counts) => StatsBand(
                    valueColor: AppColors.orange,
                    stats: [
                      (Icons.school_outlined, formatThousands(counts.schools), 'Registered Schools'),
                      (Icons.location_on_outlined, '${counts.provinces}', 'Provinces'),
                      (Icons.sports, '${counts.sports}', 'Sports Played'),
                      (Icons.scoreboard_outlined, formatThousands(counts.matches), 'Matches Played'),
                    ],
                  ),
                ),
                const SizedBox(height: 56),
                const _MissionAndVision(),
                const SizedBox(height: 56),
                const _WhyChooseUs(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _OurStory extends StatelessWidget {
  const _OurStory();

  static const _pillars = [
    (Icons.emoji_events_outlined, 'One Platform', 'Fixtures, results, standings, rankings and teams — all in one place.'),
    (Icons.groups_outlined, 'Stronger Communities', 'Connecting schools, families and communities through the power of sport.'),
    (Icons.bar_chart_rounded, 'Data That Matters', 'Accurate, real-time data that helps schools and athletes grow.'),
    (Icons.verified_user_outlined, 'Fair Play', 'Promoting transparency, respect and integrity in every competition.'),
  ];

  @override
  Widget build(BuildContext context) {
    const bodyStyle = TextStyle(fontSize: 13, color: AppColors.muted, height: 1.6);

    final story = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Eyebrow('Our story'),
        const SizedBox(height: 10),
        const Text(
          'Building the future of\nschool sports.',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.ink, height: 1.2),
        ),
        const SizedBox(height: 18),
        // TODO: confirm the founding story copy
        const Text(
          'Sportstures was founded in 2026 with a simple mission: to make school sports more '
          'organised, accessible and impactful.',
          style: bodyStyle,
        ),
        const SizedBox(height: 12),
        const Text(
          'We saw the challenges schools faced in managing fixtures, results and communication — '
          'and we built a platform that solves them all in one place.',
          style: bodyStyle,
        ),
        const SizedBox(height: 12),
        const Text(
          'Today, Sportstures is trusted by schools across South Africa to manage competitions, '
          'showcase talent and bring communities together.',
          style: bodyStyle,
        ),
        // Hidden until there is a film to play. Offering to show someone a
        // sixty-second story and then not having one is worse than not asking.
        if (SiteLinks.has(SiteLinks.storyVideo)) ...[
          const SizedBox(height: 24),
          SiteButton(
            label: 'OUR STORY IN 60 SECONDS',
            icon: Icons.play_circle_outline,
            variant: SiteButtonVariant.outline,
            small: true,
            onPressed: () => openExternal(context, Uri.parse(SiteLinks.storyVideo!)),
          ),
        ],
      ],
    );

    final pillars = LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 480 ? 2 : 1;
        final tileWidth = constraints.maxWidth / columns;
        return Wrap(
          children: [
            for (final (i, (icon, title, description)) in _pillars.indexed)
              Container(
                width: tileWidth,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border(
                    right: columns == 2 && i.isEven
                        ? const BorderSide(color: AppColors.border)
                        : BorderSide.none,
                    bottom: i < _pillars.length - columns
                        ? const BorderSide(color: AppColors.border)
                        : BorderSide.none,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(color: AppColors.surface, shape: BoxShape.circle),
                      child: Icon(icon, size: 22, color: AppColors.ink),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.ink),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            description,
                            style: const TextStyle(fontSize: 11, color: AppColors.muted, height: 1.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 900) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: story),
              const SizedBox(width: 48),
              Expanded(child: pillars),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [story, const SizedBox(height: 32), pillars],
        );
      },
    );
  }
}

class _MissionAndVision extends StatelessWidget {
  const _MissionAndVision();

  @override
  Widget build(BuildContext context) {
    const purpose = _StatementCard(
      icon: Icons.track_changes,
      label: 'Our purpose',
      labelColor: AppColors.green,
      background: AppColors.surface,
      text: 'To simplify and elevate school sports management by providing innovative tools and '
          'accurate data that empower schools, teams and athletes to achieve their best.',
    );
    const vision = _StatementCard(
      icon: Icons.visibility_outlined,
      label: 'Our vision',
      labelColor: AppColors.orange,
      background: Color(0xFFFFF7DB),
      text: 'To be the leading platform for school sports in Africa, inspiring the next generation '
          'of athletes and building a legacy of excellence both on and off the field.',
    );

    return Column(
      children: [
        const Eyebrow('Our purpose'),
        const SizedBox(height: 8),
        const Text(
          'Our Mission & Vision',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.ink),
        ),
        const SizedBox(height: 28),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= 760) {
              return const IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: purpose),
                    SizedBox(width: 20),
                    Expanded(child: vision),
                  ],
                ),
              );
            }
            return const Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [purpose, SizedBox(height: 16), vision],
            );
          },
        ),
      ],
    );
  }
}

class _StatementCard extends StatelessWidget {
  const _StatementCard({
    required this.icon,
    required this.label,
    required this.labelColor,
    required this.background,
    required this.text,
  });

  final IconData icon;
  final String label;
  final Color labelColor;
  final Color background;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: background,
        border: Border(left: BorderSide(color: labelColor, width: 4)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 40, color: AppColors.ink),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Eyebrow(label, color: labelColor),
                const SizedBox(height: 8),
                Text(text, style: const TextStyle(fontSize: 14, color: AppColors.ink, height: 1.6)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WhyChooseUs extends StatelessWidget {
  const _WhyChooseUs();

  // TODO: the design repeats "Reliable & Secure" for all five; confirm final copy
  static const _reasons = [
    (Icons.verified_user_outlined, 'Reliable & Secure', 'Your data is protected and always up to date.'),
    (Icons.smartphone, 'Works Everywhere', 'Follow fixtures and results from any device.'),
    (Icons.headset_mic_outlined, 'Real Support', 'Friendly help whenever your school needs it.'),
    (Icons.star_outline, 'Celebrates Talent', "Showcase your school's teams and achievements."),
    (Icons.insights, 'Performance Insights', 'Standings and rankings that track real progress.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SectionEyebrow('Why choose Sportstures?'),
        const SizedBox(height: 32),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 900
                ? 5
                : constraints.maxWidth >= 520
                    ? 3
                    : 2;
            const gap = 16.0;
            final itemWidth = (constraints.maxWidth - gap * (columns - 1)) / columns;
            return Wrap(
              spacing: gap,
              runSpacing: 28,
              alignment: WrapAlignment.center,
              children: [
                for (final (icon, title, description) in _reasons)
                  SizedBox(
                    width: itemWidth,
                    child: Column(
                      children: [
                        Icon(icon, size: 40, color: AppColors.ink),
                        const SizedBox(height: 14),
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.ink),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          description,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12, color: AppColors.muted, height: 1.5),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
