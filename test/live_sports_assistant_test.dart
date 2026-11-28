import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:website/ai/ai_provider.dart';
import 'package:website/ai/local_ai_service.dart';
import 'package:website/api/api_client.dart';
import 'package:website/data/match_store.dart';
import 'package:website/data/models.dart';
import 'package:website/pages/sports/sport_page.dart';

Map<String, dynamic> _team(int id, String school) => {
      'id': id,
      'name': '$school Football',
      'level': 'u16',
      'sport': {'id': 1, 'name': 'Football'},
      'school': {'id': id, 'name': school, 'province': 'Gauteng', 'town': null},
    };

Map<String, dynamic> _fixture(int id, {int? home, int? away}) => {
      'id': id,
      'matchDate': DateTime.now().add(Duration(days: home == null ? 3 : -3)).toUtc().toIso8601String(),
      'status': home == null ? 'scheduled' : 'finished',
      'matchType': 'friendly',
      'sport': {'id': 1, 'name': 'Football'},
      'homeTeam': _team(1, 'Zebra Valley High'),
      'awayTeam': _team(2, 'Quartz Ridge College'),
      'score': home == null ? null : {'home': home, 'away': away},
    };

ApiClient _api({bool down = false}) => ApiClient(
      baseUrl: 'http://api.test',
      httpClient: MockClient((r) async {
        if (down) return http.Response('{}', 500);
        final upcoming = r.url.queryParameters['when'] == 'upcoming';
        return http.Response(jsonEncode({'fixtures': [upcoming ? _fixture(1) : _fixture(2, home: 3, away: 1)]}), 200);
      }),
    );

void main() {
  tearDown(() => aiService = const LocalAiService());

  testWidgets('a sport page shows live matches and schools', (tester) async {
    tester.view.physicalSize = const Size(1400, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MatchScope(
      store: MatchStore.api(_api()),
      child: const MaterialApp(home: SportPage(sport: Sport.football)),
    ));
    await tester.pumpAndSettle();
    expect(find.textContaining('2 schools play football'), findsOneWidget);
    expect(find.textContaining('Zebra Valley High'), findsWidgets);
    expect(find.textContaining('Northview'), findsNothing);
  });

  group('the assistant on live data', () {
    Future<void> load() => MatchStore.api(_api()).ensureLoaded();

    test('knows the live schools and not the sample ones', () async {
      await load();
      final answer = await aiService.ask('How is Zebra Valley High doing?');
      expect(answer.text, contains('Zebra Valley High have won 1'));
      expect(aiService.starterQuestions().join(' '), isNot(contains('Northview')));

      final about = await aiService.ask('Tell me about Quartz Ridge College');
      expect(about.text, contains('Quartz Ridge College'));
      expect(about.text, isNot(contains('athletes')));

      final unknown = await aiService.ask('How is Northview High doing?');
      expect(unknown.text, isNot(contains('Northview High have')));
    });

    test('examples use real schools', () async {
      await load();
      final help = await aiService.ask('qqq');
      final examples = help.insights.map((i) => i.detail).join(' ');
      expect(examples, contains('Quartz Ridge College'));
      expect(examples, isNot(contains('Lakeside')));
    });

    test('two callers share one load, and both wait for it', () async {
      var calls = 0;
      final gate = Completer<void>();
      final store = MatchStore.api(ApiClient(
        baseUrl: 'http://api.test',
        httpClient: MockClient((r) async {
          calls++;
          await gate.future;
          return http.Response(jsonEncode({'fixtures': []}), 200);
        }),
      ));
      final first = store.ensureLoaded();
      var secondDone = false;
      final second = store.ensureLoaded().then((_) => secondDone = true);
      await Future<void>.delayed(Duration.zero);
      expect(secondDone, isFalse);
      gate.complete();
      await Future.wait([first, second]);
      expect(store.data, isNotNull);
      expect(calls, 2, reason: 'one request each for upcoming and past');
    });

    test('an empty platform has no made-up schools', () async {
      final store = MatchStore.api(ApiClient(
        baseUrl: 'http://api.test',
        httpClient: MockClient((r) async => http.Response(jsonEncode({'fixtures': []}), 200)),
      ));
      await store.ensureLoaded();
      expect(aiService.starterQuestions().any((q) => q.startsWith('How is')), isFalse);
      final answer = await aiService.ask('Who is top in football?');
      expect(answer.text, contains('No football has been played'));
    });
  });
}
