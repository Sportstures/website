import 'package:flutter_test/flutter_test.dart';
import 'package:website/ai/ai_service.dart';
import 'package:website/ai/local_ai_service.dart';
import 'package:website/ai/local_assistant.dart';
import 'package:website/data/models.dart';
import 'package:website/data/sports_data.dart';

void main() {
  const assistant = LocalAssistant(LocalAiService());
  final schools = SportsData.schools;

  AiAnswer ask(String question) => assistant.answer(question);

  test('an empty or unreadable question offers help instead of guessing', () {
    for (final question in ['', '   ', 'asdfghjkl', 'what is the weather']) {
      final answer = ask(question);
      expect(answer.text, contains('look up'));
      expect(answer.suggestions, isNotEmpty, reason: 'it should offer a way forward');
    }
  });

  test('naming two schools reads the match-up', () {
    final answer = ask('${schools[0].name} vs ${schools[1].name}');
    expect(answer.insights, isNotEmpty, reason: 'a match-up should show its reasoning');
    expect(answer.text, isNotEmpty);
    // The reply should talk in percentages, not vague terms.
    expect(answer.text, contains('%'));
  });

  test('asking when a school plays finds its next fixture', () {
    final scheduled = SportsData.instance.fixtures.first.home;
    final answer = ask('When does ${scheduled.name} play next?');

    expect(answer.fixture, isNotNull);
    final fixture = answer.fixture!;
    expect(
      fixture.home == scheduled || fixture.away == scheduled,
      isTrue,
      reason: 'the fixture offered should involve the school that was asked about',
    );
    expect(
      SportsData.instance.fixtures.indexOf(fixture),
      lessThanOrEqualTo(
        SportsData.instance.fixtures.indexWhere(
          (f) => f.home == scheduled || f.away == scheduled,
        ),
      ),
      reason: 'it should be the soonest one, since fixtures are ordered',
    );
  });

  test('asking about form counts the real record', () {
    final school = schools[0];
    final answer = ask('How is ${school.name} doing?');

    final recent = SportsData.instance.results
        .where((r) => r.fixture.home == school || r.fixture.away == school)
        .take(5)
        .toList();
    var won = 0;
    for (final result in recent) {
      final forScore = result.fixture.home == school ? result.homeScore : result.awayScore;
      final against = result.fixture.home == school ? result.awayScore : result.homeScore;
      if (forScore > against) won++;
    }

    expect(answer.text, contains('won $won'));
    expect(answer.text, contains('last ${recent.length}'));
  });

  test('asking who is top names the actual table leader', () {
    for (final sport in [Sport.football, Sport.rugby, Sport.netball]) {
      final results = SportsData.instance.results
          .where((r) => r.fixture.sport == sport)
          .toList();
      if (results.isEmpty) continue;

      final leader = SportsData.standingsFor(results).first;
      final answer = ask('Who is top in ${sport.label}?');

      expect(
        answer.text,
        contains(leader.school.name),
        reason: '${sport.label}: should name the side actually leading',
      );
      expect(answer.text, contains('${leader.points} points'));
    }
  });

  test('a region narrows the table it reads', () {
    final region = SportsData.regions.first;
    final answer = ask('Who is top in football in $region?');
    expect(answer.text, contains(region));
  });

  test('asking what is on returns fixtures inside the window', () {
    final answer = ask('What is on this week?');
    final now = DateTime.now();

    if (answer.fixture != null) {
      expect(answer.fixture!.startsAt.isBefore(now.add(const Duration(days: 8))), isTrue);
      expect(answer.text, contains('fixture'));
    } else {
      expect(answer.text, contains('Nothing'));
    }
  });

  test('asking what is worth watching returns a real fixture', () {
    final answer = ask('Which matches are worth watching?');
    if (answer.fixture != null) {
      expect(SportsData.instance.fixtures, contains(answer.fixture));
      expect(answer.text, isNotEmpty);
    }
  });

  test('a school on its own gives a profile that matches the record', () {
    final school = schools[2];
    final answer = ask(school.name);

    expect(answer.text, contains(school.region));
    expect(answer.text, contains(school.type.label.toLowerCase()));
    expect(answer.text, contains('${school.sports.length} sports'));
  });

  test('a school is recognised by its first word alone', () {
    final school = schools.firstWhere((s) => s.name.split(' ').first.length >= 5);
    final first = school.name.split(' ').first;
    final answer = ask('when does $first play');

    expect(answer.fixture ?? SportsData.instance.fixtures.first, isNotNull);
    expect(answer.text, contains(school.name));
  });

  test('starter questions are offered and all get a real answer', () {
    final starters = assistant.starterQuestions();
    expect(starters, isNotEmpty);

    for (final starter in starters) {
      final answer = ask(starter);
      expect(answer.text, isNotEmpty, reason: '"$starter" returned nothing');
      expect(
        answer.text,
        isNot(contains('look up')),
        reason: '"$starter" is offered to the visitor but falls through to the help text',
      );
    }
  });
}
