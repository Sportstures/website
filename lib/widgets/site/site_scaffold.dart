import 'package:flutter/material.dart';

import 'ai_assistant.dart';
import 'site_footer.dart';
import 'site_header.dart';

/// Page frame shared by the public site: nav bar, scrolling content, footer.
class SiteScaffold extends StatelessWidget {
  const SiteScaffold({super.key, required this.currentRoute, required this.children});

  final String currentRoute;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      endDrawer: SiteDrawer(currentRoute: currentRoute),
      body: Stack(
        children: [
          Column(
            children: [
              SiteHeader(currentRoute: currentRoute),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [...children, const SiteFooter()],
                  ),
                ),
              ),
            ],
          ),
          // Sits above the page on every route, so a question can be asked
          // from wherever the visitor happens to be.
          const Positioned(
            right: 0,
            bottom: 0,
            child: AiAssistantLauncher(),
          ),
        ],
      ),
    );
  }
}

/// Centres [child] and caps it at the site's content width.
class ContentWidth extends StatelessWidget {
  const ContentWidth({super.key, required this.child});

  static const maxWidth = 1200.0;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final gutter = MediaQuery.sizeOf(context).width < 600 ? 16.0 : 24.0;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: maxWidth),
        // Always fill the capped width so left-aligned content lines up with the nav bar.
        child: SizedBox(
          width: double.infinity,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: gutter),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Main content beside a sidebar on wide screens, stacked on narrow ones.
class TwoColumnLayout extends StatelessWidget {
  const TwoColumnLayout({super.key, required this.main, required this.sidebar});

  final Widget main;
  final Widget sidebar;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 960) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: main),
              const SizedBox(width: 20),
              SizedBox(width: 340, child: sidebar),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [main, const SizedBox(height: 20), sidebar],
        );
      },
    );
  }
}
