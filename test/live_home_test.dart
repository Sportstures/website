import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:website/ai/ai_provider.dart';
import 'package:website/ai/local_ai_service.dart';
import 'package:website/api/api_client.dart';
import 'package:website/api/session.dart';
import 'package:website/data/match_store.dart';
import 'package:website/main.dart';

http.Response _json(int status, Object? body) =>
    http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json'});

Map<String, dynamic> _team(int id, String school) => {
      'id': id,
      'name': '$school Football',
      'level': 'u16',
      'sport': {'id': 1, 'name': 'Football'},
      'school': {'id': id, 'name': school, 'province': 'Gauteng', 'town': null},
    };

class _Backend {
  bool down = false;
  bool empty = false;
  final seen = <http.Request>[];

  http.Response handle(http.Request r) {
    seen.add(r);
    if (down) return _json(500, {'error': {'code': 'INTERNAL', 'message': 'boom'}});
    if (r.url.path == '/api/fixtures') {
      final upcoming = r.url.queryParameters['when'] == 'upcoming' && !empty;
      return _json(200, {
        'fixtures': [
          if (upcoming)
            {
              'id': 1,
              'matchDate': DateTime.now().add(const Duration(days: 3)).toUtc().toIso8601String(),
              'status': 'scheduled',
              'matchType': 'friendly',
              'sport': {'id': 1, 'name': 'Football'},
              'homeTeam': _team(1, 'Live Home High'),
              'awayTeam': _team(2, 'Live Away College'),
              'score': null,
            },
        ],
      });
    }
    if (r.url.path == '/api/rankings') {
      return _json(200, {
        'rankings': empty ? [] : [{'position': 1, 'name': 'Western Cape', 'points': 1550, 'schoolsRanked': 4}],
        'total': empty ? 0 : 1,
      });
    }
    return _json(404, {'error': {'code': 'NOT_FOUND', 'message': 'no'}});
  }
}

Future<_Backend> _pump(WidgetTester tester, {_Backend? backend}) async {
  tester.view.physicalSize = const Size(1400, 4000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final b = backend ?? _Backend();
  final api = ApiClient(baseUrl: 'http://api.test', httpClient: MockClient((r) async => b.handle(r)));
  await tester.pumpWidget(TobunApp(session: Session(api), matches: MatchStore.api(api)));
  await tester.pumpAndSettle();
  return b;
}

void main() {
  tearDown(() => aiService = const LocalAiService());

  testWidgets('the home page shows live fixtures and regions', (tester) async {
    final b = await _pump(tester);
    expect(find.textContaining('Live Home High'), findsWidgets);
    expect(find.text('Western Cape'), findsOneWidget);
    expect(b.seen.where((r) => r.url.path == '/api/rankings').single.url.queryParameters['type'], 'regions');
  });

  testWidgets('an empty platform says so instead of showing sample matches', (tester) async {
    await _pump(tester, backend: _Backend()..empty = true);
    expect(find.text('No upcoming fixtures yet.'), findsOneWidget);
    expect(find.text('No results yet.'), findsOneWidget);
  });

  testWidgets('when the backend is down both cards say so and can be retried', (tester) async {
    final b = _Backend()..down = true;
    await _pump(tester, backend: b);
    expect(find.text("Fixtures couldn't be loaded."), findsOneWidget);
    expect(find.text("Rankings couldn't be loaded."), findsOneWidget);
    b.down = false;
    await tester.ensureVisible(find.text('TRY AGAIN').first);
    await tester.tap(find.text('TRY AGAIN').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('Live Home High'), findsWidgets);
    expect(find.text('Western Cape'), findsOneWidget);
  });
}
