import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:website/api/api_client.dart';
import 'package:website/api/session.dart';
import 'package:website/pages/coach/coach_photos_card.dart';
import 'package:website/pages/coach/photo_badge.dart';

http.Response _json(int status, Object? body) =>
    http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json'});

class _Backend {
  String? logoUrl;
  String? avatarUrl;
  http.Response? uploadError;
  final seen = <http.Request>[];

  http.Response handle(http.Request r) {
    seen.add(r);
    final path = r.url.path;
    if (path == '/api/auth/login') {
      return _json(200, {
        'accessToken': 'A',
        'refreshToken': 'R',
        'user': {'id': 7, 'role': 'coach', 'firstName': 'Thabo', 'lastName': 'Dlamini'},
      });
    }
    if (path == '/api/auth/me') return _json(200, {'user': {'id': 7, 'avatarUrl': avatarUrl}});
    if (path == '/api/teams/8' && r.method == 'GET') return _json(200, {'team': {'id': 8, 'logoUrl': logoUrl}});
    if (r.method == 'PUT' && (path == '/api/teams/8/logo' || path == '/api/me/avatar')) {
      if (uploadError != null) return uploadError!;
      final url = 'https://img.test${path.replaceAll('/', '_')}.png';
      if (path.endsWith('logo')) {
        logoUrl = url;
        return _json(200, {'logoUrl': url});
      }
      avatarUrl = url;
      return _json(200, {'avatarUrl': url});
    }
    if (r.method == 'DELETE' && path == '/api/teams/8/logo') {
      logoUrl = null;
      return _json(200, {'logoUrl': null});
    }
    if (r.method == 'DELETE' && path == '/api/me/avatar') {
      avatarUrl = null;
      return _json(200, {'avatarUrl': null});
    }
    return _json(404, {'error': {'code': 'NOT_FOUND', 'message': 'no'}});
  }

  Iterable<http.Request> sent(String method, String path) => seen.where((r) => r.method == method && r.url.path == path);
}

Future<_Backend> _pump(WidgetTester tester, {_Backend? backend}) async {
  tester.view.physicalSize = const Size(1400, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final b = backend ?? _Backend();
  final session = Session(ApiClient(baseUrl: 'http://api.test', httpClient: MockClient((r) async => b.handle(r))));
  await session.login('coach@x.com', 'Passw0rdOK');
  await tester.pumpWidget(SessionScope(
    session: session,
    child: MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: CoachPhotosCard(
            teamId: 8,
            teamName: 'Protea Glen Football',
            coachName: 'Thabo Dlamini',
            pick: () async => (bytes: <int>[0x89, 0x50, 0x4e, 0x47, 1, 2, 3], name: 'crest.png'),
          ),
        ),
      ),
    ),
  ));
  await tester.pumpAndSettle();
  return b;
}

void main() {
  testWidgets('with no images yet it shows initials and an upload button for each', (tester) async {
    await _pump(tester);
    expect(find.text('PG'), findsOneWidget); // Protea Glen
    expect(find.text('TD'), findsOneWidget); // Thabo Dlamini
    expect(find.text('UPLOAD'), findsNWidgets(2));
    expect(find.text('Remove'), findsNothing);
  });

  testWidgets('uploading a team logo sends the image to the team and shows the change option', (tester) async {
    final b = await _pump(tester);
    await tester.tap(find.text('UPLOAD').first);
    await tester.pumpAndSettle();

    final put = b.sent('PUT', '/api/teams/8/logo').single;
    expect(put.headers['content-type'], startsWith('multipart/form-data'));
    expect(put.headers['Authorization'], 'Bearer A');
    expect(put.bodyBytes.length, greaterThan(7));
    expect(find.text('CHANGE'), findsOneWidget);
    expect(find.text('Remove'), findsOneWidget);
    expect(b.sent('PUT', '/api/me/avatar'), isEmpty, reason: 'the profile photo was left alone');
  });

  testWidgets('uploading my own photo uses the profile photo endpoint', (tester) async {
    final b = await _pump(tester);
    await tester.tap(find.text('UPLOAD').last);
    await tester.pumpAndSettle();
    expect(b.sent('PUT', '/api/me/avatar'), hasLength(1));
    expect(b.sent('PUT', '/api/teams/8/logo'), isEmpty);
  });

  testWidgets('existing images are loaded, and can be removed', (tester) async {
    final b = _Backend()
      ..logoUrl = 'https://img.test/logo.png'
      ..avatarUrl = 'https://img.test/me.png';
    await _pump(tester, backend: b);
    expect(find.text('CHANGE'), findsNWidgets(2));

    await tester.tap(find.text('Remove').first);
    await tester.pumpAndSettle();
    expect(b.sent('DELETE', '/api/teams/8/logo'), hasLength(1));
    expect(find.text('UPLOAD'), findsOneWidget);
  });

  testWidgets('a too-large image shows a clear message', (tester) async {
    final b = _Backend()..uploadError = _json(413, {'error': {'code': 'FILE_TOO_LARGE', 'message': 'big'}});
    await _pump(tester, backend: b);
    await tester.tap(find.text('UPLOAD').first);
    await tester.pumpAndSettle();
    expect(find.text('That image is over 5 MB. Choose a smaller one.'), findsOneWidget);
    expect(find.text('UPLOAD'), findsNWidgets(2), reason: 'nothing changed');
  });

  testWidgets('PhotoBadge falls back to initials when there is no image', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: PhotoBadge(fallback: 'Jeppe High School')));
    expect(find.text('JH'), findsOneWidget);
  });
}
