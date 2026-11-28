import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:website/api/api_client.dart';
import 'package:website/api/session.dart';
import 'package:website/pages/contact/widgets/contact_form_card.dart';

class _Backend {
  http.Response? error;
  final seen = <http.Request>[];

  http.Response handle(http.Request r) {
    seen.add(r);
    return error ?? http.Response(jsonEncode({'id': 12, 'message': "Thanks. We'll reply to ada@example.com."}), 201);
  }
}

Future<_Backend> _pump(WidgetTester tester, {_Backend? backend}) async {
  tester.view.physicalSize = const Size(900, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final b = backend ?? _Backend();
  final session = Session(ApiClient(baseUrl: 'http://api.test', httpClient: MockClient((r) async => b.handle(r))));
  await tester.pumpWidget(SessionScope(
    session: session,
    child: const MaterialApp(home: Scaffold(body: SingleChildScrollView(child: ContactFormCard()))),
  ));
  await tester.pumpAndSettle();
  return b;
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _fill(WidgetTester tester, {String message = 'Our fixtures are missing.'}) async {
  final fields = find.byType(TextFormField);
  await tester.enterText(fields.at(0), 'Ada Obi');
  await tester.enterText(fields.at(1), 'ada@example.com');
  await _tap(tester, find.text('What is this regarding?'));
  await _tap(tester, find.text('Fixtures & results').last);
  await _tap(tester, find.text('Technical Support'));
  await tester.enterText(fields.at(2), message);
  await _tap(tester, find.text('SEND MESSAGE'));
}

void main() {
  testWidgets('the message is sent to support, and the form clears', (tester) async {
    final b = await _pump(tester);
    await _fill(tester);
    final r = b.seen.single;
    expect(r.url.path, '/api/support/messages');
    expect(r.headers.containsKey('Authorization'), isFalse);
    expect(jsonDecode(r.body), {
      'topic': 'matches',
      'subject': 'Fixtures & results (Technical Support)',
      'message': 'Our fixtures are missing.',
      'name': 'Ada Obi',
      'email': 'ada@example.com',
      'app': {'platform': 'web'},
    });
    expect(find.text("Thanks. We'll reply to ada@example.com."), findsOneWidget);
    expect(find.text('Ada Obi'), findsNothing);
  });

  testWidgets('a message under 10 characters is not sent', (tester) async {
    final b = await _pump(tester);
    await _fill(tester, message: 'Help');
    expect(find.text('Please write at least 10 characters'), findsOneWidget);
    expect(b.seen, isEmpty);
  });

  testWidgets('if it cannot be sent, it says so and keeps the message', (tester) async {
    final b = _Backend()..error = http.Response('{}', 500);
    await _pump(tester, backend: b);
    await _fill(tester);
    expect(find.textContaining('Sportstures had a problem'), findsOneWidget);
    expect(find.text('Our fixtures are missing.'), findsOneWidget);
    expect(find.textContaining('Thanks'), findsNothing);
  });
}
