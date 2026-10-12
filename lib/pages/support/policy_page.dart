import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../widgets/site/page_hero.dart';
import '../../widgets/site/site_routes.dart';
import '../../widgets/site/site_scaffold.dart';
import '../../widgets/site/ui_kit.dart';

/// Which policy a [PolicyPage] is showing.
///
// TODO: these are a working draft written to cover the platform as built. Have
// them reviewed by a lawyer, and by someone who knows the Protection of
// Personal Information Act, before launch - schools will be asked to agree to
// them on behalf of minors.
enum Policy {
  terms(
    route: SiteRoutes.terms,
    title: 'Terms & Conditions',
    subtitle: 'The agreement between Sportstures and the schools, staff and visitors who use it.',
    sections: _termsSections,
  ),
  privacy(
    route: SiteRoutes.privacy,
    title: 'Privacy Policy',
    subtitle: 'What we collect, why we collect it, and what we will never do with it. Most of the '
        'people on this platform are children, and that shapes every answer below.',
    sections: _privacySections,
  ),
  safety(
    route: SiteRoutes.safety,
    title: 'Safety & Guidelines',
    subtitle: 'How we keep a platform about school children safe, and what we expect from the '
        'schools and adults using it.',
    sections: _safetySections,
  );

  const Policy({
    required this.route,
    required this.title,
    required this.subtitle,
    required this.sections,
  });

  final String route;
  final String title;
  final String subtitle;
  final List<(String, String)> sections;
}

const _termsSections = [
  (
    'Who may use Sportstures',
    'Accounts are held by schools, not individuals. A school registers through an authorised '
        'member of staff, who may then invite coaches and administrators. Anyone may browse '
        'fixtures, results and tables without an account.',
  ),
  (
    'Your responsibilities',
    'The registering school is responsible for the accuracy of what it publishes: team sheets, '
        'fixtures and results. Schools must hold the appropriate consent for any learner they '
        'list, and must keep their staff accounts current when people change roles.',
  ),
  (
    'Results and records',
    'Either school in a fixture may post the result. Where entries disagree, both are flagged and '
        'neither counts towards a table until the schools settle it. Corrections remain on the '
        'record so that tables can be recalculated transparently.',
  ),
  (
    'Acceptable use',
    'Sportstures may not be used to harass, abuse or expose any person, to publish anything '
        'misleading about a match, or to collect information about learners for any purpose '
        'beyond school sport. Accounts that do so are suspended.',
  ),
  (
    'Availability',
    'We work to keep the platform available during fixtures and will give notice of planned '
        'maintenance where we can. We cannot guarantee uninterrupted service and are not liable '
        'for a fixture missed because of an outage.',
  ),
  (
    'Intellectual property',
    'Schools keep ownership of their crests, team names and the content they upload, and grant '
        'Sportstures permission to display it on the platform. The platform itself, its design '
        'and its software remain ours.',
  ),
  (
    'Ending an account',
    'A school may close its account at any time. Published results stay on the record, since '
        'removing them would distort the tables of every school they played; team sheets and '
        'contact details are removed.',
  ),
  (
    'Changes to these terms',
    'We will give schools notice before material changes take effect. Continuing to use the '
        'platform after that date means accepting the revised terms.',
  ),
];

const _privacySections = [
  (
    'What we collect',
    'For schools: the school name, region, sports fielded, and contact details for the staff who '
        'run the account. For learners: name, team, age group and the statistics that come out of '
        'matches played. For visitors: basic usage data that tells us which pages are used.',
  ),
  (
    'What we publish',
    'Team sheets, fixtures, results, tables and the statistics derived from them. We do not '
        'publish a learner\'s contact details, home address, date of birth, identity number or '
        'photograph without the school confirming consent.',
  ),
  (
    'Why we collect it',
    'To run fixtures and produce the tables and rankings that follow from them. We do not sell '
        'personal information, and we do not use it to advertise to learners or their families.',
  ),
  (
    'Children',
    'Most of the people represented on this platform are minors. Consent is handled by the school '
        'under its own parental consent arrangements, and a parent may ask the school to hide a '
        'learner from public listings while keeping them in the team internally.',
  ),
  (
    'Who can see what',
    'Fixtures, results and tables are public. Team management, contact details and account '
        'settings are visible only to the staff of that school. Coaches can be given access to '
        'their own teams only.',
  ),
  (
    'How long we keep it',
    'Match records are kept for the history of the competition. Personal details of staff and '
        'learners are removed when a school closes its account or asks us to remove them.',
  ),
  (
    'Your rights',
    'You may ask what we hold about you, ask for it to be corrected, or ask for it to be deleted. '
        'Requests about a learner should come through the school in the first instance. Contact us '
        'and we will respond.',
  ),
  (
    'Security',
    'Access is restricted to the school that owns the data. We review who can reach what, and we '
        'will tell affected schools promptly if personal information is ever exposed.',
  ),
];

const _safetySections = [
  (
    'Our commitment',
    'This is a platform about school children. Everything on it is built on the assumption that '
        'what we publish could be seen by anyone, so we publish only what belongs in public: how '
        'teams performed, not who a child is or where to find them.',
  ),
  (
    'What schools must do',
    'Hold parental consent for every learner listed. Keep staff accounts current and remove '
        'access when someone leaves. Make sure the adults given coach accounts are cleared to work '
        'with children under your own policies.',
  ),
  (
    'What we never publish',
    'Contact details, home addresses, dates of birth, identity numbers, medical information, or '
        'anything that would let a stranger identify or locate a learner outside a fixture.',
  ),
  (
    'Conduct',
    'Coaches, administrators and spectators using the platform are expected to behave as they '
        'would at the touchline. Abuse, harassment, discriminatory language and intimidation have '
        'no place here and cost an account its access.',
  ),
  (
    'Reporting a concern',
    'If something on the platform worries you - a listing that should not be public, a message '
        'that crossed a line, an account that does not look legitimate - report it. Anything '
        'involving the safety of a child is looked at the same day.',
  ),
  (
    'Fair play',
    'Results are a shared record. Entering a score you know to be wrong, or arranging fixtures to '
        'inflate a ranking, undermines every school on the table. Repeated cases are removed from '
        'rankings and the schools involved are contacted.',
  ),
  (
    'Images and video',
    'Where a school uploads photographs or video, it confirms it holds consent for every child '
        'shown. We remove media on request from the school or a parent, without asking for a '
        'reason.',
  ),
];

/// A policy document, rendered the same way whichever one it is.
class PolicyPage extends StatelessWidget {
  const PolicyPage({super.key, required this.policy});

  final Policy policy;

  @override
  Widget build(BuildContext context) {
    return SiteScaffold(
      currentRoute: policy.route,
      children: [
        PageHero(
          title: policy.title,
          breadcrumb: policy.title,
          subtitle: policy.subtitle,
        ),
        ContentWidth(
          child: Padding(
            padding: const EdgeInsets.only(top: 28, bottom: 56),
            child: TwoColumnLayout(
              main: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _DraftNotice(),
                  const SizedBox(height: 16),
                  for (final (index, (heading, body)) in policy.sections.indexed)
                    _Section(number: index + 1, heading: heading, body: body),
                ],
              ),
              sidebar: _PolicyNav(current: policy),
            ),
          ),
        ),
      ],
    );
  }
}

class _DraftNotice extends StatelessWidget {
  const _DraftNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.orange.withValues(alpha: 0.08),
        border: Border.all(color: AppColors.orange.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 15, color: AppColors.orange),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Working draft. This document describes how the platform is built and how we intend '
              'to operate, and is pending legal review before launch.',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.ink.withValues(alpha: 0.75),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.number, required this.heading, required this.body});

  final int number;
  final String heading;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$number.',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: AppColors.orange,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  heading,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: Text(
              body,
              style: const TextStyle(fontSize: 12.5, color: AppColors.muted, height: 1.75),
            ),
          ),
        ],
      ),
    );
  }
}

class _PolicyNav extends StatelessWidget {
  const _PolicyNav({required this.current});

  final Policy current;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionCard(
          title: 'Policies',
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              for (final policy in Policy.values)
                InkWell(
                  onTap: policy == current
                      ? null
                      : () => openSiteRoute(context, policy.route),
                  child: Container(
                    color: policy == current ? AppColors.surface : null,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            policy.title,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.ink,
                              fontWeight:
                                  policy == current ? FontWeight.w800 : FontWeight.w400,
                            ),
                          ),
                        ),
                        if (policy != current)
                          const Icon(Icons.chevron_right, size: 16, color: AppColors.muted),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: 'Questions?',
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'If anything here is unclear, or you need a copy for your governing body, ask us.',
                style: TextStyle(fontSize: 11.5, color: AppColors.muted, height: 1.6),
              ),
              const SizedBox(height: 12),
              SiteButton(
                label: 'CONTACT US',
                small: true,
                expand: true,
                onPressed: () => openSiteRoute(context, SiteRoutes.contact),
              ),
              const SizedBox(height: 8),
              SiteButton(
                label: 'HELP CENTRE',
                variant: SiteButtonVariant.outline,
                small: true,
                expand: true,
                onPressed: () => openSiteRoute(context, SiteRoutes.help),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
