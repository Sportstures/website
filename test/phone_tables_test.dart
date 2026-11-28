import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:website/data/sports_data.dart';
import 'package:website/pages/standings/widgets/standings_tables.dart';

Future<void> _pump(WidgetTester tester, double width) async {
  tester.view.physicalSize = Size(width, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final standings = SportsData.standingsFor(SportsData.instance.results).take(8).toList();
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: SingleChildScrollView(child: LeagueTable(standings: standings)))));
  expect(tester.takeException(), isNull);
}

void main() {
  testWidgets('a wide screen shows every column', (tester) async {
    await _pump(tester, 900);
    for (final label in ['P', 'W', 'D', 'L', 'GF', 'GA', 'GD', 'PTS']) {
      expect(find.text(label), findsWidgets, reason: label);
    }
  });

  testWidgets('a phone shows played, difference and points without scrolling sideways', (tester) async {
    await _pump(tester, 356);
    for (final label in ['P', 'GD', 'PTS']) {
      expect(find.text(label), findsWidgets, reason: label);
      expect(tester.getTopRight(find.text(label)).dx, lessThanOrEqualTo(356), reason: '$label is on screen');
    }
    expect(find.text('GF'), findsNothing);
    expect(find.byWidgetPredicate((w) => w is SingleChildScrollView && w.scrollDirection == Axis.horizontal), findsNothing);
  });

  testWidgets('no qualification or relegation claims are made', (tester) async {
    await _pump(tester, 900);
    expect(find.textContaining('qualification'), findsNothing);
    expect(find.text('Relegation'), findsNothing);
  });
}
