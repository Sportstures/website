import 'package:flutter/material.dart';

import 'api/api_client.dart';
import 'api/session.dart';
import 'api/token_store.dart';
import 'data/match_store.dart';
import 'pages/about/about_page.dart';
import 'pages/auth/forgot_password_page.dart';
import 'pages/coach/coach_home_page.dart';
import 'pages/coach/coach_invite_page.dart';
import 'pages/coach/coach_match_invites_page.dart';
import 'pages/coach/coach_team_page.dart';
import 'pages/contact/contact_page.dart';
import 'pages/for_schools/for_schools_page.dart';
import 'pages/fixtures/fixtures_page.dart';
import 'pages/landing/landing_page.dart';
import 'pages/login.dart';
import 'pages/rankings/rankings_page.dart';
import 'pages/results/results_page.dart';
import 'pages/schools/school_profile_page.dart';
import 'pages/schools/schools_page.dart';
import 'pages/signup/signup_page.dart';
import 'pages/sports/sport_page.dart';
import 'pages/sports/sports_index_page.dart';
import 'pages/standings/standings_page.dart';
import 'pages/support/help_page.dart';
import 'pages/support/policy_page.dart';
import 'widgets/site/site_routes.dart';

void main() {
  runApp(const TobunApp());
}

class TobunApp extends StatefulWidget {
  /// Pass a [session] to run against a different backend or token store (tests do).
  /// Pass [matches] to change where fixtures and results come from; `MatchStore.sample()`
  /// uses the built-in sample data and never calls the backend.
  const TobunApp({super.key, this.session, this.matches});

  final Session? session;
  final MatchStore? matches;

  @override
  State<TobunApp> createState() => _TobunAppState();
}

class _TobunAppState extends State<TobunApp> {
  late final Session _session =
      widget.session ?? Session(ApiClient(tokenStore: PrefsTokenStore()));
  late final MatchStore _matches = widget.matches ?? MatchStore.api(_session.api);

  @override
  void initState() {
    super.initState();
    _session.restore();
  }

  @override
  Widget build(BuildContext context) {
    return SessionScope(
      session: _session,
      child: MatchScope(
        store: _matches,
        child: _buildApp(),
      ),
    );
  }

  Widget _buildApp() {
    return MaterialApp(
      title: 'Tobun Sports Portal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto', // TODO: swap for the real brand font once confirmed
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E4A3D)),
      ),
      initialRoute: SiteRoutes.home,
      routes: _routes,
      // An invitation link arrives as /signup?invite=<code>. Open the page and keep the whole name,
      // so the sign-up page can read the code.
      onGenerateRoute: (settings) {
        final name = settings.name ?? '';
        final query = name.indexOf('?');
        final builder = query < 0 ? null : _routes[name.substring(0, query)];
        return builder == null ? null : MaterialPageRoute<void>(settings: settings, builder: builder);
      },
    );
  }

  static final Map<String, WidgetBuilder> _routes = {
        SiteRoutes.home: (_) => const LandingPage(),
        SiteRoutes.fixtures: (_) => const FixturesPage(),
        SiteRoutes.results: (_) => const ResultsPage(),
        SiteRoutes.standings: (_) => const StandingsPage(),
        SiteRoutes.rankings: (_) => const RankingsPage(),
        SiteRoutes.schools: (_) => const SchoolsPage(),
        SiteRoutes.about: (_) => const AboutPage(),
        SiteRoutes.contact: (_) => const ContactPage(),
        SiteRoutes.login: (_) => const LoginPage(),
        SiteRoutes.signup: (_) => const SignupPage(),
        SiteRoutes.sports: (_) => const SportsIndexPage(),
        SiteRoutes.sport: (_) => const SportPage(),
        SiteRoutes.school: (_) => const SchoolProfilePage(),
        SiteRoutes.forSchools: (_) => const ForSchoolsPage(),
        SiteRoutes.coach: (_) => const CoachHomePage(),
        SiteRoutes.coachTeam: (_) => const CoachTeamPage(),
        SiteRoutes.coachInvite: (_) => const CoachInvitePage(),
        SiteRoutes.coachMatchInvites: (_) => const CoachMatchInvitesPage(),
        SiteRoutes.help: (_) => const HelpPage(),
        SiteRoutes.terms: (_) => const PolicyPage(policy: Policy.terms),
        SiteRoutes.privacy: (_) => const PolicyPage(policy: Policy.privacy),
        SiteRoutes.safety: (_) => const PolicyPage(policy: Policy.safety),
        SiteRoutes.forgotPassword: (_) => const ForgotPasswordPage(),
      };
}
