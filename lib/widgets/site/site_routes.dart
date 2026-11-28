import 'package:flutter/material.dart';

abstract final class SiteRoutes {
  static const home = '/';
  static const fixtures = '/fixtures';
  static const results = '/results';
  static const standings = '/standings';
  static const rankings = '/rankings';
  static const schools = '/schools';
  static const about = '/about';
  static const contact = '/contact';
  static const login = '/login';
  static const signup = '/signup';

  /// Index of every sport.
  static const sports = '/sports';

  /// One sport's hub. Takes a [Sport] as its argument.
  static const sport = '/sport';

  /// One school's profile. Takes a [School] as its argument.
  static const school = '/school';

  /// What a registered school gets: the management tools.
  static const forSchools = '/for-schools';

  /// The signed-in coach's area.
  static const coach = '/coach';
  static const coachTeam = '/coach/team';

  /// Invite a coach from another school (by email or a shareable link).
  static const coachInvite = '/coach/invite';

  /// Upcoming matches: edit, postpone, cancel and set lineups.
  static const coachMatches = '/coach/matches';

  static const coachNotifications = '/coach/notifications';

  /// Competitions the coach organises, and their table rules.
  static const coachCompetitions = '/coach/competitions';

  /// The signed-in person's details, password and email.
  static const account = '/account';

  /// The coach's team details and school location.
  static const coachTeamDetails = '/coach/team-details';

  /// Every competition.
  static const competitions = '/competitions';

  /// One competition's table. Takes `?id=<id>`.
  static const competition = '/competition';

  /// Score a match as it happens. Takes `?fixture=<id>`.
  static const coachLive = '/coach/live';

  /// Invite another school to a match, and answer their invitations.
  static const coachMatchInvites = '/coach/match-invitations';

  static const help = '/help';
  static const terms = '/terms';
  static const privacy = '/privacy';
  static const safety = '/safety';
  static const forgotPassword = '/forgot-password';
}

class NavItem {
  const NavItem(this.label, this.route);

  final String label;
  final String route;
}

const siteNavItems = [
  NavItem('Home', SiteRoutes.home),
  NavItem('Fixtures', SiteRoutes.fixtures),
  NavItem('Results', SiteRoutes.results),
  NavItem('Standings', SiteRoutes.standings),
  NavItem('Rankings', SiteRoutes.rankings),
  NavItem('For Schools', SiteRoutes.schools),
  NavItem('About', SiteRoutes.about),
  NavItem('Contact', SiteRoutes.contact),
];

/// Opens [route]. Login and sign-up stack on top of the current page; the main
/// site pages replace each other so Back always leads home. A null route shows
/// a "coming soon" message.
void openSiteRoute(BuildContext context, String? route, {Object? arguments}) {
  if (route == null) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Coming soon')));
    return;
  }

  final navigator = Navigator.of(context);
  if (ModalRoute.of(context)?.settings.name == route && arguments == null) return;

  switch (route) {
    case SiteRoutes.login || SiteRoutes.signup:
      navigator.pushNamed(route, arguments: arguments);
    case SiteRoutes.home:
      navigator.popUntil((r) => r.isFirst);
    default:
      navigator.pushNamedAndRemoveUntil(route, (r) => r.isFirst, arguments: arguments);
  }
}
