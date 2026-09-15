import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:website/main.dart';

Future<void> _pick(WidgetTester tester, String hint, String option) async {
  await tester.tap(find.text(hint));
  await tester.pumpAndSettle();
  await tester.tap(find.text(option).last);
  await tester.pumpAndSettle();
}

Future<void> _tapNext(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Next Step'));
  await tester.tap(find.text('Next Step'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('nav bar opens the fixtures and results pages', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const TobunApp());
    expect(find.text('UPCOMING FIXTURES'), findsOneWidget);

    await tester.tap(find.text('Fixtures').first);
    await tester.pumpAndSettle();
    expect(find.text('Search fixtures'), findsOneWidget);

    await tester.tap(find.text('Results').first);
    await tester.pumpAndSettle();
    expect(find.text('Search results'), findsOneWidget);
    expect(find.text('TOP STANDINGS'), findsOneWidget);

    await tester.tap(find.text('Standings').first);
    await tester.pumpAndSettle();
    expect(find.text('LEAGUE TABLE'), findsOneWidget);

    await tester.tap(find.text('Rankings').first);
    await tester.pumpAndSettle();
    expect(find.text('RANKING BREAKDOWN'), findsOneWidget);

    await tester.tap(find.text('For Schools').first);
    await tester.pumpAndSettle();
    expect(find.text('BROWSE BY REGION'), findsOneWidget);

    await tester.tap(find.text('About').first);
    await tester.pumpAndSettle();
    expect(find.text('Our Mission & Vision'), findsOneWidget);

    await tester.tap(find.text('Contact').first);
    await tester.pumpAndSettle();
    expect(find.text('SEND US A MESSAGE'), findsOneWidget);
  });

  testWidgets('sign-up flow validates and moves through the first three steps',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const TobunApp());
    await tester.tap(find.text('LOGIN'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Register and Sign up'));
    await tester.pumpAndSettle();
    expect(find.text('Create an account'), findsOneWidget);

    // An empty form can't move on.
    await _tapNext(tester);
    expect(find.text('Create an account'), findsOneWidget);
    expect(find.text('Required'), findsWidgets);

    // Step 1: personal info
    await tester.enterText(find.widgetWithText(TextFormField, 'e.g. John'), 'Jim');
    await tester.enterText(find.widgetWithText(TextFormField, 'e.g. Doe'), 'Mokoena');
    await _pick(tester, 'Day', '3');
    await _pick(tester, 'Month', 'March');
    await _pick(tester, 'Year', '${DateTime.now().year - 10}');
    await _tapNext(tester);
    expect(find.text('School details'), findsOneWidget);

    // Step 2: school details
    await _pick(tester, 'Select your school', 'Greenwood Academy');
    await _pick(tester, 'Select your province', 'Gauteng');
    await tester.enterText(find.widgetWithText(TextFormField, 'e.g. GRW-2024'), 'GRW-2024');
    await _pick(tester, 'Select your role', 'Coach');
    await _tapNext(tester);
    expect(find.text('Account setup'), findsOneWidget);

    // Step 3: mismatched passwords are rejected.
    final passwordFields = find.byType(TextFormField);
    await tester.enterText(passwordFields.at(0), 'coach.jim@greenwood.com');
    await tester.enterText(passwordFields.at(1), 'coach_jim');
    await tester.enterText(passwordFields.at(2), 'password123');
    await tester.enterText(passwordFields.at(3), 'password124');
    await _tapNext(tester);
    expect(find.text('Passwords do not match'), findsOneWidget);

    // Back keeps what was entered earlier.
    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();
    expect(find.text('School details'), findsOneWidget);
    expect(find.text('GRW-2024'), findsOneWidget);
    expect(find.text('Greenwood Academy'), findsOneWidget);

    // Login link returns to the login page.
    await tester.ensureVisible(find.text('Login'));
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome Back'), findsOneWidget);
  });
}
