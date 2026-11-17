import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:website/api/api_client.dart';
import 'package:website/api/invitations_api.dart';
import 'package:website/api/session.dart';
import 'package:website/data/match_store.dart';
import 'package:website/main.dart';
import 'package:website/pages/coach/coach_invite_page.dart';
import 'package:website/pages/signup/signup_form_data.dart';

http.Response _json(int status, Object? body) =>
    http.Response(body == null ? '' : jsonEncode(body), status, headers: {'content-type': 'application/json'});

http.Response _error(int status, String code, [String message = 'msg']) =>
    _json(status, {'error': {'code': code, 'message': message}});

Map<String, dynamic> _invitation(int id, {String kind = 'email', String? email, String status = 'pending', int joined = 0, String code = 'CODE'}) => {
      'id': id,
      'kind': kind,
      'email': email,
      'status': status,
      'link': 'https://sportstures.test/signup?invite=$code$id',
      'code': '$code$id',
      'joined': joined,
      'emailSent': kind == 'email',
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'expiresAt': DateTime.now().add(const Duration(days: 14)).toUtc().toIso8601String(),
    };

class _Backend {
  _Backend() {
    invitations = [_invitation(1, email: 'old@school.co.za', status: 'accepted', joined: 1)];
  }

  late List<Map<String, dynamic>> invitations;
  http.Response? inviteError;
  final seen = <http.Request>[];

  http.Response handle(http.Request r) {
    seen.add(r);
    final path = r.url.path;
    if (path == '/api/auth/login') {
      return _json(200, {
        'accessToken': 'A',
        'refreshToken': 'R',
        'user': {'id': 7, 'role': r.body.contains('learner') ? 'learner' : 'coach', 'firstName': 'Thabo', 'lastName': 'Dlamini'},
      });
    }
    if (path == '/api/invitations' && r.method == 'GET') {
      return _json(200, {'invitations': invitations, 'joined': invitations.fold<int>(0, (n, i) => n + (i['joined'] as int))});
    }
    if (path == '/api/invitations' && r.method == 'POST') {
      if (inviteError != null) return inviteError!;
      final body = jsonDecode(r.body) as Map<String, dynamic>;
      final made = body['email'] == null
          ? _invitation(5, kind: 'link', code: 'LINK')
          : _invitation(invitations.length + 10, email: body['email'] as String);
      invitations = [made, ...invitations];
      return _json(201, {'invitation': made});
    }
    final one = RegExp(r'^/api/invitations/(\d+)$').firstMatch(path);
    if (one != null && r.method == 'DELETE') {
      invitations.removeWhere((i) => i['id'] == int.parse(one.group(1)!));
      return http.Response('', 204);
    }
    return _error(404, 'NOT_FOUND');
  }

  Iterable<http.Request> posts() => seen.where((r) => r.method == 'POST' && r.url.path == '/api/invitations');
}

Future<_Backend> _pumpInvite(WidgetTester tester, {_Backend? backend}) async {
  tester.view.physicalSize = const Size(1400, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final b = backend ?? _Backend();
  final session = Session(ApiClient(baseUrl: 'http://api.test', httpClient: MockClient((r) async => b.handle(r))));
  await session.login('coach@x.com', 'Passw0rdOK');
  await tester.pumpWidget(SessionScope(session: session, child: const MaterialApp(home: CoachInvitePage())));
  await tester.pumpAndSettle();
  return b;
}

void main() {
  group('invite page', () {
    testWidgets('shows what was sent and who joined', (tester) async {
      await _pumpInvite(tester);
      expect(find.text('INVITATIONS SENT'), findsOneWidget);
      expect(find.text('old@school.co.za'), findsOneWidget);
      expect(find.text('JOINED'), findsOneWidget);
      expect(find.text('1 joined'), findsOneWidget);
    });

    testWidgets('emailing an invitation sends the address and says it went', (tester) async {
      final b = await _pumpInvite(tester);
      await tester.enterText(find.widgetWithText(TextFormField, 'School email address'), '  head@newschool.co.za ');
      await tester.tap(find.text('SEND INVITATION'));
      await tester.pumpAndSettle();

      expect(jsonDecode(b.posts().single.body), {'email': 'head@newschool.co.za'});
      expect(find.textContaining('Invitation sent to head@newschool.co.za'), findsOneWidget);
      expect(find.text('head@newschool.co.za'), findsOneWidget, reason: 'it appears in the list');
      expect(tester.widget<TextFormField>(find.byType(TextFormField)).controller!.text, isEmpty);
    });

    testWidgets('a bad address is caught before anything is sent', (tester) async {
      final b = await _pumpInvite(tester);
      await tester.tap(find.text('SEND INVITATION'));
      await tester.pumpAndSettle();
      expect(find.text('Enter an email address'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField), 'not-an-email');
      await tester.tap(find.text('SEND INVITATION'));
      await tester.pumpAndSettle();
      expect(find.text('Enter a valid email address'), findsOneWidget);
      expect(b.posts(), isEmpty);
    });

    testWidgets('explains an address that already has an account, and one the mail server rejected', (tester) async {
      final b = _Backend()..inviteError = _error(409, 'ALREADY_REGISTERED');
      await _pumpInvite(tester, backend: b);
      await tester.enterText(find.byType(TextFormField), 'taken@school.co.za');
      await tester.tap(find.text('SEND INVITATION'));
      await tester.pumpAndSettle();
      expect(find.text('That address already has a Sportstures account.'), findsOneWidget);

      b.inviteError = _error(502, 'EMAIL_FAILED', 'We could not send the email.');
      await tester.tap(find.text('SEND INVITATION'));
      await tester.pumpAndSettle();
      expect(find.text('We could not send the email.'), findsOneWidget);
    });

    testWidgets('the share link is shown and copied', (tester) async {
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') copied = (call.arguments as Map)['text'] as String;
        return null;
      });
      addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));

      await _pumpInvite(tester);
      expect(find.text('COPY LINK'), findsNothing);
      await tester.tap(find.text('GET MY INVITE LINK'));
      await tester.pumpAndSettle();
      expect(find.text('https://sportstures.test/signup?invite=LINK5'), findsWidgets);

      await tester.tap(find.text('COPY LINK'));
      await tester.pumpAndSettle(const Duration(seconds: 4));
      expect(copied, 'https://sportstures.test/signup?invite=LINK5');
    });

    testWidgets('a pending invitation can be cancelled; a joined one cannot', (tester) async {
      final b = _Backend()..invitations = [_invitation(2, email: 'wait@school.co.za'), _invitation(1, email: 'old@school.co.za', status: 'accepted', joined: 1)];
      await _pumpInvite(tester, backend: b);
      expect(find.byIcon(Icons.close), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(b.seen.any((r) => r.method == 'DELETE' && r.url.path == '/api/invitations/2'), isTrue);
      expect(find.text('wait@school.co.za'), findsNothing);
    });

    testWidgets('visitors and learners do not see it', (tester) async {
      tester.view.physicalSize = const Size(1400, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final session = Session(ApiClient(baseUrl: 'http://api.test', httpClient: MockClient((r) async => _Backend().handle(r))));
      await tester.pumpWidget(SessionScope(session: session, child: const MaterialApp(home: CoachInvitePage())));
      await tester.pumpAndSettle();
      expect(find.text('LOG IN'), findsOneWidget);
      expect(find.text('SEND INVITATION'), findsNothing);
    });
  });

  group('opening an invitation link', () {
    const info = {'valid': true, 'inviterName': 'Sipho Williams', 'schoolName': 'Jeppe High', 'email': 'head@newschool.co.za'};

    Future<List<http.Request>> pumpLink(WidgetTester tester, http.Response Function(http.Request) respond) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final seen = <http.Request>[];
      final api = ApiClient(baseUrl: 'http://api.test', httpClient: MockClient((r) async {
        seen.add(r);
        return respond(r);
      }));
      await tester.pumpWidget(TobunApp(session: Session(api), matches: MatchStore.sample()));
      await tester.pumpAndSettle();
      // What the browser does for https://site/signup?invite=abc123
      tester.state<NavigatorState>(find.byType(Navigator)).pushNamed('/signup?invite=abc123');
      await tester.pumpAndSettle();
      return seen;
    }

    testWidgets('a good link names the inviter, fills in the email and registers them as a coach with the code', (tester) async {
      final seen = await pumpLink(tester, (r) {
        if (r.url.path == '/api/invitations/abc123') return _json(200, info);
        if (r.url.path == '/api/auth/register/coach') return _json(201, {'userId': 9, 'status': 'pending_verification'});
        return _json(200, {});
      });
      expect(find.textContaining('Sipho Williams from Jeppe High invited you'), findsOneWidget);
      expect(seen.first.headers.containsKey('Authorization'), isFalse, reason: 'the lookup is public');

      await tester.enterText(find.widgetWithText(TextFormField, 'e.g. John'), 'Hlengiwe');
      await tester.enterText(find.widgetWithText(TextFormField, 'e.g. Doe'), 'Mokoena');
      for (final (hint, option) in [('Day', '3'), ('Month', 'March'), ('Year', '${DateTime.now().year - 20}')]) {
        await tester.tap(find.text(hint));
        await tester.pumpAndSettle();
        await tester.tap(find.text(option).last);
        await tester.pumpAndSettle();
      }
      Future<void> next(String label) async {
        final f = find.text(label).first;
        await tester.ensureVisible(f);
        await tester.tap(f);
        await tester.pumpAndSettle();
      }

      await next('Next Step');
      expect(find.text('Your role'), findsOneWidget, reason: 'they were put on the coach sign-up');
      await tester.enterText(find.widgetWithText(TextFormField, 'e.g. Greenwood High'), 'New School');
      for (final (hint, option) in [('Select your coaching role', 'Head coach'), ('Select your experience', '1 to 3 years'), ('Select level', 'Under 13')]) {
        await tester.tap(find.text(hint));
        await tester.pumpAndSettle();
        await tester.tap(find.text(option).last);
        await tester.pumpAndSettle();
      }
      await tester.enterText(find.widgetWithText(TextFormField, 'e.g. Basketball Boys'), 'New School Netball');
      await tester.enterText(find.widgetWithText(TextFormField, 'e.g. Basketball'), 'Netball');
      await next('Next Step');

      final fields = find.byType(TextFormField);
      expect(tester.widget<TextFormField>(fields.at(0)).controller!.text, 'head@newschool.co.za');
      await tester.enterText(fields.at(1), 'Passw0rdOK');
      await tester.enterText(fields.at(2), 'Passw0rdOK');
      await next('Create account');

      final sent = jsonDecode(seen.lastWhere((r) => r.url.path == '/api/auth/register/coach').body) as Map<String, dynamic>;
      expect(sent['inviteCode'], 'abc123');
      expect(sent['email'], 'head@newschool.co.za');
    });

    testWidgets('a dead link says so but still lets them register', (tester) async {
      await pumpLink(tester, (r) => _error(404, 'INVITATION_INVALID'));
      expect(find.textContaining('not valid any more'), findsOneWidget);
      expect(find.text('Next Step'), findsOneWidget);
    });
  });

  group('API client', () {
    test('invitation text reads naturally', () {
      expect(const InvitationInfo(inviterName: 'Sipho', schoolName: 'Jeppe High', email: null).from, 'Sipho from Jeppe High');
      expect(const InvitationInfo(inviterName: 'Sipho', schoolName: null, email: null).from, 'Sipho');
      expect(const InvitationInfo(inviterName: '', schoolName: null, email: null).from, 'A coach');
    });

    test('the code is sent only for invited sign-ups', () {
      final plain = SignupFormData()..accountType = AccountType.coach;
      expect(plain.coachPayload().containsKey('inviteCode'), isFalse);
      expect((SignupFormData()..inviteCode = 'abc').coachPayload()['inviteCode'], 'abc');
    });
  });
}
