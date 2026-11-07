import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:website/data/sports_data.dart';
import 'package:website/widgets/site/ai_analysis_view.dart';

/// Pumps [child] inside just enough app to render.
Future<void> _pump(WidgetTester tester, Widget child, {double width = 520}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(width: width, child: SingleChildScrollView(child: child)),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  final fixture = SportsData.instance.fixtures.first;

  testWidgets('the outcome bar is actually drawn', (tester) async {
    // It collapsed to zero height once: a ColoredBox with no child takes the
    // smallest size offered, and a Row centres its children by default, so the
    // segments were laid out at height zero and the bar vanished while the
    // percentages underneath still read correctly.
    await _pump(tester, AiAnalysisView(fixture: fixture));

    final segments = find.descendant(
      of: find.byType(ClipRRect),
      matching: find.byType(ColoredBox),
    );
    expect(segments, findsWidgets, reason: 'the bar should have at least one segment');

    for (final element in segments.evaluate()) {
      final size = (element.renderObject! as RenderBox).size;
      expect(size.height, greaterThan(0), reason: 'a bar segment rendered with no height');
      expect(size.width, greaterThan(0), reason: 'a bar segment rendered with no width');
    }
  });

  testWidgets('the analysis renders without overflowing a narrow sidebar', (tester) async {
    await _pump(tester, AiAnalysisView(fixture: fixture, compact: true), width: 280);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the full analysis renders without overflowing the dialog', (tester) async {
    await _pump(tester, AiAnalysisView(fixture: fixture), width: 520);
    expect(tester.takeException(), isNull);
    expect(find.textContaining('%'), findsWidgets);
  });
}
