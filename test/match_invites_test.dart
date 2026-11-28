import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:website/api/api_client.dart';
import 'package:website/api/session.dart';
import 'package:website/pages/coach/coach_match_invites_page.dart';

http.Response _json(int status, Object? body) =>
    http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json'});

Map<String, dynamic> _team(int id, String school, {bool coach = true}) => {
      'id': id,
      'name': '$school Netball',
      'logoUrl': null,
      'sport': {'id': 6, 'name': 'Netball'},
      'school': {'id': id, 'name': school},
      'coach': coach ? {'id': 100 + id, 'name': 'Coach $id'} : null,
    };

Map<String, dynamic> _invitation(int id, {required bool received, String status = 'pending', String other = 'Eastgate College'}) {
  final mine = _team(8, 'Protea Glen');
  final theirs = _team(20 + id, other);
  return {
    'id': id,
    'status': status,
    'direction': received ? 'received' : 'sent',
    'matchDate': DateTime.now().add(const Duration(days: 10)).toUtc().toIso8601String(),
    'matchType': 'friendly',
    'venue': 'Main Field',
    'message': 'Pre-season friendly?',
    'responseMessage': null,
    'invitedBy': {'id': 1, 'name': 'Someone'},
    'homeTeam': received ? theirs : mine,
    'awayTeam': received ? mine : theirs,
    'inviterTeam': received ? theirs : mine,
    'invitedTeam': received ? mine : theirs,
    'canRespond': received && status == 'pending',
    'canCancel': !received && status == 'pending',
  };
}

class _Backend {
  List<Map<String, dynamic>> invitations = [
    _invitation(1, received: true),
    _invitation(2, received: false, other: 'Northview High'),
  ];
  http.Response? sendError;
  final seen = <http.Request>[];

  http.Response handle(http.Request r) {
    seen.add(r);
    final path = r.url.path;
    if (path == '/api/auth/login') {
      return _json(200, {
        'accessToken': 'A',
        'refreshToken': 'R',
        'user': {
          'id': 7,
          'role': 'coach',
          'firstName': 'Thabo',
          'lastName': 'Dlamini',
          'profile': {'team': {'id': 8, 'name': 'Protea Glen Netball'}},
          'team': {'id': 8, 'name': 'Protea Glen Netball'},
        },
      });
    }
    if (path == '/api/match-invitations' && r.method == 'GET') {
      return _json(200, {'invitations': invitations, 'total': invitations.length});
    }
    if (path == '/api/match-invitations' && r.method == 'POST') {
      return sendError ?? _json(201, {'invitation': _invitation(9, received: false)});
    }
    final action = RegExp(r'^/api/match-invitations/(\d+)/(accept|decline|cancel)$').firstMatch(path);
    if (action != null) {
      final i = invitations.firstWhere((x) => x['id'] == int.parse(action.group(1)!));
      i['status'] = {'accept': 'accepted', 'decline': 'declined', 'cancel': 'cancelled'}[action.group(2)];
      i['canRespond'] = false;
      i['canCancel'] = false;
      return _json(200, {'invitation': i});
    }
    if (path == '/api/teams/8') return _json(200, {'team': _team(8, 'Protea Glen')});
    if (path == '/api/teams') {
      return _json(200, {'teams': [_team(30, 'Greenwood Academy'), _team(31, 'Quiet High', coach: false)]});
    }
    return _json(404, {'error': {'code': 'NOT_FOUND', 'message': 'no'}});
  }

  Iterable<http.Request> sent(String method, String path) => seen.where((r) => r.method == method && r.url.path == path);
}

Future<_Backend> _pump(WidgetTester tester, {_Backend? backend}) async {
  tester.view.physicalSize = const Size(1400, 2200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final b = backend ?? _Backend();
  final session = Session(ApiClient(baseUrl: 'http://api.test', httpClient: MockClient((r) async => b.handle(r))));
  await session.login('coach@x.com', 'Passw0rdOK');
  await tester.pumpWidget(SessionScope(session: session, child: const MaterialApp(home: CoachMatchInvitesPage())));
  await tester.pumpAndSettle();
  return b;
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows invitations waiting for an answer and the ones sent', (tester) async {
    await _pump(tester);
    expect(find.text('WAITING FOR YOUR ANSWER'), findsOneWidget);
    expect(find.text('From Eastgate College'), findsOneWidget);
    expect(find.text('To Northview High'), findsOneWidget);
    expect(find.text('ACCEPT'), findsOneWidget);
    expect(find.text('Withdraw'), findsOneWidget);
  });

  testWidgets('accepting confirms the match', (tester) async {
    final b = await _pump(tester);
    await _tap(tester, find.text('ACCEPT'));
    expect(b.sent('POST', '/api/match-invitations/1/accept'), hasLength(1));
    expect(find.textContaining('Match confirmed with Eastgate College'), findsOneWidget);
    expect(find.text('WAITING FOR YOUR ANSWER'), findsNothing);
    expect(find.text('ACCEPTED'), findsOneWidget);
  });

  testWidgets('declining asks first and sends the reason', (tester) async {
    final b = await _pump(tester);
    await _tap(tester, find.text('Decline'));
    await _tap(tester, find.text('Keep it'));
    expect(b.sent('POST', '/api/match-invitations/1/decline'), isEmpty);

    await _tap(tester, find.text('Decline'));
    await tester.enterText(find.widgetWithText(TextField, 'Reason (optional)'), 'Exams that week');
    await _tap(tester, find.text('Decline match'));
    final post = b.sent('POST', '/api/match-invitations/1/decline').single;
    expect(jsonDecode(post.body), {'message': 'Exams that week'});
    expect(find.text('DECLINED'), findsOneWidget);
  });

  testWidgets('a sent invitation can be withdrawn', (tester) async {
    final b = await _pump(tester);
    await _tap(tester, find.text('Withdraw'));
    expect(b.sent('POST', '/api/match-invitations/2/cancel'), hasLength(1));
    expect(find.text('WITHDRAWN'), findsOneWidget);
  });

  testWidgets('only teams of my sport at other schools are offered, and ones without a coach cannot be chosen', (tester) async {
    final b = await _pump(tester);
    final query = b.sent('GET', '/api/teams').first.url.queryParameters;
    expect(query['otherSchools'], 'true');
    expect(query['sportId'], '6');
    expect(find.text('Choose'), findsOneWidget);
    expect(find.text('Invite coach'), findsOneWidget);
    expect(find.textContaining('no coach on Sportstures yet'), findsOneWidget);
  });

  testWidgets('needs a team and a date before sending', (tester) async {
    final b = await _pump(tester);
    await _tap(tester, find.text('SEND MATCH INVITATION'));
    expect(find.text('Choose the team you want to play.'), findsOneWidget);
    await _tap(tester, find.text('Choose'));
    await _tap(tester, find.text('SEND MATCH INVITATION'));
    expect(find.text('Choose the match date.'), findsOneWidget);
    expect(b.sent('POST', '/api/match-invitations'), isEmpty);
  });

  testWidgets('sends the chosen team, date, venue and side', (tester) async {
    final b = await _pump(tester);
    await _tap(tester, find.text('Choose'));
    await _tap(tester, find.text('Choose date'));
    await _tap(tester, find.text('OK')); // a week from today
    await _tap(tester, find.text('They host'));
    await tester.enterText(find.widgetWithText(TextField, 'Venue (optional)'), 'Greenwood Court');
    await _tap(tester, find.text('SEND MATCH INVITATION'));

    final body = jsonDecode(b.sent('POST', '/api/match-invitations').single.body) as Map<String, dynamic>;
    expect(body['teamId'], 8);
    expect(body['opponentTeamId'], 30);
    expect(body['playAt'], 'away');
    expect(body['matchType'], 'friendly');
    expect(body['venue'], 'Greenwood Court');
    expect(body.containsKey('message'), isFalse);
    expect(body['matchDate'], endsWith('Z'));
    final when = DateTime.parse(body['matchDate'] as String).toLocal();
    expect(when.hour, 15);
    expect(find.textContaining('Invitation sent to Greenwood Academy'), findsOneWidget);
  });

  testWidgets('a duplicate invitation is explained', (tester) async {
    final b = _Backend()..sendError = _json(409, {'error': {'code': 'INVITATION_EXISTS', 'message': 'x'}});
    await _pump(tester, backend: b);
    await _tap(tester, find.text('Choose'));
    await _tap(tester, find.text('Choose date'));
    await _tap(tester, find.text('OK'));
    await _tap(tester, find.text('SEND MATCH INVITATION'));
    expect(find.text('These teams already have an open invitation for that time.'), findsOneWidget);
  });
}
