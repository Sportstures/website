import 'package:flutter/material.dart';

import '../data/models.dart';
import '../data/sports_data.dart';
import '../utils/formatters.dart';
import 'ai_service.dart';
import 'local_ai_service.dart';

/// Answers questions about the season from the fixtures and results the app
/// already holds.
///
/// It reads a question by pulling out what it recognises - schools, a sport, a
/// region, a sense of time - and then picking the reading that fits what was
/// found. It is deliberately narrow: when nothing matches it says so and offers
/// what it can do, rather than guessing and sounding confident about it.
///
/// Swapping [aiService] for a backend-backed implementation replaces this with
/// a real language model and the assistant panel does not change.
class LocalAssistant {
  const LocalAssistant(this._service);

  final LocalAiService _service;

  SportsData get _data => _service.data ?? SportsData.instance;

  AiAnswer answer(String question) {
    final text = question.toLowerCase().replaceAll(RegExp(r'[^a-z0-9\s/]'), ' ');
    if (text.trim().isEmpty) return _fallback();

    final schools = _schoolsIn(text);
    final sport = _sportIn(text);
    final region = _regionIn(text);

    // Most specific first: two schools named is a question about that match.
    if (schools.length >= 2) return _matchup(schools[0], schools[1], sport);

    if (schools.length == 1) {
      final school = schools.single;
      if (_mentions(text, const ['next', 'when', 'upcoming', 'fixture', 'playing', 'play'])) {
        return _nextFixture(school, sport);
      }
      if (_mentions(text, const ['form', 'how did', 'how are', 'recent', 'last', 'result', 'doing'])) {
        return _form(school, sport);
      }
      return _school(school);
    }

    if (_mentions(text, const ['top scorer', 'most goals', 'most points', 'scores the most', 'highest scoring'])) {
      return _topScoring(sport, region);
    }
    if (_mentions(text, const ['top', 'best', 'leading', 'leader', 'first', 'winning', 'table', 'standing'])) {
      return _leader(sport, region);
    }
    if (_mentions(text, const ['today', 'tomorrow', 'this week', 'weekend', 'fixture', 'playing', 'on'])) {
      return _whatsOn(text, sport, region);
    }
    if (_mentions(text, const ['watch', 'worth', 'interesting', 'recommend', 'should i'])) {
      return _toWatch(sport);
    }

    return _fallback();
  }

  // --- readings ------------------------------------------------------------

  AiAnswer _matchup(School home, School away, Sport? sport) {
    final fixture = _data.fixtures.firstWhere(
      (f) =>
          (f.home == home && f.away == away) || (f.home == away && f.away == home),
      orElse: () => Fixture(
        sport: sport ?? _sharedSport(home, away),
        ageGroup: 'U/19',
        league: 'Friendlies',
        home: home,
        away: away,
        startsAt: DateTime.now().add(const Duration(days: 7)),
      ),
    );

    final analysis = _service.analyzeFixtureSync(fixture);
    final scheduled = _data.fixtures.contains(fixture);

    return AiAnswer(
      text: scheduled
          ? '${analysis.verdict}. They meet in ${fixture.sport.label} ${fixture.ageGroup} on '
              '${formatShortDate(fixture.startsAt)}, and the model gives '
              '${home.name} ${(analysis.homeWinChance * 100).round()}% against '
              '${(analysis.awayWinChance * 100).round()}%.'
          : 'They have nothing scheduled, but on current form ${analysis.verdict.toLowerCase()}: '
              '${home.name} ${(analysis.homeWinChance * 100).round()}% against '
              '${(analysis.awayWinChance * 100).round()}% in '
              '${fixture.sport.label.toLowerCase()}.',
      insights: [
        for (final factor in analysis.factors.take(3))
          AiInsight(icon: Icons.auto_awesome, headline: factor.headline, detail: factor.detail),
      ],
      fixture: scheduled ? fixture : null,
      suggestions: [
        'How is ${home.name} doing?',
        'When does ${away.name} play next?',
      ],
    );
  }

  AiAnswer _nextFixture(School school, Sport? sport) {
    final upcoming = _data.fixtures
        .where((f) => (f.home == school || f.away == school) && (sport == null || f.sport == sport))
        .take(4)
        .toList(growable: false);

    if (upcoming.isEmpty) {
      return AiAnswer(
        text: '${school.name} have nothing coming up'
            '${sport == null ? '' : ' in ${sport.label.toLowerCase()}'} in the fixtures I can see.',
        suggestions: ['How is ${school.name} doing?', 'What is on this week?'],
      );
    }

    final next = upcoming.first;
    final opponent = next.home == school ? next.away : next.home;

    return AiAnswer(
      text: '${school.name} are ${next.home == school ? 'at home to' : 'away at'} '
          '${opponent.name} on ${formatShortDate(next.startsAt)} at '
          '${formatTime(next.startsAt)}, in ${next.sport.label} ${next.ageGroup}.',
      insights: [
        for (final fixture in upcoming.skip(1))
          AiInsight(
            icon: Icons.event_outlined,
            headline: '${fixture.home.name} vs ${fixture.away.name}',
            detail: '${fixture.competition} · ${formatShortDate(fixture.startsAt)} · '
                '${formatTime(fixture.startsAt)}',
          ),
      ],
      fixture: next,
      suggestions: [
        '${school.name} vs ${opponent.name}',
        'How is ${school.name} doing?',
      ],
    );
  }

  AiAnswer _form(School school, Sport? sport) {
    final played = _data.results
        .where((r) =>
            (r.fixture.home == school || r.fixture.away == school) &&
            (sport == null || r.fixture.sport == sport))
        .take(5)
        .toList(growable: false);

    if (played.isEmpty) {
      return AiAnswer(
        text: '${school.name} have not played'
            '${sport == null ? '' : ' any ${sport.label.toLowerCase()}'} yet.',
        suggestions: ['When does ${school.name} play next?'],
      );
    }

    var won = 0;
    var drawn = 0;
    for (final result in played) {
      final forScore = result.fixture.home == school ? result.homeScore : result.awayScore;
      final againstScore = result.fixture.home == school ? result.awayScore : result.homeScore;
      if (forScore > againstScore) {
        won++;
      } else if (forScore == againstScore) {
        drawn++;
      }
    }
    final lost = played.length - won - drawn;

    return AiAnswer(
      text: '${school.name} have won $won, drawn $drawn and lost $lost of their last '
          '${played.length}${sport == null ? '' : ' in ${sport.label.toLowerCase()}'}.',
      insights: [
        for (final result in played.take(4))
          AiInsight(
            icon: _outcomeIcon(result, school),
            headline: '${result.fixture.home.name} ${result.homeScore}-${result.awayScore} '
                '${result.fixture.away.name}',
            detail: '${result.fixture.competition} · '
                '${formatShortDate(result.fixture.startsAt)}',
          ),
      ],
      suggestions: ['When does ${school.name} play next?', 'Who is top of the table?'],
    );
  }

  AiAnswer _leader(Sport? sport, String? region) {
    final chosen = sport ?? Sport.football;
    final results = _resultsFor(chosen, region);
    if (results.isEmpty) return _noDataFor(chosen, region);

    final table = SportsData.standingsFor(results);
    final summary = _service.summarizeStandingsSync(table, chosen);
    final leader = table.first;

    return AiAnswer(
      text: '${summary.headline}${region == null ? '' : ' in $region'}. '
          'They have ${leader.points} points from ${leader.played} played, '
          'with a score difference of ${leader.scoreDifference >= 0 ? '+' : ''}'
          '${leader.scoreDifference}.',
      insights: summary.insights.take(3).toList(growable: false),
      suggestions: [
        'How is ${leader.school.name} doing?',
        'Who scores the most in ${chosen.label.toLowerCase()}?',
      ],
    );
  }

  AiAnswer _topScoring(Sport? sport, String? region) {
    final chosen = sport ?? Sport.football;
    final results = _resultsFor(chosen, region);
    if (results.isEmpty) return _noDataFor(chosen, region);

    final table = SportsData.standingsFor(results)
      ..sort((a, b) => (b.scored / b.played).compareTo(a.scored / a.played));
    final best = table.first;

    return AiAnswer(
      text: '${best.school.name} score the most ${chosen.scoreLabel.toLowerCase()} in '
          '${chosen.label.toLowerCase()}${region == null ? '' : ' in $region'}: '
          '${(best.scored / best.played).toStringAsFixed(1)} a game across '
          '${best.played} matches.',
      insights: [
        for (final standing in table.take(4).skip(1))
          AiInsight(
            icon: Icons.sports_score,
            headline: standing.school.name,
            detail: '${(standing.scored / standing.played).toStringAsFixed(1)} '
                '${chosen.scoreLabel.toLowerCase()} a game from ${standing.played} matches.',
          ),
      ],
      suggestions: ['Who is top of the ${chosen.label.toLowerCase()} table?'],
    );
  }

  AiAnswer _whatsOn(String text, Sport? sport, String? region) {
    final now = DateTime.now();
    final (from, to, label) = switch (text) {
      _ when text.contains('tomorrow') => (
          DateUtils.dateOnly(now.add(const Duration(days: 1))),
          DateUtils.dateOnly(now.add(const Duration(days: 2))),
          'tomorrow',
        ),
      _ when text.contains('week') || text.contains('weekend') => (
          DateUtils.dateOnly(now),
          DateUtils.dateOnly(now.add(const Duration(days: 7))),
          'over the next week',
        ),
      _ => (DateUtils.dateOnly(now), DateUtils.dateOnly(now.add(const Duration(days: 1))), 'today'),
    };

    final matching = _data.fixtures
        .where((f) =>
            !f.startsAt.isBefore(from) &&
            f.startsAt.isBefore(to) &&
            (sport == null || f.sport == sport) &&
            (region == null || f.home.region == region || f.away.region == region))
        .toList(growable: false);

    if (matching.isEmpty) {
      return AiAnswer(
        text: 'Nothing $label'
            '${sport == null ? '' : ' in ${sport.label.toLowerCase()}'}'
            '${region == null ? '' : ' in $region'}.',
        suggestions: const ['What is on this week?', 'Which matches are worth watching?'],
      );
    }

    final sports = matching.map((f) => f.sport).toSet();
    return AiAnswer(
      text: '${matching.length} ${matching.length == 1 ? 'fixture' : 'fixtures'} $label'
          '${sports.length == 1 ? ' in ${sports.single.label.toLowerCase()}' : ' across ${sports.length} sports'}'
          '${region == null ? '' : ' in $region'}.',
      insights: [
        for (final fixture in matching.take(4))
          AiInsight(
            icon: Icons.event_outlined,
            headline: '${fixture.home.name} vs ${fixture.away.name}',
            detail: '${fixture.competition} · ${formatTime(fixture.startsAt)} · '
                '${fixture.venue}',
          ),
      ],
      fixture: matching.first,
      suggestions: const ['Which matches are worth watching?'],
    );
  }

  AiAnswer _toWatch(Sport? sport) {
    final candidates = _data.fixtures
        .where((f) => sport == null || f.sport == sport)
        .toList(growable: false);
    final picks = _service.recommendFixturesSync(candidates, limit: 3);

    if (picks.isEmpty) {
      return const AiAnswer(
        text: 'Nothing stands out yet. Once these sides have played a few more matches the '
            'picks get sharper.',
        suggestions: ['What is on this week?'],
      );
    }

    final best = picks.first.fixture;
    return AiAnswer(
      text: '${best.home.name} vs ${best.away.name} is the pick of what is coming up. '
          '${picks.first.reason}',
      insights: [
        for (final pick in picks.skip(1))
          AiInsight(
            icon: Icons.star_outline,
            headline: '${pick.fixture.home.name} vs ${pick.fixture.away.name}',
            detail: pick.reason,
          ),
      ],
      fixture: best,
      suggestions: ['${best.home.name} vs ${best.away.name}'],
    );
  }

  AiAnswer _school(School school) {
    final played = _data.results
        .where((r) => r.fixture.home == school || r.fixture.away == school)
        .length;
    final next = _data.fixtures
        .where((f) => f.home == school || f.away == school)
        .firstOrNull;

    return AiAnswer(
      // The backend does not record a school's type or athlete numbers, so only the sample mentions them.
      text: _data.isSample
          ? '${school.name} is a ${school.type.label.toLowerCase()} school in '
              '${school.location}, competing in ${school.region}. They field '
              '${school.sports.length} sports with ${formatThousands(school.athletes)} athletes, '
              'and have played $played ${played == 1 ? 'match' : 'matches'} so far.'
          : '${school.name}${school.region.isEmpty ? '' : ' (${school.region})'} play '
              '${school.sports.length} ${school.sports.length == 1 ? 'sport' : 'sports'} in the matches I can see, '
              'with $played finished ${played == 1 ? 'match' : 'matches'}.',
      insights: [
        if (next != null)
          AiInsight(
            icon: Icons.event_outlined,
            headline: 'Next up: ${next.home.name} vs ${next.away.name}',
            detail: '${next.competition} · ${formatShortDate(next.startsAt)} · '
                '${formatTime(next.startsAt)}',
          ),
        AiInsight(
          icon: Icons.sports,
          headline: 'Sports played',
          detail: school.sports.map((s) => s.label).join(', '),
        ),
      ],
      fixture: next,
      suggestions: [
        'How is ${school.name} doing?',
        'When does ${school.name} play next?',
      ],
    );
  }

  AiAnswer _noDataFor(Sport sport, String? region) => AiAnswer(
        text: 'No ${sport.label.toLowerCase()} has been played'
            '${region == null ? '' : ' in $region'} yet.',
        suggestions: const ['Who is top of the football table?'],
      );

  AiAnswer _fallback() => AiAnswer(
        text: 'I can look up fixtures, results, form and tables from the season so far. '
            'Try naming a school, a sport or a region.',
        insights: [
          AiInsight(
            icon: Icons.event_outlined,
            headline: 'Fixtures',
            detail: '"When does ${_example(0)} play next?" or "What is on this week?"',
          ),
          AiInsight(
            icon: Icons.insights_outlined,
            headline: 'Form and tables',
            detail: '"How is ${_example(1)} doing?" or "Who is top in rugby?"',
          ),
          const AiInsight(
            icon: Icons.auto_awesome,
            headline: 'Match-ups',
            detail: 'Name two schools and I will read the match for you.',
          ),
        ],
        suggestions: starterQuestions(),
      );

  /// A real school's name to use in an example question.
  String _example(int index) {
    final schools = _data.allSchools;
    return schools.isEmpty ? 'your school' : schools[index % schools.length].name;
  }

  List<String> starterQuestions() {
    return [
      'What is on this week?',
      'Who is top in football?',
      if (_data.allSchools.isNotEmpty) 'How is ${_data.allSchools.first.name} doing?',
      'Which matches are worth watching?',
    ];
  }

  // --- reading the question ------------------------------------------------

  /// Schools named in [text], in the order they appear. Matches the full name
  /// and the first word, which is distinctive for every school in the data.
  List<School> _schoolsIn(String text) {
    final found = <(int, School)>[];
    for (final school in _data.allSchools) {
      final name = school.name.toLowerCase();
      var at = text.indexOf(name);
      if (at < 0) {
        final first = name.split(' ').first;
        // Guard against a first word that is not distinctive on its own.
        final shared = _data.allSchools
            .where((other) => other.name.toLowerCase().startsWith('$first '))
            .length;
        if (first.length >= 5 && shared == 1) at = text.indexOf(first);
      }
      if (at >= 0) found.add((at, school));
    }
    found.sort((a, b) => a.$1.compareTo(b.$1));
    return [for (final (_, school) in found) school];
  }

  Sport? _sportIn(String text) {
    for (final sport in Sport.values) {
      if (text.contains(sport.label.toLowerCase())) return sport;
    }
    return null;
  }

  String? _regionIn(String text) {
    for (final region in _data.regionOptions) {
      if (text.contains(region.toLowerCase())) return region;
    }
    return null;
  }

  static bool _mentions(String text, List<String> words) =>
      words.any((word) => text.contains(word));

  List<MatchResult> _resultsFor(Sport sport, String? region) => _data.results
      .where((r) =>
          r.fixture.sport == sport &&
          (region == null || r.fixture.home.region == region || r.fixture.away.region == region))
      .toList(growable: false);

  Sport _sharedSport(School a, School b) {
    final shared = a.sports.where(b.sports.contains);
    return shared.isEmpty ? a.sports.first : shared.first;
  }

  static IconData _outcomeIcon(MatchResult result, School school) {
    final forScore = result.fixture.home == school ? result.homeScore : result.awayScore;
    final againstScore = result.fixture.home == school ? result.awayScore : result.homeScore;
    if (forScore > againstScore) return Icons.arrow_upward;
    if (forScore == againstScore) return Icons.remove;
    return Icons.arrow_downward;
  }
}
