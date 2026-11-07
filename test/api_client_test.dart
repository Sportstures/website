import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:website/api/api_client.dart';
import 'package:website/api/api_exception.dart';
import 'package:website/api/session.dart';
import 'package:website/api/token_store.dart';

http.Response json(int status, Object? body) =>
    http.Response(body == null ? '' : jsonEncode(body), status, headers: {'content-type': 'application/json'});

Map<String, Object?> errorBody(String code, [String message = 'msg']) => {
      'error': {'code': code, 'message': message},
    };

const _user = {'id': 7, 'role': 'coach', 'firstName': 'Thabo', 'lastName': 'Dlamini', 'email': 't@x.com'};

/// A client whose server is [handler], with tokens already saved.
({ApiClient api, MemoryTokenStore store, List<http.Request> seen}) setup(
  http.Response Function(http.Request) handler, {
  bool signedIn = true,
}) {
  final store = MemoryTokenStore();
  final seen = <http.Request>[];
  if (signedIn) store.write(const Tokens(accessToken: 'A1', refreshToken: 'R1'));
  final api = ApiClient(
    baseUrl: 'http://api.test',
    tokenStore: store,
    httpClient: MockClient((request) async {
      seen.add(request);
      return handler(request);
    }),
  );
  return (api: api, store: store, seen: seen);
}

void main() {
  group('ApiClient', () {
    test('sends the Bearer token and a JSON body, and decodes the answer', () async {
      final s = setup((r) => json(200, {'ok': true}));
      final res = await s.api.post('/api/things', body: {'a': 1});
      expect(res, {'ok': true});
      expect(s.seen.single.headers['Authorization'], 'Bearer A1');
      expect(s.seen.single.headers['Content-Type'], contains('application/json'));
      expect(jsonDecode(s.seen.single.body), {'a': 1});
      expect(s.seen.single.url.toString(), 'http://api.test/api/things');
    });

    test('auth: false sends no token; empty query values are dropped', () async {
      final s = setup((r) => json(200, {}));
      await s.api.get('/api/teams', query: {'q': 'lions', 'sportId': 2, 'mine': null, 'x': ''}, auth: false);
      expect(s.seen.single.headers.containsKey('Authorization'), isFalse);
      expect(s.seen.single.url.queryParameters, {'q': 'lions', 'sportId': '2'});
    });

    test('a 204 answer returns null', () async {
      final s = setup((r) => http.Response('', 204));
      expect(await s.api.delete('/api/teams/1/membership'), isNull);
    });

    test('an error envelope becomes an ApiException with code and message', () async {
      final s = setup((r) => json(409, errorBody('JERSEY_TAKEN', 'Number taken')));
      await expectLater(
        s.api.post('/api/teams/1/roster', body: {}),
        throwsA(isA<ApiException>()
            .having((e) => e.status, 'status', 409)
            .having((e) => e.code, 'code', 'JERSEY_TAKEN')
            .having((e) => e.message, 'message', 'Number taken')),
      );
    });

    test('validation details become field errors (first message per field wins)', () async {
      final s = setup((r) => json(400, {
            'error': {
              'code': 'VALIDATION_ERROR',
              'message': 'Invalid input',
              'details': [
                {'field': 'email', 'message': 'A valid email is required'},
                {'field': 'email', 'message': 'second'},
                {'field': 'password', 'message': 'Too short'},
              ],
            },
          }));
      try {
        await s.api.post('/api/auth/register', body: {}, auth: false);
        fail('should throw');
      } on ApiException catch (e) {
        expect(e.fieldErrors, {'email': 'A valid email is required', 'password': 'Too short'});
      }
    });

    test('the coach signup 422 shape ({errors: {...}}) becomes field errors', () async {
      final s = setup((r) => json(422, {'errors': {'coachRole': 'Pick a role'}}));
      try {
        await s.api.post('/api/auth/register/coach', body: {}, auth: false);
        fail('should throw');
      } on ApiException catch (e) {
        expect(e.status, 422);
        expect(e.fieldErrors, {'coachRole': 'Pick a role'});
        expect(e.message, 'Pick a role');
      }
    });

    test('an unreadable server error still gives a usable message', () async {
      final s = setup((r) => http.Response('<html>oops</html>', 502));
      await expectLater(
        s.api.get('/api/teams'),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', contains('try again'))),
      );
    });

    test('an unreachable server is a NETWORK error', () async {
      final api = ApiClient(
        baseUrl: 'http://api.test',
        httpClient: MockClient((r) async => throw http.ClientException('down')),
      );
      await expectLater(api.get('/api/teams'), throwsA(isA<ApiException>().having((e) => e.isNetwork, 'isNetwork', isTrue)));
    });

    test('an expired access token is refreshed and the request retried once', () async {
      var round = 0;
      final s = setup((r) {
        if (r.url.path == '/api/auth/refresh') {
          expect(jsonDecode(r.body), {'refreshToken': 'R1'});
          return json(200, {'user': _user, 'accessToken': 'A2', 'refreshToken': 'R2'});
        }
        round++;
        return r.headers['Authorization'] == 'Bearer A1'
            ? json(401, errorBody('TOKEN_EXPIRED'))
            : json(200, {'round': round});
      });
      final res = await s.api.get('/api/me/teams');
      expect(res, {'round': 2});
      final saved = await s.store.read();
      expect(saved!.accessToken, 'A2');
      expect(saved.refreshToken, 'R2', reason: 'the newest pair must be saved');
    });

    test('requests made together share one refresh (refresh tokens are single use)', () async {
      var refreshes = 0;
      final s = setup((r) {
        if (r.url.path == '/api/auth/refresh') {
          refreshes++;
          return json(200, {'user': _user, 'accessToken': 'A2', 'refreshToken': 'R2'});
        }
        return r.headers['Authorization'] == 'Bearer A1' ? json(401, errorBody('TOKEN_EXPIRED')) : json(200, {'ok': 1});
      });
      final results = await Future.wait([s.api.get('/a'), s.api.get('/b'), s.api.get('/c')]);
      expect(results, everyElement({'ok': 1}));
      expect(refreshes, 1);
    });

    test('when the refresh fails the tokens are cleared and the app is told', () async {
      var told = 0;
      final s = setup((r) {
        if (r.url.path == '/api/auth/refresh') return json(401, errorBody('INVALID_REFRESH_TOKEN'));
        return json(401, errorBody('TOKEN_EXPIRED'));
      });
      s.api.onSessionExpired = () => told++;
      await expectLater(s.api.get('/api/me/teams'), throwsA(isA<ApiException>().having((e) => e.code, 'code', 'TOKEN_EXPIRED')));
      expect(await s.store.read(), isNull);
      expect(told, 1);
    });

    test('an offline refresh keeps the tokens', () async {
      final store = MemoryTokenStore();
      await store.write(const Tokens(accessToken: 'A1', refreshToken: 'R1'));
      final api = ApiClient(
        baseUrl: 'http://api.test',
        tokenStore: store,
        httpClient: MockClient((r) async {
          if (r.url.path == '/api/auth/refresh') throw http.ClientException('offline');
          return json(401, errorBody('TOKEN_EXPIRED'));
        }),
      );
      await expectLater(api.get('/x'), throwsA(isA<ApiException>()));
      expect(await store.read(), isNotNull);
    });

    test('other 401s are not retried', () async {
      final s = setup((r) => json(401, errorBody('INVALID_TOKEN')));
      await expectLater(s.api.get('/x'), throwsA(isA<ApiException>().having((e) => e.code, 'code', 'INVALID_TOKEN')));
      expect(s.seen.length, 1);
    });
  });

  group('Session', () {
    test('login saves both tokens and the user', () async {
      final s = setup((r) => json(200, {'user': _user, 'accessToken': 'A9', 'refreshToken': 'R9'}), signedIn: false);
      final session = Session(s.api);
      final user = await session.login('  t@x.com ', 'secret');
      expect(user.isCoach, isTrue);
      expect(user.displayName, 'Thabo Dlamini');
      expect(session.isSignedIn, isTrue);
      expect((await s.store.read())!.refreshToken, 'R9');
      expect(jsonDecode(s.seen.single.body), {'email': 't@x.com', 'password': 'secret'});
      expect(s.seen.single.headers.containsKey('Authorization'), isFalse);
    });

    test('a wrong password throws and leaves the session signed out', () async {
      final s = setup((r) => json(401, errorBody('INVALID_CREDENTIALS')), signedIn: false);
      final session = Session(s.api);
      await expectLater(session.login('a@b.com', 'x'), throwsA(isA<ApiException>().having((e) => e.code, 'code', 'INVALID_CREDENTIALS')));
      expect(session.isSignedIn, isFalse);
      expect(await s.store.read(), isNull);
    });

    test('an unverified learner gets EMAIL_NOT_VERIFIED', () async {
      final s = setup((r) => json(403, errorBody('EMAIL_NOT_VERIFIED')), signedIn: false);
      await expectLater(Session(s.api).login('a@b.com', 'x'), throwsA(isA<ApiException>().having((e) => e.code, 'code', 'EMAIL_NOT_VERIFIED')));
    });

    test('verifying a coach signs them in; verifying a learner does not', () async {
      final coach = setup((r) => json(200, {'user': _user, 'accessToken': 'A', 'refreshToken': 'R'}), signedIn: false);
      final coachSession = Session(coach.api);
      expect((await coachSession.verifyOtp('t@x.com', '123456'))!.isCoach, isTrue);
      expect(coachSession.isSignedIn, isTrue);

      final learner = setup((r) => json(200, {'message': 'Account verified. You can now log in.'}), signedIn: false);
      final learnerSession = Session(learner.api);
      expect(await learnerSession.verifyOtp('l@x.com', '123456'), isNull);
      expect(learnerSession.isSignedIn, isFalse);
    });

    test('resendOtp returns the wait in seconds', () async {
      final s = setup((r) => json(200, {'retryAfterSeconds': 60}), signedIn: false);
      expect(await Session(s.api).resendOtp('a@b.com'), 60);
    });

    test('restore signs back in from saved tokens, and the coach team is read from the profile', () async {
      final s = setup((r) => json(200, {
            'user': {
              ..._user,
              'profile': {'team': {'id': 10, 'name': 'Basketball Boys'}},
            },
          }));
      final session = Session(s.api);
      await session.restore();
      expect(session.user!.id, 7);
      expect(session.user!.team!['name'], 'Basketball Boys');
      expect(session.isRestoring, isFalse);
    });

    test('restore with no saved tokens makes no request', () async {
      final s = setup((r) => json(200, {}), signedIn: false);
      await Session(s.api).restore();
      expect(s.seen, isEmpty);
    });

    test('restore with bad tokens clears them; offline keeps them', () async {
      final bad = setup((r) => json(401, errorBody('INVALID_TOKEN')));
      final badSession = Session(bad.api);
      await badSession.restore();
      expect(badSession.isSignedIn, isFalse);
      expect(await bad.store.read(), isNull);

      final store = MemoryTokenStore();
      await store.write(const Tokens(accessToken: 'A', refreshToken: 'R'));
      final offline = Session(ApiClient(
        baseUrl: 'http://api.test',
        tokenStore: store,
        httpClient: MockClient((r) async => throw http.ClientException('offline')),
      ));
      await offline.restore();
      expect(offline.isSignedIn, isFalse);
      expect(await store.read(), isNotNull, reason: 'offline must not sign the user out for good');
    });

    test('logout signs out locally even if the server is unreachable', () async {
      final store = MemoryTokenStore();
      await store.write(const Tokens(accessToken: 'A', refreshToken: 'R'));
      final session = Session(ApiClient(
        baseUrl: 'http://api.test',
        tokenStore: store,
        httpClient: MockClient((r) async {
          if (r.url.path == '/api/auth/login') return json(200, {'user': _user, 'accessToken': 'A', 'refreshToken': 'R'});
          throw http.ClientException('offline');
        }),
      ));
      await session.login('t@x.com', 'x');
      await session.logout();
      expect(session.isSignedIn, isFalse);
      expect(await store.read(), isNull);
    });

    test('when the session expires mid-use, the user is signed out and listeners are told', () async {
      final s = setup((r) {
        if (r.url.path == '/api/auth/login') return json(200, {'user': _user, 'accessToken': 'A1', 'refreshToken': 'R1'});
        if (r.url.path == '/api/auth/refresh') return json(401, errorBody('REFRESH_TOKEN_EXPIRED'));
        return json(401, errorBody('TOKEN_EXPIRED'));
      }, signedIn: false);
      final session = Session(s.api);
      await session.login('t@x.com', 'x');
      var notified = 0;
      session.addListener(() => notified++);
      await expectLater(s.api.get('/api/me/teams'), throwsA(isA<ApiException>()));
      expect(session.isSignedIn, isFalse);
      expect(notified, 1);
    });
  });
}
