import 'package:flutter/material.dart';

import '../../api/session.dart';
import '../../widgets/site/page_hero.dart';
import '../../widgets/site/site_routes.dart';
import '../../widgets/site/site_scaffold.dart';
import '../../widgets/site/ui_kit.dart';

/// Shows [builder] only to a signed-in coach. Everyone else gets a clear message
/// instead of a page of errors: a spinner while a saved login is being checked,
/// a log in prompt for visitors, and an explanation for learners and admins.
class CoachGuard extends StatelessWidget {
  const CoachGuard({
    super.key,
    required this.currentRoute,
    required this.title,
    required this.subtitle,
    required this.builder,
  });

  final String currentRoute;
  final String title;
  final String subtitle;
  final Widget Function(BuildContext context, AppUser coach) builder;

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    final user = session.user;
    if (user != null && user.isCoach) return builder(context, user);

    final Widget body;
    if (session.isRestoring) {
      body = const Center(child: CircularProgressIndicator());
    } else if (user == null) {
      body = SectionCard(
        title: 'Log in to continue',
        child: Column(
          children: [
            const EmptyState('The coach area is for signed-in coaches.'),
            const SizedBox(height: 12),
            SiteButton(label: 'LOG IN', small: true, onPressed: () => openSiteRoute(context, SiteRoutes.login)),
            const SizedBox(height: 12),
          ],
        ),
      );
    } else {
      body = const SectionCard(
        title: 'Coaches only',
        child: Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: EmptyState('This area is for coach accounts. You are signed in as a learner or an administrator.'),
        ),
      );
    }

    return SiteScaffold(
      currentRoute: currentRoute,
      children: [
        PageHero(title: title, breadcrumb: title, subtitle: subtitle),
        ContentWidth(child: Padding(padding: const EdgeInsets.symmetric(vertical: 56), child: body)),
      ],
    );
  }
}
