import 'package:flutter/material.dart';

import 'api/api_client.dart';
import 'api/session.dart';
import 'api/token_store.dart';
import 'pages/about/about_page.dart';
import 'pages/auth/forgot_password_page.dart';
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
  const TobunApp({super.key, this.session});

  final Session? session;

  @override
  State<TobunApp> createState() => _TobunAppState();
}

class _TobunAppState extends State<TobunApp> {
  late final Session _session =
      widget.session ?? Session(ApiClient(tokenStore: PrefsTokenStore()));

  @override
  void initState() {
    super.initState();
    _session.restore();
  }

  @override
  Widget build(BuildContext context) {
    return SessionScope(
      session: _session,
      child: _buildApp(),
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
      routes: {
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
        SiteRoutes.help: (_) => const HelpPage(),
        SiteRoutes.terms: (_) => const PolicyPage(policy: Policy.terms),
        SiteRoutes.privacy: (_) => const PolicyPage(policy: Policy.privacy),
        SiteRoutes.safety: (_) => const PolicyPage(policy: Policy.safety),
        SiteRoutes.forgotPassword: (_) => const ForgotPasswordPage(),
      },
    );
  }
}
