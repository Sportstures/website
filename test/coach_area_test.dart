import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:website/api/api_client.dart';
import 'package:website/api/coach_api.dart';
import 'package:website/api/session.dart';
import 'package:website/data/match_store.dart';
import 'package:website/main.dart';
import 'package:website/pages/coach/coach_home_page.dart';
import 'package:website/pages/coach/coach_team_page.dart';

http.Response _json(int status, Object? body) =>
    http.Response(body == null ? '' : jsonEncode(body), status, headers: {'content-type': 'application/json'});

http.Response _error(int status, String code, [String message = 'msg']) =>
    _json(status, {'error': {'code': code, 'message': message}});

const _team = {
  'id': 10,
  'name': 'Alpha Boys',
  'level': '1st_team',
  'sport': {'id': 1, 'name': 'Basketball'},
  'school': {'id': 1, 'name': 'Alpha High', 'province': 'Gauteng', 'town': null},
};

Map<String, dynamic> _side(String school, int id) => {
      'id': id,
      'name': '$school Boys',
      'level': '1st_team',
      'sport': {'id': 1, 'name': 'Basketball'},
      'school': {'id': id, 'name': school, 'province': null, 'town': null},
    };

Map<String, dynamic> _fixture(int id, String opponent, int opponentId, {required DateTime at, bool home = true, int? mine, int? theirs, String? venue}) => {
      'id': id,
      'matchDate': at.toUtc().toIso8601String(),
      'status': mine == null ? 'scheduled' : 'finished',
      'venue': venue,
      'competition': {'id': 1, 'name': 'Schools League'},
      'homeTeam': home ? _team : _side(opponent, opponentId),
      'awayTeam': home ? _side(opponent, opponentId) : _team,
      'score': mine == null ? null : {'home': home ? mine : theirs, 'away': home ? theirs : mine},
    };

DateTime _days(int n) => DateTime.now().add(Duration(days: n));

Map<String, dynamic> _member(int id, String name, {String status = 'active', int? jersey, String? position, int grade = 9}) => {
      'userId': id,
      'name': name,
      'status': status,
      'jerseyNumber': jersey,
      'position': position,
      'grade': grade,
      'className': '9A',
      'requestedAt': DateTime.now().toUtc().toIso8601String(),
    };

/// A fake backend for a coach's team. Rosters change when the page calls the write endpoints.
class _Backend {
  _Backend() {
    squad = [_member(1, 'Pat Player', jersey: 4, position: 'Guard'), _member(2, 'Quinn Player', jersey: 9)];
    requests = [_member(3, 'Rae Player', status: 'pending', jersey: 4)];
    candidates = [
      {'userId': 5, 'name': 'Noah Three', 'grade': 9, 'className': '9A', 'declaredSport': 'Basketball', 'declaredJerseyNumber': 11},
    ];
  }

  late List<Map<String, dynamic>> squad;
  late List<Map<String, dynamic>> requests;
  late List<Map<String, dynamic>> candidates;
  final requestsSeen = <http.Request>[];
  Map<String, dynamic>? dashboardOverride;
  http.Response? dashboardError;
  http.Response? writeError;

  Map<String, dynamic> dashboard() =>
      dashboardOverride ??
      {
        'team': {..._team, 'playerCount': squad.length},
        'squadSize': squad.length,
        'pendingRequests': requests.length,
        'record': {'played': 5, 'won': 3, 'drawn': 1, 'lost': 1, 'winRate': 60, 'form': ['W', 'L', 'D', 'W', 'W']},
        'nextMatch': _fixture(1, 'Bravo High', 2, at: _days(2), venue: 'Alpha Main Court'),
        'upcoming': [_fixture(1, 'Bravo High', 2, at: _days(2), venue: 'Alpha Main Court'), _fixture(2, 'Charlie High', 3, at: _days(9), home: false)],
        'recentResults': [_fixture(10, 'Delta High', 4, at: _days(-3), mine: 70, theirs: 55), _fixture(11, 'Echo High', 5, at: _days(-10), home: false, mine: 40, theirs: 60)],
        'actionItems': [
          {'type': 'record_result', 'dueAt': _days(-1).toUtc().toIso8601String(), 'fixture': _fixture(12, 'Foxtrot High', 6, at: _days(-1))},
          {'type': 'submit_lineup', 'dueAt': _days(2).toUtc().toIso8601String(), 'fixture': _fixture(1, 'Bravo High', 2, at: _days(2))},
          {'type': 'file_report', 'dueAt': _days(-3).toUtc().toIso8601String(), 'fixture': _fixture(10, 'Delta High', 4, at: _days(-3), mine: 70, theirs: 55)},
          if (requests.isNotEmpty) {'type': 'review_join_requests', 'dueAt': null, 'count': requests.length},
        ],
      };

  http.Response handle(http.Request r) {
    requestsSeen.add(r);
    final path = r.url.path;
    final method = r.method;
    if (path == '/api/auth/login') {
      return _json(200, {
        'accessToken': 'A',
        'refreshToken': 'R',
        'user': {'id': 7, 'role': r.body.contains('learner') ? 'learner' : 'coach', 'firstName': 'Thabo', 'lastName': 'Dlamini', 'team': _team},
      });
    }
    if (path == '/api/coach/dashboard') return dashboardError ?? _json(200, dashboard());
    if (path == '/api/teams/10/roster' && method == 'GET') {
      return _json(200, {'roster': r.url.queryParameters['status'] == 'pending' ? requests : squad});
    }
    if (path == '/api/teams/10/candidates') {
      final q = (r.url.queryParameters['q'] ?? '').toLowerCase();
      return _json(200, {'candidates': candidates.where((c) => '${c['name']}'.toLowerCase().contains(q)).toList()});
    }
    if (method != 'GET' && writeError != null) return writeError!;
    if (path == '/api/teams/10/roster' && method == 'POST') {
      final body = jsonDecode(r.body) as Map<String, dynamic>;
      final id = body['userId'] as int;
      final fromRequests = requests.where((m) => m['userId'] == id).toList();
      final person = fromRequests.isNotEmpty ? fromRequests.first : _member(id, 'Noah Three');
      requests.removeWhere((m) => m['userId'] == id);
      candidates.removeWhere((c) => c['userId'] == id);
      squad.add({...person, 'status': 'active', 'jerseyNumber': body['jerseyNumber'], 'position': body['position']});
      return _json(201, {'member': person});
    }
    final member = RegExp(r'^/api/teams/10/roster/(\d+)$').firstMatch(path);
    if (member != null) {
      final id = int.parse(member.group(1)!);
      if (method == 'PATCH') {
        final body = jsonDecode(r.body) as Map<String, dynamic>;
        final i = squad.indexWhere((m) => m['userId'] == id);
        squad[i] = {...squad[i], ...body};
        return _json(200, {'member': squad[i]});
      }
      if (method == 'DELETE') {
        squad.removeWhere((m) => m['userId'] == id);
        requests.removeWhere((m) => m['userId'] == id);
        return http.Response('', 204);
      }
    }
    return _error(404, 'NOT_FOUND');
  }

  Iterable<http.Request> writes() => requestsSeen.where((r) => r.method != 'GET' && r.url.path != '/api/auth/login');
}

/// Pumps [page] inside a session. [role] null means nobody is signed in.
Future<_Backend> _pump(WidgetTester tester, Widget page, {String? role = 'coach', _Backend? backend}) async {
  tester.view.physicalSize = const Size(1400, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final b = backend ?? _Backend();
  final api = ApiClient(baseUrl: 'http://api.test', httpClient: MockClient((r) async => b.handle(r)));
  final session = Session(api);
  if (role != null) await session.login(role == 'learner' ? 'learner@x.com' : 'coach@x.com', 'Passw0rdOK');
  await tester.pumpWidget(SessionScope(session: session, child: MaterialApp(home: page)));
  await tester.pumpAndSettle();
  return b;
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder.first);
  await tester.tap(finder.first);
  await tester.pumpAndSettle();
}

Finder _inDialog(Finder f) => find.descendant(of: find.byType(AlertDialog), matching: f);

void main() {
  group('CoachFixture and models', () {
    test('a fixture is read from backend JSON, using the school name when there is one', () {
      final f = CoachFixture.fromJson(_fixture(1, 'Bravo High', 2, at: _days(1), home: false, mine: 3, theirs: 1));
      expect(f.homeName, 'Bravo High');
      expect(f.awayName, 'Alpha High');
      expect(f.opponentOf(10), 'Bravo High');
      expect(f.isHome(10), isFalse);
      expect(f.outcomeFor(10), 'W');
      expect(f.outcomeFor(2), 'L');
    });

    test('no score means no outcome', () {
      final f = CoachFixture.fromJson(_fixture(1, 'Bravo High', 2, at: _days(1)));
      expect(f.hasScore, isFalse);
      expect(f.outcomeFor(10), isNull);
    });

    test('a draw', () {
      final f = CoachFixture.fromJson(_fixture(1, 'Bravo High', 2, at: _days(-1), mine: 2, theirs: 2));
      expect(f.outcomeFor(10), 'D');
    });
  });

  group('who can see the coach area', () {
    testWidgets('a visitor is asked to log in, and nothing is requested', (tester) async {
      final b = await _pump(tester, const CoachHomePage(), role: null);
      expect(find.text('LOG IN TO CONTINUE'), findsOneWidget);
      expect(find.text('LOG IN'), findsOneWidget);
      expect(b.requestsSeen, isEmpty);
    });

    testWidgets('a learner is told this is for coaches', (tester) async {
      final b = await _pump(tester, const CoachTeamPage(), role: 'learner');
      expect(find.text('COACHES ONLY'), findsOneWidget);
      expect(b.requestsSeen.where((r) => r.url.path.contains('/roster')), isEmpty);
    });
  });

  group('coach dashboard', () {
    testWidgets('shows the team, the numbers, the next match and results', (tester) async {
      await _pump(tester, const CoachHomePage());
      expect(find.text('Alpha Boys'), findsOneWidget);
      expect(find.textContaining('Basketball'), findsWidgets);
      expect(find.text('2'), findsWidgets, reason: 'squad size and upcoming');
      expect(find.text('3W 1D 1L'), findsOneWidget);
      expect(find.text('60%'), findsOneWidget);
      expect(find.text('Welcome back, Thabo.'), findsOneWidget);
      expect(find.text('vs Bravo High'), findsWidgets);
      expect(find.text('Alpha Main Court'), findsWidgets);
      expect(find.text('70 - 55'), findsOneWidget);
      expect(find.text('60 - 40'), findsOneWidget);
    });

    testWidgets('lists every kind of action item in plain words', (tester) async {
      await _pump(tester, const CoachHomePage());
      expect(find.text('Record the result vs Foxtrot High'), findsOneWidget);
      expect(find.text('Submit your lineup vs Bravo High'), findsOneWidget);
      expect(find.text('File the match report vs Delta High'), findsOneWidget);
      expect(find.text('1 player wants to join your team'), findsOneWidget);
    });

    testWidgets('"players want to join" opens the squad page', (tester) async {
      await tester.pumpWidget(const SizedBox());
      final b = _Backend();
      tester.view.physicalSize = const Size(1400, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final api = ApiClient(baseUrl: 'http://api.test', httpClient: MockClient((r) async => b.handle(r)));
      final session = Session(api);
      await session.login('coach@x.com', 'Passw0rdOK');
      await tester.pumpWidget(SessionScope(
        session: session,
        child: MaterialApp(
          home: const CoachHomePage(),
          routes: {'/coach/team': (_) => const CoachTeamPage()},
        ),
      ));
      await tester.pumpAndSettle();
      await _tap(tester, find.text('1 player wants to join your team'));
      expect(find.text('JOIN REQUESTS'), findsOneWidget);
    });

    testWidgets('an empty dashboard shows friendly messages', (tester) async {
      final b = _Backend()
        ..dashboardOverride = {
          'team': _team,
          'squadSize': 0,
          'pendingRequests': 0,
          'record': {'played': 0, 'won': 0, 'drawn': 0, 'lost': 0, 'winRate': null, 'form': []},
          'nextMatch': null,
          'upcoming': [],
          'recentResults': [],
          'actionItems': [],
        };
      await _pump(tester, const CoachHomePage(), backend: b);
      expect(find.textContaining("You're all caught up"), findsOneWidget);
      expect(find.text('No matches are scheduled yet.'), findsOneWidget);
      expect(find.text('No upcoming match.'), findsOneWidget);
      expect(find.text('No results yet.'), findsOneWidget);
      expect(find.text('–'), findsOneWidget, reason: 'no win rate before a match is played');
    });

    testWidgets('a failure can be retried', (tester) async {
      final b = _Backend()..dashboardError = _error(500, 'INTERNAL', 'boom');
      await _pump(tester, const CoachHomePage(), backend: b);
      expect(find.text("COULDN'T LOAD YOUR DASHBOARD"), findsOneWidget);
      b.dashboardError = null;
      await _tap(tester, find.text('TRY AGAIN'));
      expect(find.text('Alpha Boys'), findsOneWidget);
    });

    testWidgets('a coach with no team is told so', (tester) async {
      final b = _Backend()..dashboardError = _error(404, 'TEAM_NOT_FOUND');
      await _pump(tester, const CoachHomePage(), backend: b);
      expect(find.text('NO TEAM YET'), findsOneWidget);
      expect(find.text('TRY AGAIN'), findsNothing);
    });
  });

  group('squad page', () {
    testWidgets('shows the squad, the join requests and who can be added', (tester) async {
      await _pump(tester, const CoachTeamPage());
      expect(find.text('Pat Player'), findsOneWidget);
      expect(find.text('Quinn Player'), findsOneWidget);
      expect(find.text('Guard'), findsOneWidget);
      expect(find.text('JOIN REQUESTS'), findsOneWidget);
      expect(find.text('Rae Player'), findsOneWidget);
      expect(find.text('Noah Three'), findsOneWidget);
    });

    testWidgets('approving a request sends the jersey number and moves the player to the squad', (tester) async {
      final b = await _pump(tester, const CoachTeamPage());
      expect(find.text('JOIN REQUESTS'), findsOneWidget);
      // the request asked for 4, which Pat already has; give Rae 12
      final jersey = find.widgetWithText(TextField, '4').last;
      await tester.enterText(jersey, '12');
      await _tap(tester, find.text('APPROVE'));

      final post = b.writes().single;
      expect(post.method, 'POST');
      expect(jsonDecode(post.body), {'userId': 3, 'jerseyNumber': 12});
      expect(find.text('JOIN REQUESTS'), findsNothing, reason: 'no requests left');
      expect(find.text('Rae Player'), findsOneWidget);
      expect(find.text('Rae Player is now on the team.'), findsOneWidget);
    });

    testWidgets('a taken jersey number is explained in plain words and nothing changes', (tester) async {
      final b = _Backend()..writeError = _error(409, 'JERSEY_TAKEN');
      await _pump(tester, const CoachTeamPage(), backend: b);
      await _tap(tester, find.text('APPROVE'));
      expect(find.text('That jersey number is already taken by another player.'), findsOneWidget);
      expect(find.text('JOIN REQUESTS'), findsOneWidget);
    });

    testWidgets('declining asks first, then removes the request', (tester) async {
      final b = await _pump(tester, const CoachTeamPage());
      await _tap(tester, find.text('DECLINE'));
      expect(find.text('Decline Rae Player?'), findsOneWidget);
      await _tap(tester, find.text('Cancel'));
      expect(b.writes(), isEmpty, reason: 'cancel changes nothing');

      await _tap(tester, find.text('DECLINE'));
      await _tap(tester, find.text('Decline').last);
      expect(b.writes().single.method, 'DELETE');
      expect(b.writes().single.url.path, '/api/teams/10/roster/3');
      expect(find.text('JOIN REQUESTS'), findsNothing);
    });

    testWidgets('editing a player changes their number and position', (tester) async {
      final b = await _pump(tester, const CoachTeamPage());
      await _tap(tester, find.byTooltip('Edit Quinn Player'));
      expect(find.text('Edit Quinn Player'), findsOneWidget);
      await tester.enterText(_inDialog(find.byType(TextField)).first, '10');
      await tester.enterText(_inDialog(find.byType(TextField)).last, 'Centre');
      await _tap(tester, find.text('Save'));

      final patch = b.writes().single;
      expect(patch.method, 'PATCH');
      expect(patch.url.path, '/api/teams/10/roster/2');
      expect(jsonDecode(patch.body), {'jerseyNumber': 10, 'position': 'Centre'});
      expect(find.text('Centre'), findsOneWidget);
    });

    testWidgets('clearing the number sends null', (tester) async {
      final b = await _pump(tester, const CoachTeamPage());
      await _tap(tester, find.byTooltip('Edit Pat Player'));
      await tester.enterText(_inDialog(find.byType(TextField)).first, '');
      await _tap(tester, find.text('Save'));
      expect(jsonDecode(b.writes().single.body), containsPair('jerseyNumber', null));
    });

    testWidgets('removing a player asks first', (tester) async {
      final b = await _pump(tester, const CoachTeamPage());
      await _tap(tester, find.byTooltip('Remove Pat Player'));
      expect(find.text('Remove Pat Player?'), findsOneWidget);
      await _tap(tester, find.text('Remove').last);
      expect(b.writes().single.url.path, '/api/teams/10/roster/1');
      expect(find.text('Pat Player'), findsNothing);
      expect(find.text('Pat Player was removed.'), findsOneWidget);
    });

    testWidgets('adding a school learner pre-fills the number they chose at signup', (tester) async {
      final b = await _pump(tester, const CoachTeamPage());
      await _tap(tester, find.text('ADD'));
      expect(find.text('Add Noah Three'), findsOneWidget);
      expect(_inDialog(find.widgetWithText(TextField, '11')), findsOneWidget);
      await tester.enterText(_inDialog(find.byType(TextField)).last, 'Forward');
      await _tap(tester, find.text('Add to team'));

      expect(jsonDecode(b.writes().single.body), {'userId': 5, 'jerseyNumber': 11, 'position': 'Forward'});
      expect(find.text('Noah Three was added.'), findsOneWidget);
      expect(find.text('No learners from your school are available to add.'), findsOneWidget);
    });

    testWidgets('searching asks the backend for matching learners', (tester) async {
      final b = await _pump(tester, const CoachTeamPage());
      await tester.enterText(find.widgetWithText(TextField, 'Search by name'), 'zzz');
      await _tap(tester, find.text('SEARCH'));
      final search = b.requestsSeen.lastWhere((r) => r.url.path.endsWith('/candidates'));
      expect(search.url.queryParameters['q'], 'zzz');
      expect(find.text('No learners from your school are available to add.'), findsOneWidget);
    });

    testWidgets('an empty squad invites the coach to add players', (tester) async {
      final b = _Backend()
        ..squad = []
        ..requests = [];
      await _pump(tester, const CoachTeamPage(), backend: b);
      expect(find.textContaining('No players yet'), findsOneWidget);
      expect(find.text('JOIN REQUESTS'), findsNothing);
    });
  });

  group('in the app', () {
    testWidgets('logging in as a coach lands on the dashboard, with a MY TEAM shortcut', (tester) async {
      tester.view.physicalSize = const Size(1400, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final b = _Backend();
      final api = ApiClient(baseUrl: 'http://api.test', httpClient: MockClient((r) async => b.handle(r)));
      await tester.pumpWidget(TobunApp(session: Session(api), matches: MatchStore.sample()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('LOGIN'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), 'coach@x.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'Passw0rdOK');
      await _tap(tester, find.text('Sign In'));

      expect(find.text('COACH DASHBOARD'), findsWidgets);
      expect(find.text('Alpha Boys'), findsOneWidget);
      expect(find.text('MY TEAM'), findsOneWidget);
    });

    testWidgets('a learner who logs in does not get a MY TEAM button', (tester) async {
      tester.view.physicalSize = const Size(1400, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final b = _Backend();
      final api = ApiClient(baseUrl: 'http://api.test', httpClient: MockClient((r) async => b.handle(r)));
      await tester.pumpWidget(TobunApp(session: Session(api), matches: MatchStore.sample()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('LOGIN'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), 'learner@x.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'Passw0rdOK');
      await _tap(tester, find.text('Sign In'));
      expect(find.text('LOG OUT'), findsOneWidget);
      expect(find.text('MY TEAM'), findsNothing);
    });
  });
}
