import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../widgets/site/page_hero.dart';
import '../../widgets/site/site_routes.dart';
import '../../widgets/site/site_scaffold.dart';
import '../../widgets/site/ui_kit.dart';

/// Help centre: the questions schools and parents actually ask, grouped, with
/// a way through to a person when the answer is not here.
// TODO: confirm the support hours and response times before launch
class HelpPage extends StatefulWidget {
  const HelpPage({super.key});

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  static const _topics = [
    (
      Icons.rocket_launch_outlined,
      'Getting started',
      [
        (
          'How do we register our school?',
          'Use Register School in the top bar. You will need the school name, your region, the '
              'sports you field and a contact for the sports office. Registration is free.',
        ),
        (
          'Who should hold the account?',
          'Usually the sports director or an administrator in the sports office. You can invite '
              'coaches afterwards and give them access to their own teams only.',
        ),
        (
          'How long does approval take?',
          'Most schools are verified the same day. We check that the school exists and that the '
              'contact belongs to it before fixtures go live.',
        ),
      ],
    ),
    (
      Icons.calendar_month_outlined,
      'Fixtures and results',
      [
        (
          'How do we arrange a fixture?',
          'Create a match, pick the opposing school, and set the sport, age group, date and '
              'venue. They confirm, and it appears on both calendars.',
        ),
        (
          'Who enters the score?',
          'Either school can post the result. If the two entries disagree, both are flagged and '
              'neither counts towards the table until it is settled.',
        ),
        (
          'Can a result be corrected?',
          'Yes. Corrections are kept on the record so tables can be recalculated and anyone '
              'following the match can see what changed.',
        ),
        (
          'What happens to a postponed match?',
          'Mark it postponed and it comes off the table until a new date is agreed. Everyone '
              'following the fixture is notified.',
        ),
      ],
    ),
    (
      Icons.bar_chart_rounded,
      'Tables and rankings',
      [
        (
          'How are standings worked out?',
          'Three points for a win, one for a draw. Schools level on points are split on score '
              'difference, then on points scored, then on their results against each other '
              '(head-to-head), then alphabetically.',
        ),
        (
          'Why is our table different from the rankings?',
          'Tables cover one sport and age group. Rankings compare schools across everything they '
              'play, so a school strong in several sports climbs higher.',
        ),
        (
          'What is the AI analysis?',
          'A reading of past results - form, scoring margins and head-to-head - shown with the '
              'numbers behind it. It is a projection, not a prediction of what will happen.',
        ),
      ],
    ),
    (
      Icons.lock_outline,
      'Accounts and privacy',
      [
        (
          'I have forgotten my password.',
          'Use Forgot Password on the login page and we will email you a reset link.',
        ),
        (
          'What do you publish about learners?',
          'Team sheets, results and statistics. We do not publish contact details, addresses or '
              'dates of birth. See the privacy policy for the full position.',
        ),
        (
          'Can a parent ask for a child to be left out?',
          'Yes. Contact your school sports office, who can hide a learner from public listings '
              'while keeping them in the team internally.',
        ),
      ],
    ),
  ];

  int _open = 0;

  @override
  Widget build(BuildContext context) {
    return SiteScaffold(
      currentRoute: SiteRoutes.help,
      children: [
        const PageHero(
          title: 'Help Centre',
          breadcrumb: 'Help Centre',
          subtitle: 'Answers to the questions we get most. If yours is not here, we would rather '
              'you asked us than guessed.',
        ),
        ContentWidth(
          child: Padding(
            padding: const EdgeInsets.only(top: 28, bottom: 56),
            child: TwoColumnLayout(
              main: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (index, topic) in _topics.indexed)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _TopicCard(
                        icon: topic.$1,
                        title: topic.$2,
                        entries: topic.$3,
                        expanded: _open == index,
                        onToggle: () => setState(() => _open = _open == index ? -1 : index),
                      ),
                    ),
                ],
              ),
              sidebar: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: const [
                  _ContactCard(),
                  SizedBox(height: 16),
                  _PolicyLinksCard(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TopicCard extends StatelessWidget {
  const _TopicCard({
    required this.icon,
    required this.title,
    required this.entries,
    required this.expanded,
    required this.onToggle,
  });

  final IconData icon;
  final String title;
  final List<(String, String)> entries;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onToggle,
            child: Container(
              color: AppColors.surface,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(icon, size: 16, color: AppColors.green),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  CountLabel(count: entries.length, noun: 'answer'),
                  const SizedBox(width: 8),
                  Icon(
                    expanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: AppColors.muted,
                  ),
                ],
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DividedColumn(
                children: [
                  for (final (question, answer) in entries)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            question,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            answer,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.muted,
                              height: 1.6,
                            ),
                          ),
                        ],
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

class _ContactCard extends StatelessWidget {
  const _ContactCard();

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Still stuck?',
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Send us the details and we will come back to you. Sports offices get priority '
            'during the season.',
            style: TextStyle(fontSize: 11.5, color: AppColors.muted, height: 1.6),
          ),
          const SizedBox(height: 14),
          SiteButton(
            label: 'CONTACT SUPPORT',
            small: true,
            expand: true,
            onPressed: () => openSiteRoute(context, SiteRoutes.contact),
          ),
          const SizedBox(height: 8),
          SiteButton(
            label: 'REPORT A PROBLEM',
            variant: SiteButtonVariant.outline,
            small: true,
            expand: true,
            onPressed: () => openSiteRoute(context, SiteRoutes.contact),
          ),
        ],
      ),
    );
  }
}

class _PolicyLinksCard extends StatelessWidget {
  const _PolicyLinksCard();

  @override
  Widget build(BuildContext context) {
    const links = [
      (Icons.gavel_outlined, 'Terms & Conditions', SiteRoutes.terms),
      (Icons.privacy_tip_outlined, 'Privacy Policy', SiteRoutes.privacy),
      (Icons.health_and_safety_outlined, 'Safety & Guidelines', SiteRoutes.safety),
    ];

    return SectionCard(
      title: 'Policies',
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          for (final (icon, label, route) in links)
            InkWell(
              onTap: () => openSiteRoute(context, route),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                child: Row(
                  children: [
                    Icon(icon, size: 15, color: AppColors.green),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        label,
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
