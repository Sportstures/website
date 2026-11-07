import 'package:flutter/material.dart';

import '../../data/match_store.dart';
import '../../data/sports_data.dart';
import 'page_hero.dart';
import 'site_scaffold.dart';
import 'ui_kit.dart';

/// Gives a match page its data. With a [MatchScope] above it the data comes from the
/// backend, with a loading state and a retry on failure; without one (a page built on
/// its own) it uses the sample data.
///
/// [builder] runs only once data exists, so pages never have to handle "not loaded yet".
class MatchDataBuilder extends StatefulWidget {
  const MatchDataBuilder({
    super.key,
    required this.currentRoute,
    required this.title,
    required this.subtitle,
    required this.builder,
  });

  final String currentRoute;
  final String title;
  final String subtitle;
  final Widget Function(BuildContext context, SportsData data) builder;

  @override
  State<MatchDataBuilder> createState() => _MatchDataBuilderState();
}

class _MatchDataBuilderState extends State<MatchDataBuilder> {
  MatchStore? _requested;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final store = MatchScope.maybeOf(context);
    if (store != null && !identical(store, _requested)) {
      _requested = store;
      // Not during build: loading notifies listeners.
      WidgetsBinding.instance.addPostFrameCallback((_) => store.ensureLoaded());
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = MatchScope.maybeOf(context);
    if (store == null) return widget.builder(context, SportsData.instance);

    final data = store.data;
    if (data != null) return widget.builder(context, data);

    return SiteScaffold(
      currentRoute: widget.currentRoute,
      children: [
        PageHero(title: widget.title, breadcrumb: widget.title, subtitle: widget.subtitle),
        ContentWidth(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 56),
            child: store.state == MatchLoad.failed
                ? SectionCard(
                    title: "Couldn't load ${widget.title.toLowerCase()}",
                    child: Column(
                      children: [
                        EmptyState(store.error ?? 'Something went wrong. Please try again.'),
                        const SizedBox(height: 12),
                        SiteButton(label: 'TRY AGAIN', small: true, onPressed: store.reload),
                      ],
                    ),
                  )
                : const Center(child: CircularProgressIndicator()),
          ),
        ),
      ],
    );
  }
}
