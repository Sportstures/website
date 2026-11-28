import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:website/data/models.dart';
import 'package:website/data/sports_data.dart';
import 'package:website/config/site_links.dart';
import 'package:website/main.dart';
import 'package:website/data/match_store.dart';
import 'package:website/pages/about/about_page.dart';
import 'package:website/pages/landing/landing_page.dart';
import 'package:website/pages/auth/forgot_password_page.dart';
import 'package:website/pages/for_schools/for_schools_page.dart';
import 'package:website/pages/schools/school_profile_page.dart';
import 'package:website/pages/sports/sport_page.dart';
import 'package:website/pages/sports/sports_index_page.dart';
import 'package:website/pages/support/help_page.dart';
import 'package:website/pages/support/policy_page.dart';

Future<void> _pumpPage(WidgetTester tester, Widget page, {Size size = const Size(1400, 1000)}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(MaterialApp(home: page));
  await tester.pumpAndSettle();
}

void main() {
  group('the new pages render', () {
    testWidgets('sports index', (tester) async {
      await _pumpPage(tester, const SportsIndexPage());
      expect(find.text('Sports'), findsWidgets);
      for (final sport in Sport.values) {
        expect(find.text(sport.label), findsWidgets, reason: '${sport.label} should be listed');
      }
    });

    testWidgets('every sport hub', (tester) async {
      for (final sport in Sport.values) {
        await _pumpPage(tester, SportPage(sport: sport));
        expect(tester.takeException(), isNull, reason: '${sport.label} hub threw');
        expect(find.text(sport.label), findsWidgets);
      }
    });

    testWidgets('every school profile', (tester) async {
      for (final school in SportsData.schools) {
        await _pumpPage(tester, SchoolProfilePage(school: school));
        expect(tester.takeException(), isNull, reason: '${school.name} profile threw');
        expect(find.text(school.name), findsWidgets);
      }
    });

    testWidgets('for schools', (tester) async {
      await _pumpPage(tester, const ForSchoolsPage());
      expect(find.text('MANAGE TEAMS'), findsOneWidget);
      expect(find.text('POST RESULTS'), findsOneWidget);
      expect(find.text('MATCH HISTORY'), findsOneWidget);
    });

    testWidgets('help centre', (tester) async {
      await _pumpPage(tester, const HelpPage());
      expect(find.text('GETTING STARTED'), findsOneWidget);
      // The first topic opens by default, so an answer is visible on arrival.
      expect(find.textContaining('Register School in the top bar'), findsOneWidget);
    });

    testWidgets('every policy', (tester) async {
      for (final policy in Policy.values) {
        await _pumpPage(tester, PolicyPage(policy: policy));
        expect(tester.takeException(), isNull, reason: '${policy.title} threw');
        expect(find.text(policy.title), findsWidgets);
        expect(find.textContaining('Working draft'), findsOneWidget);
      }
    });

    testWidgets('password reset refuses an address that is not one', (tester) async {
      await _pumpPage(tester, const ForgotPasswordPage());
      await tester.tap(find.text('SEND CODE'));
      await tester.pumpAndSettle();
      expect(find.text('Required'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), 'not-an-email');
      await tester.tap(find.text('SEND CODE'));
      await tester.pumpAndSettle();
      expect(find.text('Enter a valid email address'), findsOneWidget);
      expect(find.text('Enter your code'), findsNothing);
    });
  });

  testWidgets('controls for external destinations match what is configured', (tester) async {
    // Written against SiteLinks rather than against today's values, so filling
    // a real address in changes the page without breaking this.
    await _pumpPage(tester, const LandingPage(), size: const Size(1400, 3000));

    expect(find.text('APP STORE'), findsOneWidget);
    expect(find.text('GOOGLE PLAY STORE'), findsOneWidget);
    expect(
      find.text('Coming soon to'),
      SiteLinks.has(SiteLinks.appStore) && SiteLinks.has(SiteLinks.playStore)
          ? findsNothing
          : findsWidgets,
      reason: 'a store badge should say so until its listing exists',
    );

    await _pumpPage(tester, const AboutPage(), size: const Size(1400, 3000));
    expect(
      find.text('OUR STORY IN 60 SECONDS'),
      SiteLinks.has(SiteLinks.storyVideo) ? findsOneWidget : findsNothing,
      reason: 'the story button should only be offered when there is a film behind it',
    );
  });

  testWidgets('no footer link is a dead end', (tester) async {
    // The whole point of these pages: every link in the footer should open
    // something, rather than raising the "coming soon" notice.
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(TobunApp(matches: MatchStore.sample()));
    await tester.pumpAndSettle();

    final labels = <String>[
      ...['Fixtures', 'Results', 'Standings', 'Rankings', 'For Schools', 'About'],
      ...Sport.values.take(6).map((sport) => sport.label),
      'More Sports',
      ...[
        'Register Your School',
        'Manage Teams',
        'Create a Match',
        'Post Results',
        'Manage Fixtures',
        'View Match History',
      ],
      ...[
        'Help Centre',
        'Contact Us',
        'Report a Problem',
        'Safety & Guidelines',
        'Terms & Conditions',
        'Privacy Policy',
        'FAQs',
      ],
    ];

    for (final label in labels) {
      // A fresh key forces a new element tree, and so a new navigator. Pumping
      // the same widget again would leave us on whatever the last link opened,
      // and the auth pages carry no footer to find the next link in.
      await tester.pumpWidget(TobunApp(key: ValueKey(label), matches: MatchStore.sample()));
      await tester.pumpAndSettle();

      final link = find.text(label);
      expect(link, findsWidgets, reason: '"$label" is not in the footer any more');

      await tester.ensureVisible(link.last);
      await tester.pumpAndSettle();
      await tester.tap(link.last, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(
        find.text('Coming soon'),
        findsNothing,
        reason: '"$label" still has no page behind it',
      );
    }
  });
}
