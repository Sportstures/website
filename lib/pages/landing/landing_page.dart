import 'package:flutter/material.dart';

import '../../widgets/site/site_routes.dart';
import '../../widgets/site/site_scaffold.dart';
import 'sections/app_section.dart';
import 'sections/cta_banner.dart';
import 'sections/features_section.dart';
import 'sections/fixtures_and_regions_section.dart';
import 'sections/landing_hero.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SiteScaffold(
      currentRoute: SiteRoutes.home,
      children: [
        LandingHero(),
        FeaturesSection(),
        FixturesAndRegionsSection(),
        CtaBanner(),
        AppSection(),
      ],
    );
  }
}
