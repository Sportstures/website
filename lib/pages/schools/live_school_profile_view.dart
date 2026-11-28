import 'package:flutter/material.dart';

import '../../api/api_client.dart';
import '../../api/api_exception.dart';
import '../../api/coach_api.dart';
import '../../api/schools_api.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';
import '../../widgets/site/page_hero.dart';
import '../../widgets/site/site_routes.dart';
import '../../widgets/site/site_scaffold.dart';
import '../../widgets/site/ui_kit.dart';
import '../coach/photo_badge.dart';

/// One school's page on live data, found by its id, or by name when that is all the caller has.
class LiveSchoolProfileView extends StatefulWidget {
  const LiveSchoolProfileView({super.key, required this.api, this.schoolId, this.schoolName});

  final ApiClient api;
  final int? schoolId;
  final String? schoolName;

  @override
  State<LiveSchoolProfileView> createState() => _LiveSchoolProfileViewState();
}

class _LiveSchoolProfileViewState extends State<LiveSchoolProfileView> {
  late final SchoolsApi _api = SchoolsApi(widget.api);

  SchoolPageData? _data;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  static const _notFound = 'We could not find that school.';

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      var id = widget.schoolId;
      final name = widget.schoolName;
      if (id == null && name != null) id = await _api.idOf(name);
      if (id == null) {
        if (mounted) setState(() => _error = _notFound);
        return;
      }
      final data = await _api.school(id);
      if (mounted) setState(() => _data = data);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.status == 404 ? _notFound : e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Something went wrong loading this school.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    final school = data?.school;
    return SiteScaffold(
      currentRoute: SiteRoutes.schools,
      children: [
        PageHero(
          title: school?.name ?? 'School',
          breadcrumb: school?.name ?? 'School',
          subtitle: school == null
              ? 'Teams, fixtures and results.'
              : (school.location.isEmpty ? 'Teams, fixtures and results.' : 'Competing from ${school.location}.'),
          trailing: school == null ? null : PhotoBadge(fallback: school.name, size: 76, square: true),
        ),
        ContentWidth(
          child: Padding(
            padding: const EdgeInsets.only(top: 28, bottom: 56),
            child: data != null
                ? _content(data)
                : _error == null
                    ? const Padding(padding: EdgeInsets.all(48), child: Center(child: CircularProgressIndicator()))
                    : SectionCard(
                        title: "Couldn't open this school",
                        child: Column(children: [
                          EmptyState(_error!),
                          const SizedBox(height: 8),
                          if (_error != _notFound) ...[
                            SiteButton(label: 'TRY AGAIN', small: true, onPressed: _load),
                            const SizedBox(height: 8),
                          ],
                          SiteButton(
                            label: 'ALL SCHOOLS',
                            small: true,
                            variant: SiteButtonVariant.outline,
                            onPressed: () => openSiteRoute(context, SiteRoutes.schools),
                          ),
                          const SizedBox(height: 12),
                        ]),
                      ),
          ),
        ),
      ],
    );
  }

  Widget _content(SchoolPageData data) {
    final s = data.school;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StatsBand(valueColor: AppColors.orange, stats: [
          (Icons.groups_outlined, '${s.teamCount}', 'Teams'),
          (Icons.sports, '${s.sports.length}', 'Sports played'),
          (Icons.scoreboard_outlined, '${s.played}', 'Matches played'),
          (Icons.emoji_events_outlined, '${s.won}', 'Wins'),
        ]),
        const SizedBox(height: 24),
        TwoColumnLayout(
          main: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _teams(data.teams),
              const SizedBox(height: 16),
              _matches(
                'Upcoming fixtures',
                // Matches whose day has passed without a result are left out.
                [for (final f in data.upcoming) if (f.status == 'live' || !f.startsAt.isBefore(DateUtils.dateOnly(DateTime.now()))) f],
                'No upcoming fixtures.',
                result: false,
              ),
              const SizedBox(height: 16),
              _matches('Recent results', data.results, 'No results yet.', result: true),
            ],
          ),
          sidebar: SectionCard(
            title: 'Record',
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  for (final (label, value) in [
                    ('Won', '${s.won}'),
                    ('Drawn', '${s.drawn}'),
                    ('Lost', '${s.lost}'),
                    ('Win rate', s.winRate == null ? '–' : '${s.winRate}%'),
                  ])
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(children: [
                        Expanded(child: Text(label, style: tableCellStyle)),
                        Text(value, style: tableStrongStyle),
                      ]),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _teams(List<SchoolTeam> teams) => SectionCard(
        title: 'Teams',
        child: teams.isEmpty
            ? const EmptyState('No teams registered yet.')
            : DividedColumn(
                children: [
                  for (final t in teams)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          PhotoBadge(url: t.logoUrl, fallback: t.name, size: 36, square: true),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(t.name, style: tableStrongStyle),
                                Text(
                                  [?t.sport, ?t.ageGroup, if (t.coach != null) 'Coach ${t.coach}'].join(' · '),
                                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                                ),
                              ],
                            ),
                          ),
                          CountLabel(count: t.playerCount, noun: 'player'),
                        ],
                      ),
                    ),
                ],
              ),
      );

  Widget _matches(String title, List<CoachFixture> matches, String empty, {required bool result}) => SectionCard(
        title: title,
        child: matches.isEmpty
            ? EmptyState(empty)
            : DividedColumn(
                children: [
                  for (final f in matches)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${f.homeName} vs ${f.awayName}', style: tableStrongStyle),
                                Text(
                                  [
                                    '${formatShortDate(f.startsAt)}, ${formatTime(f.startsAt)}',
                                    ?f.competition,
                                    if (f.venue != null && f.venue!.isNotEmpty) f.venue!,
                                  ].join(' · '),
                                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                                ),
                              ],
                            ),
                          ),
                          if (result && f.hasScore)
                            Text('${f.homeScore} - ${f.awayScore}',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.green))
                          else if (f.status != 'scheduled')
                            StatusPill(f.status, color: f.status == 'live' ? Colors.red : AppColors.orange),
                        ],
                      ),
                    ),
                ],
              ),
      );
}
