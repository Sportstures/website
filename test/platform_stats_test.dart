import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:website/api/api_client.dart';
import 'package:website/data/match_store.dart';
import 'package:website/pages/about/about_page.dart';
import 'package:website/pages/for_schools/for_schools_page.dart';

ApiClient _api({bool down = false}) => ApiClient(
      baseUrl: 'http://api.test',
      httpClient: MockClient((r) async {
        if (down) return http.Response('{}', 500);
        final body = switch (r.url.path) {
          '/api/schools' => {'schools': [], 'total': 15},
          '/api/schools/filters' => {
              'provinces': [{'name': 'Gauteng', 'schoolCount': 6}, {'name': 'Limpopo', 'schoolCount': 0}],
              'sports': [{'id': 1, 'name': 'Football', 'schoolCount': 6}],
            },
          _ => {'summary': {'matchesPlayed': 65}, 'days': []},
        };
        return http.Response(jsonEncode(body), 200);
      }),
    );

Future<void> _pump(WidgetTester tester, Widget page, ApiClient api) async {
  tester.view.physicalSize = const Size(1400, 4000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MatchScope(store: MatchStore.api(api), child: MaterialApp(home: page)));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('About shows the real counts, without athlete numbers', (tester) async {
    await _pump(tester, const AboutPage(), _api());
    expect(find.text('15'), findsOneWidget);
    expect(find.text('65'), findsOneWidget);
    expect(find.textContaining(RegExp('student athletes', caseSensitive: false)), findsNothing);
  });

  testWidgets('For Schools shows the real counts', (tester) async {
    await _pump(tester, const ForSchoolsPage(), _api());
    expect(find.text('15'), findsOneWidget);
    expect(find.text('65'), findsOneWidget);
    expect(find.text('Free'), findsOneWidget);
  });

  testWidgets('with the backend down no made-up figures appear', (tester) async {
    await _pump(tester, const ForSchoolsPage(), _api(down: true));
    expect(find.text('Free'), findsNothing);
    expect(find.textContaining(RegExp('schools on board', caseSensitive: false)), findsNothing);
  });
}
