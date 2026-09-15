import 'package:flutter/material.dart';

import 'pages/about/about_page.dart';
import 'pages/contact/contact_page.dart';
import 'pages/fixtures/fixtures_page.dart';
import 'pages/landing/landing_page.dart';
import 'pages/login.dart';
import 'pages/rankings/rankings_page.dart';
import 'pages/results/results_page.dart';
import 'pages/schools/schools_page.dart';
import 'pages/signup/signup_page.dart';
import 'pages/standings/standings_page.dart';
import 'widgets/site/site_routes.dart';

void main() {
  runApp(const TobunApp());
}

class TobunApp extends StatelessWidget {
  const TobunApp({super.key});

  @override
  Widget build(BuildContext context) {
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
      },
    );
  }
}
