import 'package:flutter/material.dart';

import '../../api/api_exception.dart';
import '../../api/coach_api.dart';
import '../../api/session.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';
import '../../widgets/site/page_hero.dart';
import '../../widgets/site/site_routes.dart';
import '../../widgets/site/site_scaffold.dart';
import '../../widgets/site/ui_kit.dart';
import 'coach_guard.dart';
import 'photo_badge.dart';

/// The coach's home: team numbers, what is coming up, and what needs doing.
class CoachHomePage extends StatelessWidget {
  const CoachHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return CoachGuard(
      currentRoute: SiteRoutes.coach,
      title: 'Coach Dashboard',
      subtitle: 'Your team, your matches and what needs your attention.',
      builder: (context, coach) => _CoachHome(coach: coach),
    );
  }
}

class _CoachHome extends StatefulWidget {
  const _CoachHome({required this.coach});

  final AppUser coach;

  @override
  State<_CoachHome> createState() => _CoachHomeState();
}

class _CoachHomeState extends State<_CoachHome> {
  late Future<CoachDashboard> _future = _load();

  Future<CoachDashboard> _load() => CoachApi(SessionScope.read(context).api).dashboard();

  void _retry() {
    setState(() {
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final first = widget.coach.firstName;
    return SiteScaffold(
      currentRoute: SiteRoutes.coach,
      children: [
        PageHero(
          title: 'Coach Dashboard',
          breadcrumb: 'Coach Dashboard',
          subtitle: first == null || first.isEmpty ? 'Your team, your matches and what needs your attention.' : 'Welcome back, $first.',
        ),
        ContentWidth(
          child: Padding(
            padding: const EdgeInsets.only(top: 28, bottom: 56),
            child: FutureBuilder<CoachDashboard>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Padding(padding: EdgeInsets.symmetric(vertical: 48), child: Center(child: CircularProgressIndicator()));
                }
                if (snapshot.hasError) return _ErrorCard(error: snapshot.error!, onRetry: _retry);
                return _Dashboard(data: snapshot.data!, onChanged: _retry);
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final e = error is ApiException ? error as ApiException : null;
    final noTeam = e?.code == 'TEAM_NOT_FOUND';
    return SectionCard(
      title: noTeam ? 'No team yet' : "Couldn't load your dashboard",
      child: Column(
        children: [
          EmptyState(noTeam ? 'Your coach account does not have a team yet.' : (e?.message ?? 'Something went wrong. Please try again.')),
          if (!noTeam) ...[
            const SizedBox(height: 12),
            SiteButton(label: 'TRY AGAIN', small: true, onPressed: onRetry),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _Dashboard extends StatelessWidget {
  const _Dashboard({required this.data, required this.onChanged});

  final CoachDashboard data;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final record = data.record;
    final team = data.team;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TeamHeader(team: team),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _StatTile(icon: Icons.groups_outlined, label: 'Squad size', value: '${data.squadSize}'),
            _StatTile(icon: Icons.event_outlined, label: 'Upcoming', value: '${data.upcoming.length}'),
            _StatTile(icon: Icons.emoji_events_outlined, label: 'Season record', value: '${record.won}W ${record.drawn}D ${record.lost}L'),
            _StatTile(
              icon: Icons.trending_up,
              label: 'Win rate',
              value: record.winRate == null ? '–' : '${record.winRate!.round()}%',
            ),
          ],
        ),
        const SizedBox(height: 20),
        TwoColumnLayout(
          main: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ActionItems(items: data.actionItems, teamId: team.id),
              const SizedBox(height: 16),
              _Upcoming(fixtures: data.upcoming, teamId: team.id),
            ],
          ),
          sidebar: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _NextMatch(fixture: data.nextMatch, teamId: team.id),
              const SizedBox(height: 16),
              _RecentResults(fixtures: data.recentResults, teamId: team.id, form: record.form),
              const SizedBox(height: 16),
              SectionCard(
                title: 'Grow the league',
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Invite a coach from another school, so you can play each other on Sportstures.',
                        style: TextStyle(fontSize: 13, color: AppColors.muted, height: 1.5),
                      ),
                      const SizedBox(height: 12),
                      SiteButton(label: 'INVITE ANOTHER SCHOOL', small: true, onPressed: () => openSiteRoute(context, SiteRoutes.coachInvite)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SectionCard(
                title: 'Your squad',
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        data.pendingRequests > 0
                            ? '${data.squadSize} players · ${data.pendingRequests} waiting to join'
                            : '${data.squadSize} players',
                        style: const TextStyle(fontSize: 13, color: AppColors.ink),
                      ),
                      const SizedBox(height: 12),
                      SiteButton(label: 'MANAGE SQUAD', small: true, onPressed: () => openSiteRoute(context, SiteRoutes.coachTeam)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TeamHeader extends StatelessWidget {
  const _TeamHeader({required this.team});

  final CoachTeam team;

  @override
  Widget build(BuildContext context) {
    final details = [team.sport, team.level, team.school, team.province].whereType<String>().where((s) => s.isNotEmpty).join(' · ');
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.green, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          PhotoBadge(url: team.logoUrl, fallback: team.name, size: 56, square: true),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(team.name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                if (details.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(details, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 270,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.green, size: 26),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.ink)),
                Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.muted, letterSpacing: 0.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _when(DateTime date) => '${formatShortDate(date)} · ${formatTime(date)}';

class _ActionItems extends StatelessWidget {
  const _ActionItems({required this.items, required this.teamId});

  final List<ActionItem> items;
  final int teamId;

  ({String title, String detail, IconData icon, VoidCallback? onTap}) _describe(BuildContext context, ActionItem item) {
    final f = item.fixture;
    final versus = f == null ? '' : 'vs ${f.opponentOf(teamId)}';
    return switch (item.type) {
      'record_result' => (
          title: 'Record the result $versus',
          detail: 'Played ${_when(f!.startsAt)}',
          icon: Icons.scoreboard_outlined,
          onTap: null,
        ),
      'submit_lineup' => (
          title: 'Submit your lineup $versus',
          detail: 'Kick-off ${_when(f!.startsAt)}',
          icon: Icons.format_list_numbered,
          onTap: null,
        ),
      'file_report' => (
          title: 'File the match report $versus',
          detail: 'Played ${_when(f!.startsAt)}',
          icon: Icons.description_outlined,
          onTap: null,
        ),
      'review_join_requests' => (
          title: '${item.count} ${item.count == 1 ? 'player wants' : 'players want'} to join your team',
          detail: 'Approve or decline their requests',
          icon: Icons.person_add_alt_1_outlined,
          onTap: () => openSiteRoute(context, SiteRoutes.coachTeam),
        ),
      _ => (title: item.type, detail: '', icon: Icons.info_outline, onTap: null),
    };
  }

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Action items',
      trailing: CountLabel(count: items.length, noun: 'item'),
      child: items.isEmpty
          ? const EmptyState("You're all caught up. Nothing needs your attention right now.")
          : DividedColumn(
              children: [
                for (final item in items)
                  Builder(builder: (context) {
                    final d = _describe(context, item);
                    return InkWell(
                      onTap: d.onTap,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            Icon(d.icon, color: AppColors.orange, size: 22),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(d.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink)),
                                  if (d.detail.isNotEmpty)
                                    Text(d.detail, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                                ],
                              ),
                            ),
                            if (d.onTap != null) const Icon(Icons.chevron_right, color: AppColors.muted),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
    );
  }
}

class _Upcoming extends StatelessWidget {
  const _Upcoming({required this.fixtures, required this.teamId});

  final List<CoachFixture> fixtures;
  final int teamId;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Upcoming matches',
      trailing: CountLabel(count: fixtures.length, noun: 'match'),
      child: fixtures.isEmpty
          ? const EmptyState('No matches are scheduled yet.')
          : DividedColumn(
              children: [
                for (final f in fixtures)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        StatusPill(f.isHome(teamId) ? 'Home' : 'Away', color: f.isHome(teamId) ? AppColors.green : AppColors.orange),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('vs ${f.opponentOf(teamId)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink)),
                              Text(
                                [_when(f.startsAt), if (f.venue != null && f.venue!.isNotEmpty) f.venue!].join(' · '),
                                style: const TextStyle(fontSize: 12, color: AppColors.muted),
                              ),
                            ],
                          ),
                        ),
                        if (f.status == 'live') const StatusPill('Live', color: Colors.red),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

class _NextMatch extends StatelessWidget {
  const _NextMatch({required this.fixture, required this.teamId});

  final CoachFixture? fixture;
  final int teamId;

  @override
  Widget build(BuildContext context) {
    final f = fixture;
    return SectionCard(
      title: 'Next match',
      child: f == null
          ? const EmptyState('No upcoming match.')
          : Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('vs ${f.opponentOf(teamId)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink)),
                  const SizedBox(height: 4),
                  Text(formatLongDate(f.startsAt), style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                  Text(formatTime(f.startsAt), style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                  if (f.venue != null && f.venue!.isNotEmpty) Text(f.venue!, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                  if (f.competition != null) ...[
                    const SizedBox(height: 8),
                    Text(f.competition!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.green)),
                  ],
                ],
              ),
            ),
    );
  }
}

class _RecentResults extends StatelessWidget {
  const _RecentResults({required this.fixtures, required this.teamId, required this.form});

  final List<CoachFixture> fixtures;
  final int teamId;
  final List<String> form;

  Color _color(String? outcome) => switch (outcome) {
        'W' => AppColors.greenBright,
        'L' => Colors.red.shade400,
        _ => AppColors.muted,
      };

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Recent results',
      child: fixtures.isEmpty
          ? const EmptyState('No results yet.')
          : DividedColumn(
              children: [
                for (final f in fixtures)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        StatusPill(f.outcomeFor(teamId) ?? '–', color: _color(f.outcomeFor(teamId))),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text('vs ${f.opponentOf(teamId)}', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.ink)),
                        ),
                        Text(
                          f.hasScore ? '${f.homeScore} - ${f.awayScore}' : '',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.ink),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}
