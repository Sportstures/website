import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:website/api/api_client.dart';
import 'package:website/api/session.dart';
import 'package:website/pages/auth/forgot_password_page.dart';

http.Response _json(int status, Object? body) =>
    http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json'});

class _Backend {
  http.Response? resetError;
  final seen = <http.Request>[];

  http.Response handle(http.Request r) {
    seen.add(r);
    if (r.url.path == '/api/auth/forgot-password') return _json(200, {'message': 'ok', 'retryAfterSeconds': 60});
    if (r.url.path == '/api/auth/reset-password') return resetError ?? _json(200, {'message': 'done'});
    return _json(404, {'error': {'code': 'NOT_FOUND', 'message': 'no'}});
  }

  Iterable<http.Request> sent(String path) => seen.where((r) => r.url.path == path);
}

Future<_Backend> _pump(WidgetTester tester, {_Backend? backend}) async {
  tester.view.physicalSize = const Size(1400, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final b = backend ?? _Backend();
  final session = Session(ApiClient(baseUrl: 'http://api.test', httpClient: MockClient((r) async => b.handle(r))));
  await tester.pumpWidget(SessionScope(session: session, child: const MaterialApp(home: ForgotPasswordPage())));
  await tester.pumpAndSettle();
  return b;
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Finder _field(String label) => find.byKey(ValueKey(label));

Future<void> _toCodeStep(WidgetTester tester) async {
  await tester.enterText(_field('Email address'), ' coach@school.co.za ');
  await _tap(tester, find.text('SEND CODE'));
}

Future<void> _fill(WidgetTester tester, {String code = '123456', String password = 'Sipho2026', String? again}) async {
  await tester.enterText(_field('6-digit code'), code);
  await tester.enterText(_field('New password'), password);
  await tester.enterText(_field('Repeat new password'), again ?? password);
  await _tap(tester, find.text('SET NEW PASSWORD'));
}

void main() {
  testWidgets('asks the server to email a code', (tester) async {
    final b = await _pump(tester);
    await _toCodeStep(tester);
    expect(jsonDecode(b.sent('/api/auth/forgot-password').single.body), {'email': 'coach@school.co.za'});
    expect(find.text('Enter your code'), findsOneWidget);
    expect(find.textContaining('If an account exists for coach@school.co.za'), findsOneWidget);
  });

  testWidgets('sets the new password with the code', (tester) async {
    final b = await _pump(tester);
    await _toCodeStep(tester);
    await _fill(tester);
    expect(jsonDecode(b.sent('/api/auth/reset-password').single.body),
        {'email': 'coach@school.co.za', 'code': '123456', 'newPassword': 'Sipho2026'});
    expect(find.text('Password changed'), findsOneWidget);
  });

  testWidgets('checks the code and passwords before sending', (tester) async {
    final b = await _pump(tester);
    await _toCodeStep(tester);
    await _fill(tester, code: '12', password: 'short', again: 'other');
    expect(find.text('Enter the 6 digits from the email'), findsOneWidget);
    expect(find.text('Password must be at least 8 characters'), findsOneWidget);
    expect(find.text('The passwords do not match'), findsOneWidget);
    expect(b.sent('/api/auth/reset-password'), isEmpty);
  });

  testWidgets('a wrong code is explained and a new one can be sent', (tester) async {
    final b = _Backend()..resetError = _json(400, {'error': {'code': 'INVALID_OTP', 'message': 'x'}});
    await _pump(tester, backend: b);
    await _toCodeStep(tester);
    await _fill(tester);
    expect(find.textContaining('That code is wrong or has expired'), findsOneWidget);
    await _tap(tester, find.text('Send a new code'));
    expect(b.sent('/api/auth/forgot-password'), hasLength(2));
    expect(find.textContaining('We sent a new code'), findsOneWidget);
  });
}
