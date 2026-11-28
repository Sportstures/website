import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:website/api/api_client.dart';
import 'package:website/api/notifications_api.dart';
import 'package:website/api/session.dart';
import 'package:website/pages/coach/coach_notifications_page.dart';

http.Response _json(int status, Object? body) =>
    http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json'});

Map<String, dynamic> _note(int id, String type, String title, {bool read = false, int? fixtureId}) => {
      'id': id,
      'type': type,
      'title': title,
      'body': 'Details $id',
      'data': {'fixtureId': ?fixtureId},
      'read': read,
      'createdAt': '2026-11-20T10:00:00.000Z',
    };

class _Backend {
  List<Map<String, dynamic>> notes = [
    _note(1, 'match_invitation_received', 'Eastgate invited you to a match'),
    _note(2, 'fixture_postponed', 'Match postponed', read: true, fixtureId: 5),
  ];
  Map<String, bool> settings = {'matchInvitations': true, 'goalConfirmations': true, 'fixtureChanges': true, 'matchResults': true};
  bool failSettingsSave = false;
  final seen = <http.Request>[];

  int get unread => notes.where((n) => n['read'] == false).length;

  http.Response handle(http.Request r) {
    seen.add(r);
    final path = r.url.path;
    if (path == '/api/auth/login') {
      return _json(200, {'accessToken': 'A', 'refreshToken': 'R', 'user': {'id': 7, 'role': 'coach', 'firstName': 'Thabo'}});
    }
    if (path == '/api/me/notifications' && r.method == 'GET') {
      return _json(200, {'notifications': notes, 'unreadCount': unread, 'hasMore': false});
    }
    if (path == '/api/me/notifications/read-all') {
      for (final n in notes) {
        n['read'] = true;
      }
      return _json(200, {'marked': 1, 'unreadCount': 0});
    }
    if (path == '/api/me/notifications/settings') {
      if (r.method == 'PUT') {
        if (failSettingsSave) return _json(500, {'error': {'code': 'ERR', 'message': 'Could not save that'}});
        settings.addAll(Map<String, bool>.from(jsonDecode(r.body) as Map));
      }
      return _json(200, {'settings': settings});
    }
    final one = RegExp(r'^/api/me/notifications/(\d+)(/read)?$').firstMatch(path);
    if (one != null) {
      final id = int.parse(one.group(1)!);
      if (r.method == 'DELETE') {
        notes.removeWhere((n) => n['id'] == id);
      } else {
        notes.firstWhere((n) => n['id'] == id)['read'] = true;
      }
      return _json(200, {'unreadCount': unread});
    }
    return _json(404, {'error': {'code': 'NOT_FOUND', 'message': 'no'}});
  }

  Iterable<http.Request> sent(String method, String path) => seen.where((r) => r.method == method && r.url.path == path);
}

/// The names of the pages a tap asked for.
final _opened = <String?>[];

Future<_Backend> _pump(WidgetTester tester, {_Backend? backend}) async {
  _opened.clear();
  tester.view.physicalSize = const Size(1400, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final b = backend ?? _Backend();
  final session = Session(ApiClient(baseUrl: 'http://api.test', httpClient: MockClient((r) async => b.handle(r))));
  await session.login('coach@x.com', 'Passw0rdOK');
  await tester.pumpWidget(SessionScope(
    session: session,
    child: MaterialApp(
      home: const CoachNotificationsPage(),
      onGenerateRoute: (settings) {
        _opened.add(settings.name);
        return MaterialPageRoute<void>(settings: settings, builder: (_) => const Scaffold());
      },
    ),
  ));
  await tester.pumpAndSettle();
  return b;
}

/// Takes the page down so its polling timer stops before the test ends.
Future<void> _close(WidgetTester tester) => tester.pumpWidget(const SizedBox());

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the inbox, the unread count and only the coach settings', (tester) async {
    await _pump(tester);
    expect(find.text('INBOX · 1 UNREAD'), findsOneWidget);
    expect(find.text('Eastgate invited you to a match'), findsOneWidget);
    expect(find.byType(SwitchListTile), findsNWidgets(3));
    await _close(tester);
  });

  testWidgets('tapping one marks it read and opens the right page', (tester) async {
    final b = await _pump(tester);
    await _tap(tester, find.text('Eastgate invited you to a match'));
    expect(b.sent('PUT', '/api/me/notifications/1/read'), hasLength(1));
    expect(_opened, ['/coach/match-invitations']);
    await _close(tester);
  });

  testWidgets('mark all read and delete', (tester) async {
    final b = await _pump(tester);
    await _tap(tester, find.text('Mark all read'));
    expect(find.text('INBOX'), findsOneWidget);
    await _tap(tester, find.byTooltip('Delete notification').first);
    expect(b.sent('DELETE', '/api/me/notifications/1'), hasLength(1));
    expect(find.text('Eastgate invited you to a match'), findsNothing);
    await _close(tester);
  });

  testWidgets('switching a setting saves only that one', (tester) async {
    final b = await _pump(tester);
    await _tap(tester, find.text('Scores to confirm'));
    expect(jsonDecode(b.sent('PUT', '/api/me/notifications/settings').single.body), {'goalConfirmations': false});
    await _close(tester);
  });

  testWidgets('a setting that fails to save goes back and says why', (tester) async {
    final b = _Backend()..failSettingsSave = true;
    await _pump(tester, backend: b);
    await _tap(tester, find.text('Match changes'));
    expect(find.text('Could not save that'), findsOneWidget);
    expect(tester.widget<SwitchListTile>(find.widgetWithText(SwitchListTile, 'Match changes')).value, isTrue);
    await _close(tester);
  });

  testWidgets('new notifications appear by themselves', (tester) async {
    final b = await _pump(tester);
    b.notes = [_note(3, 'goal_confirmation_needed', 'Confirm a goal', fixtureId: 9), ...b.notes];
    await tester.pump(notificationPollInterval);
    await tester.pumpAndSettle();
    expect(find.text('Confirm a goal'), findsOneWidget);
    await _close(tester);
  });

  test('each kind of notification leads to the right page', () {
    String? to(String type, [int? fixture]) => notificationRoute(AppNotification.fromJson(_note(1, type, 't', fixtureId: fixture)));
    expect(to('match_invitation_accepted', 4), '/coach/match-invitations');
    expect(to('goal_disputed', 4), '/coach/live?fixture=4');
    expect(to('fixture_cancelled', 4), '/coach/matches');
    expect(to('something_else'), isNull);
  });
}
