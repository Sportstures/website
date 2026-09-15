import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';
import 'ui_kit.dart';

// TODO: swap for real crest images once schools upload them
class TeamCrest extends StatelessWidget {
  const TeamCrest({super.key, required this.school, this.size = 28});

  final School school;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: school.color.withValues(alpha: 0.12),
        border: Border.all(color: school.color, width: 1.5),
      ),
      child: Text(
        school.initials,
        style: TextStyle(
          fontSize: size * 0.36,
          fontWeight: FontWeight.w800,
          color: school.color,
        ),
      ),
    );
  }
}

/// Crest and school name (with an optional second line) for table cells.
class SchoolCell extends StatelessWidget {
  const SchoolCell({super.key, required this.school, this.subtitle, this.crestSize = 24});

  final School school;
  final String? subtitle;
  final double crestSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        TeamCrest(school: school, size: crestSize),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                school.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10, color: AppColors.muted),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// "Home name (crest) [center] (crest) Away name"
class TeamsLine extends StatelessWidget {
  const TeamsLine({
    super.key,
    required this.home,
    required this.away,
    required this.center,
    this.homeBold = false,
    this.awayBold = false,
  });

  final School home;
  final School away;
  final Widget center;
  final bool homeBold;
  final bool awayBold;

  @override
  Widget build(BuildContext context) {
    TextStyle style(bool bold) => TextStyle(
          fontSize: 12,
          color: AppColors.ink,
          fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
        );

    return Row(
      children: [
        Expanded(
          child: Text(
            home.name,
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style(homeBold),
          ),
        ),
        const SizedBox(width: 8),
        TeamCrest(school: home),
        const SizedBox(width: 10),
        center,
        const SizedBox(width: 10),
        TeamCrest(school: away),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            away.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style(awayBold),
          ),
        ),
      ],
    );
  }
}

class _CompetitionLabel extends StatelessWidget {
  const _CompetitionLabel(this.fixture);

  final Fixture fixture;

  @override
  Widget build(BuildContext context) {
    return Text(
      fixture.competition,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        color: AppColors.orange,
        letterSpacing: 0.3,
      ),
    );
  }
}

class _Venue extends StatelessWidget {
  const _Venue(this.fixture, {this.textAlign = TextAlign.center});

  final Fixture fixture;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    return Text(
      fixture.venue,
      textAlign: textAlign,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 10, color: AppColors.muted),
    );
  }
}

class _DateBadge extends StatelessWidget {
  const _DateBadge(this.date);

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Text(
            '${date.day}',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.ink),
          ),
          Text(
            shortMonth(date),
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class FixtureRow extends StatelessWidget {
  const FixtureRow({super.key, required this.fixture});

  final Fixture fixture;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          _DateBadge(fixture.startsAt),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _CompetitionLabel(fixture),
                const SizedBox(height: 6),
                TeamsLine(
                  home: fixture.home,
                  away: fixture.away,
                  center: const Text(
                    'VS',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.muted),
                  ),
                ),
                const SizedBox(height: 4),
                _Venue(fixture),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatTime(fixture.startsAt),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.ink),
              ),
              const SizedBox(height: 6),
              const StatusPill('Upcoming', color: AppColors.green),
            ],
          ),
        ],
      ),
    );
  }
}

class ResultRow extends StatelessWidget {
  const ResultRow({super.key, required this.result});

  final MatchResult result;

  @override
  Widget build(BuildContext context) {
    final fixture = result.fixture;

    final teams = TeamsLine(
      home: fixture.home,
      away: fixture.away,
      homeBold: result.homeWon,
      awayBold: result.awayWon,
      center: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${result.homeScore} - ${result.awayScore}',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.ink),
          ),
          const Text(
            'FT',
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.muted),
          ),
        ],
      ),
    );

    final meta = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          formatTime(fixture.startsAt),
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.ink),
        ),
        const SizedBox(height: 2),
        _CompetitionLabel(fixture),
        const SizedBox(height: 2),
        _Venue(fixture, textAlign: TextAlign.left),
      ],
    );

    const pill = StatusPill('Full time', color: AppColors.muted);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 560) {
            return Row(
              children: [
                SizedBox(width: 130, child: meta),
                const SizedBox(width: 12),
                Expanded(child: teams),
                const SizedBox(width: 12),
                pill,
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [Expanded(child: meta), pill],
              ),
              const SizedBox(height: 10),
              teams,
            ],
          );
        },
      ),
    );
  }
}
