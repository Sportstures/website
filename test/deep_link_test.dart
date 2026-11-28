import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:website/api/api_client.dart';
import 'package:website/api/session.dart';
import 'package:website/data/match_store.dart';
import 'package:website/main.dart';
import 'package:website/pages/signup/signup_page.dart';

/// Opening the website straight at an address, as a visitor following a link does.
void main() {
  testWidgets('an invitation link opens sign-up with the invitation', (tester) async {
    tester.view.physicalSize = const Size(1400, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.defaultRouteNameTestValue = '/signup?invite=abc123';
    addTearDown(tester.platformDispatcher.clearDefaultRouteNameTestValue);

    final looked = <String>[];
    final session = Session(ApiClient(
      baseUrl: 'http://api.test',
      httpClient: MockClient((r) async {
        if (r.url.path.startsWith('/api/invitations/')) {
          looked.add(r.url.pathSegments.last);
          return http.Response(
              jsonEncode({'valid': true, 'inviterName': 'Sipho Williams', 'schoolName': 'Jeppe High', 'email': null}), 200);
        }
        return http.Response('{}', 404);
      }),
    ));
    await tester.pumpWidget(TobunApp(session: session, matches: MatchStore.sample()));
    await tester.pumpAndSettle();

    expect(find.byType(SignupPage), findsOneWidget);
    expect(looked, ['abc123']);
    expect(find.textContaining('invited you to join Sportstures'), findsOneWidget);
  });
}
