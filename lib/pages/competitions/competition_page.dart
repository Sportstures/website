import 'package:flutter/material.dart';

import '../../api/api_client.dart';
import '../../api/api_exception.dart';
import '../../api/competitions_api.dart';
import '../../api/session.dart';
import '../../theme/app_colors.dart';
import '../../widgets/site/page_hero.dart';
import '../../widgets/site/site_routes.dart';
import '../../widgets/site/site_scaffold.dart';
import '../../widgets/site/ui_kit.dart';
import '../coach/photo_badge.dart';

/// One competition's table, decided by its own rules. Public: `/competition?id=<id>`.
class CompetitionPage extends StatelessWidget {
  const CompetitionPage({super.key});

  static String routeFor(int id) => '${SiteRoutes.competition}?id=$id';

  @override
  Widget build(BuildContext context) {
    final id = int.tryParse(Uri.tryParse(ModalRoute.of(context)?.settings.name ?? '')?.queryParameters['id'] ?? '');
    return _CompetitionView(key: ValueKey(id), api: SessionScope.read(context).api, id: id);
  }
}

class _CompetitionView extends StatefulWidget {
  const _CompetitionView({super.key, required this.api, required this.id});

  final ApiClient api;
  final int? id;

  @override
  State<_CompetitionView> createState() => _CompetitionViewState();
}

class _CompetitionViewState extends State<_CompetitionView> {
  static const _notFound = 'We could not find that competition.';

  CompetitionTableData? _data;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    final id = widget.id;
    if (id == null) {
      setState(() => _error = _notFound);
      return;
    }
    try {
      final data = await CompetitionsApi(widget.api).table(id);
      if (mounted) setState(() => _data = data);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.status == 404 ? _notFound : e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    final name = data?.competition.name ?? 'Competition';
    return SiteScaffold(
      currentRoute: SiteRoutes.competition,
      children: [
        PageHero(
          title: name,
          breadcrumb: name,
          subtitle: [?data?.competition.sport, if (data?.competition.season != null) '${data!.competition.season} season'].join(' · '),
        ),
        ContentWidth(
          child: Padding(
            padding: const EdgeInsets.only(top: 28, bottom: 56),
            child: data != null
                ? _table(data)
                : _error == null
                    ? const Padding(padding: EdgeInsets.all(48), child: Center(child: CircularProgressIndicator()))
                    : SectionCard(
                        title: "Couldn't open this competition",
                        child: Column(children: [
                          EmptyState(_error!),
                          if (_error != _notFound) SiteButton(label: 'TRY AGAIN', small: true, onPressed: _load),
                          const SizedBox(height: 12),
                        ]),
                      ),
          ),
        ),
      ],
    );
  }

  Widget _table(CompetitionTableData data) {
    return SectionCard(
      title: 'Table',
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (data.rows.isEmpty)
            const EmptyState('No matches in this competition yet.')
          else
            SiteTable(
              minWidth: 640,
              columns: const [
                SiteTableColumn('#', width: 36),
                SiteTableColumn('Team', alignment: Alignment.centerLeft),
                SiteTableColumn('P', width: 38),
                SiteTableColumn('W', width: 38, hideOnNarrow: true),
                SiteTableColumn('D', width: 38, hideOnNarrow: true),
                SiteTableColumn('L', width: 38, hideOnNarrow: true),
                SiteTableColumn('F', width: 40, hideOnNarrow: true),
                SiteTableColumn('A', width: 40, hideOnNarrow: true),
                SiteTableColumn('+/-', width: 44),
                SiteTableColumn('Pts', width: 44),
              ],
              rows: [
                for (final r in data.rows)
                  [
                    Text('${r.position}', style: tableStrongStyle),
                    Row(
                      children: [
                        PhotoBadge(url: r.logoUrl, fallback: r.school, size: 26, square: true),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(r.school, style: tableStrongStyle, overflow: TextOverflow.ellipsis),
                              if (r.tiebreaker != null)
                                Text('Decided on ${(tiebreakerLabels[r.tiebreaker] ?? r.tiebreaker!).toLowerCase()}',
                                    style: const TextStyle(fontSize: 10, color: AppColors.orange)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    for (final v in [r.played, r.won, r.drawn, r.lost, r.scored, r.conceded]) Text('$v', style: tableCellStyle),
                    Text(r.difference > 0 ? '+${r.difference}' : '${r.difference}', style: tableCellStyle),
                    Text('${r.points}', style: tableStrongStyle),
                  ],
              ],
            ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Text(data.competition.rules.summary, style: const TextStyle(fontSize: 11, color: AppColors.muted, height: 1.4)),
          ),
        ],
      ),
    );
  }
}
