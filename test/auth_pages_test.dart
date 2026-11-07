import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:website/api/api_client.dart';
import 'package:website/api/session.dart';
import 'package:website/main.dart';
import 'package:website/pages/signup/signup_form_data.dart';

http.Response _json(int status, Object body) =>
    http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json'});

http.Response _error(int status, String code, [String message = 'msg']) =>
    _json(status, {'error': {'code': code, 'message': message}});

const _coachUser = {'id': 5, 'role': 'coach', 'firstName': 'Thabo', 'lastName': 'Dlamini'};

class _Fake {
  _Fake(this.respond);

  final http.Response Function(http.Request request) respond;
  final requests = <http.Request>[];

  http.Request last(String path) => requests.lastWhere((r) => r.url.path == path);
  Map<String, dynamic> body(String path) => jsonDecode(last(path).body) as Map<String, dynamic>;
}

Future<_Fake> _pumpApp(WidgetTester tester, http.Response Function(http.Request) respond) async {
  tester.view.physicalSize = const Size(1280, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final fake = _Fake(respond);
  final api = ApiClient(
    baseUrl: 'http://api.test',
    httpClient: MockClient((request) async {
      fake.requests.add(request);
      return fake.respond(request);
    }),
  );
  await tester.pumpWidget(TobunApp(session: Session(api)));
  await tester.pumpAndSettle();
  return fake;
}

Future<void> _pick(WidgetTester tester, String hint, String option) async {
  await tester.tap(find.text(hint));
  await tester.pumpAndSettle();
  await tester.tap(find.text(option).last);
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, String label) async {
  final finder = find.text(label);
  await tester.ensureVisible(finder.first);
  await tester.tap(finder.first);
  await tester.pumpAndSettle();
}

// 'Verify' is also a label in the stepper, so aim at the button.
Future<void> _tapVerify(WidgetTester tester) async {
  final button = find.widgetWithText(ElevatedButton, 'Verify');
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

Future<void> _openLogin(WidgetTester tester) async {
  await tester.tap(find.text('LOGIN'));
  await tester.pumpAndSettle();
}

Future<void> _logIn(WidgetTester tester, String email, String password) async {
  await tester.enterText(find.widgetWithText(TextFormField, 'e.g. coach@northviewhigh.co.za'), email);
  await tester.enterText(find.byType(TextFormField).at(1), password);
  await _tap(tester, 'Sign In');
}

Future<void> _openSignup(WidgetTester tester) async {
  await _openLogin(tester);
  await _tap(tester, 'Register and Sign up');
}

Future<void> _fillPersonal(WidgetTester tester, {bool coach = false}) async {
  await tester.enterText(find.widgetWithText(TextFormField, 'e.g. John'), 'Thabo');
  await tester.enterText(find.widgetWithText(TextFormField, 'e.g. Doe'), 'Dlamini');
  await _pick(tester, 'Day', '3');
  await _pick(tester, 'Month', 'March');
  await _pick(tester, 'Year', '${DateTime.now().year - 20}');
  if (coach) await _tap(tester, 'Coach');
  await _tap(tester, 'Next Step');
}

Future<void> _fillAccount(WidgetTester tester) async {
  final fields = find.byType(TextFormField);
  await tester.enterText(fields.at(0), 'thabo@greenwood.com');
  await tester.enterText(fields.at(1), 'Passw0rdOK');
  await tester.enterText(fields.at(2), 'Passw0rdOK');
  await _tap(tester, 'Create account');
}

void main() {
  group('sign-up payloads', () {
    SignupFormData filled() => SignupFormData()
      ..firstName.text = ' Ada '
      ..lastName.text = 'Obi'
      ..birthDay = 4
      ..birthMonth = 3
      ..birthYear = 2009
      ..gender = Gender.female
      ..school.text = 'Example School'
      ..email.text = ' ada@example.com '
      ..password.text = 'Passw0rdOK';

    test('date of birth is YYYY-MM-DD, and null until complete', () {
      final data = filled();
      expect(data.dateOfBirth, '2009-03-04');
      data.birthDay = null;
      expect(data.dateOfBirth, isNull);
    });

    test('a learner without a sport sends sport: null', () {
      final p = (filled()..grade = 10..className.text = '10A').learnerPayload();
      expect(p['role'], 'learner');
      expect(p['firstName'], 'Ada');
      expect(p['gender'], 'female');
      expect(p['email'], 'ada@example.com');
      expect(p['school'], {'name': 'Example School', 'grade': 10, 'className': '10A'});
      expect(p['sport'], isNull);
      expect(p.containsKey('username'), isFalse);
    });

    test('a learner with a sport sends the team name only when given', () {
      final withTeam = (filled()..sport.text = 'Football'..teamName.text = 'Falcons').learnerPayload();
      expect(withTeam['sport'], {'name': 'Football', 'teamName': 'Falcons'});
      final noTeam = (filled()..sport.text = 'Football').learnerPayload();
      expect(noTeam['sport'], {'name': 'Football'});
    });

    test('a coach sends the coded values and nested team', () {
      final p = (filled()
            ..accountType = AccountType.coach
            ..coachingRole = 'head_coach'
            ..experience = '5_10_years'
            ..teamName.text = 'Basketball Boys'
            ..teamLevel = '1st_team'
            ..sport.text = 'Basketball')
          .coachPayload();
      expect(p['school'], 'Example School');
      expect(p['coachingRole'], 'head_coach');
      expect(p['experience'], '5_10_years');
      expect(p['team'], {'name': 'Basketball Boys', 'level': '1st_team', 'sport': 'Basketball'});
      expect(p.containsKey('role'), isFalse);
    });
  });

  group('login', () {
    testWidgets('signs in, goes home, and the header shows the name with a log out button', (tester) async {
      final fake = await _pumpApp(tester, (r) {
        if (r.url.path == '/api/auth/login') {
          return _json(200, {'user': _coachUser, 'accessToken': 'A', 'refreshToken': 'R'});
        }
        return _json(200, {});
      });
      await _openLogin(tester);
      await _logIn(tester, ' thabo@greenwood.com ', 'Passw0rdOK');

      expect(fake.body('/api/auth/login'), {'email': 'thabo@greenwood.com', 'password': 'Passw0rdOK'});
      expect(find.text('Welcome Back'), findsNothing);
      expect(find.text('Thabo Dlamini'), findsOneWidget);
      expect(find.text('LOG OUT'), findsOneWidget);
      expect(find.text('LOGIN'), findsNothing);

      await _tap(tester, 'LOG OUT');
      expect(find.text('LOGIN'), findsOneWidget);
      expect(find.text('Thabo Dlamini'), findsNothing);
    });

    testWidgets('a wrong password shows a message and stays on the page', (tester) async {
      await _pumpApp(tester, (r) => _error(401, 'INVALID_CREDENTIALS'));
      await _openLogin(tester);
      await _logIn(tester, 'a@b.com', 'wrong');
      expect(find.text('Wrong email or password.'), findsOneWidget);
      expect(find.text('Welcome Back'), findsOneWidget);
    });

    testWidgets('an empty form makes no request', (tester) async {
      final fake = await _pumpApp(tester, (r) => _json(200, {}));
      await _openLogin(tester);
      await _tap(tester, 'Sign In');
      expect(find.text('Required'), findsWidgets);
      expect(fake.requests, isEmpty);
    });

    testWidgets('an unreachable server says so', (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final api = ApiClient(
        baseUrl: 'http://api.test',
        httpClient: MockClient((r) async => throw http.ClientException('down')),
      );
      await tester.pumpWidget(TobunApp(session: Session(api)));
      await tester.pumpAndSettle();
      await _openLogin(tester);
      await _logIn(tester, 'a@b.com', 'x');
      expect(find.textContaining('Could not reach Sportstures'), findsOneWidget);
    });

    testWidgets('an unverified account can go and enter its code', (tester) async {
      final fake = await _pumpApp(tester, (r) {
        if (r.url.path == '/api/auth/login') return _error(403, 'EMAIL_NOT_VERIFIED');
        if (r.url.path == '/api/auth/verify-otp') return _json(200, {'message': 'Account verified. You can now log in.'});
        return _json(200, {});
      });
      await _openLogin(tester);
      await _logIn(tester, 'lena@school.com', 'Passw0rdOK');
      expect(find.text('Please verify your email before logging in.'), findsOneWidget);

      await _tap(tester, 'Enter your verification code');
      expect(find.text('Verify your email'), findsOneWidget);
      expect(find.textContaining('lena@school.com'), findsWidgets);
      expect(find.text('Resend code'), findsOneWidget, reason: 'no code was just sent, so resend works at once');

      await tester.enterText(find.byType(TextField), '123456');
      await _tapVerify(tester);
      expect(fake.body('/api/auth/verify-otp'), {'email': 'lena@school.com', 'code': '123456'});
      expect(find.text("You're all set"), findsOneWidget);
      expect(find.text('Log in'), findsOneWidget, reason: 'learners are not signed in by verifying');
    });
  });

  group('sign-up', () {
    testWidgets('a learner signs up, verifies, and is then asked to log in', (tester) async {
      final fake = await _pumpApp(tester, (r) {
        if (r.url.path == '/api/auth/register') return _json(201, {'userId': 1});
        if (r.url.path == '/api/auth/verify-otp') return _json(200, {'message': 'Account verified. You can now log in.'});
        return _json(200, {});
      });
      await _openSignup(tester);
      expect(find.text('Username'), findsNothing);
      expect(find.text('School Code (provided by your coach)'), findsNothing);
      expect(find.text('Register as a school'), findsNothing);

      await _fillPersonal(tester);
      expect(find.text('School details'), findsOneWidget);
      await tester.enterText(find.widgetWithText(TextFormField, 'e.g. Greenwood High'), 'Greenwood High');
      await _pick(tester, 'Select grade', 'Grade 2');
      await tester.enterText(find.widgetWithText(TextFormField, 'e.g. 10A'), '2B');
      await _tap(tester, 'Next Step');
      await _fillAccount(tester);

      final body = fake.body('/api/auth/register');
      expect(body['role'], 'learner');
      expect(body['school'], {'name': 'Greenwood High', 'grade': 2, 'className': '2B'});
      expect(body['sport'], isNull);
      expect(body['email'], 'thabo@greenwood.com');
      expect(body['dateOfBirth'], '${DateTime.now().year - 20}-03-03');

      expect(find.text('Verify your email'), findsOneWidget);
      expect(find.textContaining('Resend code in'), findsOneWidget, reason: 'a code was just sent');

      await tester.enterText(find.byType(TextField), '12');
      await _tapVerify(tester);
      expect(find.text('Enter the 6-digit code from your email'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '654321');
      await _tapVerify(tester);
      expect(find.text("You're all set"), findsOneWidget);
      await _tap(tester, 'Log in');
      expect(find.text('Welcome Back'), findsOneWidget);
    });

    testWidgets('a coach signs up, verifies and is signed in', (tester) async {
      final fake = await _pumpApp(tester, (r) {
        if (r.url.path == '/api/auth/register/coach') return _json(201, {'userId': 5, 'status': 'pending_verification'});
        if (r.url.path == '/api/auth/verify-otp') {
          return _json(200, {'user': _coachUser, 'accessToken': 'A', 'refreshToken': 'R'});
        }
        return _json(200, {});
      });
      await _openSignup(tester);
      await _fillPersonal(tester, coach: true);

      expect(find.text('Your role'), findsOneWidget);
      await tester.enterText(find.widgetWithText(TextFormField, 'e.g. Greenwood High'), 'Greenwood High');
      await _pick(tester, 'Select your coaching role', 'Head coach');
      await _pick(tester, 'Select your experience', '1 to 3 years');
      await tester.enterText(find.widgetWithText(TextFormField, 'e.g. Basketball Boys'), 'Basketball Boys');
      await _pick(tester, 'Select level', 'Under 13');
      await tester.enterText(find.widgetWithText(TextFormField, 'e.g. Basketball'), 'Basketball');
      await _tap(tester, 'Next Step');
      await _fillAccount(tester);

      expect(fake.body('/api/auth/register/coach'), {
        'firstName': 'Thabo',
        'lastName': 'Dlamini',
        'dateOfBirth': '${DateTime.now().year - 20}-03-03',
        'gender': 'male',
        'school': 'Greenwood High',
        'coachingRole': 'head_coach',
        'experience': '1_3_years',
        'team': {'name': 'Basketball Boys', 'level': 'u13', 'sport': 'Basketball'},
        'email': 'thabo@greenwood.com',
        'password': 'Passw0rdOK',
      });

      await tester.enterText(find.byType(TextField), '123456');
      await _tapVerify(tester);
      expect(find.text('Your email is verified and you are signed in.'), findsOneWidget);
      await _tap(tester, 'Go to the site');
      expect(find.text('Thabo Dlamini'), findsOneWidget, reason: 'the header shows who is signed in');
    });

    testWidgets('an email that is already registered is explained, and the form is kept', (tester) async {
      await _pumpApp(tester, (r) => _error(409, 'EMAIL_TAKEN'));
      await _openSignup(tester);
      await _fillPersonal(tester);
      await tester.enterText(find.widgetWithText(TextFormField, 'e.g. Greenwood High'), 'Greenwood High');
      await _pick(tester, 'Select grade', 'Grade 2');
      await tester.enterText(find.widgetWithText(TextFormField, 'e.g. 10A'), '2B');
      await _tap(tester, 'Next Step');
      await _fillAccount(tester);

      expect(find.textContaining('already exists'), findsOneWidget);
      expect(find.text('Account setup'), findsOneWidget);
    });

    testWidgets('server field errors name the field, even from an earlier step', (tester) async {
      await _pumpApp(tester, (r) => _json(422, {'errors': {'team.sport': 'Required', 'coachingRole': 'Pick one'}}));
      await _openSignup(tester);
      await _fillPersonal(tester, coach: true);
      await tester.enterText(find.widgetWithText(TextFormField, 'e.g. Greenwood High'), 'Greenwood High');
      await _pick(tester, 'Select your coaching role', 'Head coach');
      await _pick(tester, 'Select your experience', '1 to 3 years');
      await tester.enterText(find.widgetWithText(TextFormField, 'e.g. Basketball Boys'), 'Basketball Boys');
      await _pick(tester, 'Select level', 'Under 13');
      await tester.enterText(find.widgetWithText(TextFormField, 'e.g. Basketball'), 'Basketball');
      await _tap(tester, 'Next Step');
      await _fillAccount(tester);

      expect(find.textContaining('Sport: Required'), findsOneWidget);
      expect(find.textContaining('Coaching role: Pick one'), findsOneWidget);
    });

    testWidgets('a weak password is caught before anything is sent', (tester) async {
      final fake = await _pumpApp(tester, (r) => _json(200, {}));
      await _openSignup(tester);
      await _fillPersonal(tester);
      await tester.enterText(find.widgetWithText(TextFormField, 'e.g. Greenwood High'), 'Greenwood High');
      await _pick(tester, 'Select grade', 'Grade 2');
      await tester.enterText(find.widgetWithText(TextFormField, 'e.g. 10A'), '2B');
      await _tap(tester, 'Next Step');

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'thabo@greenwood.com');
      await tester.enterText(fields.at(1), 'onlyletters');
      await tester.enterText(fields.at(2), 'onlyletters');
      await _tap(tester, 'Create account');
      expect(find.text('Use at least one letter and one number'), findsOneWidget);
      expect(fake.requests, isEmpty);
    });

    testWidgets('the school link goes to the For Schools page, not the personal sign-up', (tester) async {
      await _pumpApp(tester, (r) => _json(200, {}));
      await _openSignup(tester);
      await _tap(tester, 'See how it works');
      expect(find.text('Create an account'), findsNothing);
    });
  });
}
