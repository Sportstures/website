import 'dart:math';

import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../config/site_links.dart';
import '../../theme/app_colors.dart';
import 'photo_background.dart';
import 'site_routes.dart';
import 'site_scaffold.dart';
import 'ui_kit.dart';

class SiteFooter extends StatelessWidget {
  const SiteFooter({super.key});

  static final _linkColumns = [
    ('Quick Links', ['Home', 'Fixtures', 'Results', 'Standings', 'Rankings', 'For Schools', 'About']),
    // Taken from the sports the platform actually runs, so a link here can
    // never name a sport that has no page behind it.
    ('Sports', [...Sport.values.take(6).map((sport) => sport.label), 'More Sports']),
    (
      'For Schools',
      [
        'Register Your School',
        'Manage Teams',
        'Create a Match',
        'Post Results',
        'Manage Fixtures',
        'View Match History',
      ],
    ),
    (
      'Support',
      [
        'Help Centre',
        'Contact Us',
        'Report a Problem',
        'Safety & Guidelines',
        'Terms & Conditions',
        'Privacy Policy',
        'FAQs',
      ],
    ),
  ];

  static const _linkRoutes = {
    'Home': SiteRoutes.home,
    'Fixtures': SiteRoutes.fixtures,
    'Results': SiteRoutes.results,
    'Standings': SiteRoutes.standings,
    'Rankings': SiteRoutes.rankings,
    'For Schools': SiteRoutes.schools,
    'About': SiteRoutes.about,
    'More Sports': SiteRoutes.sports,
    'Register Your School': SiteRoutes.signup,
    // The five management links are parts of one set of tools rather than five
    // destinations, so they share a page.
    'Manage Teams': SiteRoutes.forSchools,
    'Create a Match': SiteRoutes.forSchools,
    'Post Results': SiteRoutes.forSchools,
    'Manage Fixtures': SiteRoutes.forSchools,
    'View Match History': SiteRoutes.forSchools,
    'Help Centre': SiteRoutes.help,
    'FAQs': SiteRoutes.help,
    'Contact Us': SiteRoutes.contact,
    'Report a Problem': SiteRoutes.contact,
    'Safety & Guidelines': SiteRoutes.safety,
    'Terms & Conditions': SiteRoutes.terms,
    'Privacy Policy': SiteRoutes.privacy,
  };

  /// A sport's name goes to the sport hub, carrying which sport to show.
  static final _sportsByLabel = {
    for (final sport in Sport.values) sport.label: sport,
  };

  /// Where a footer link lands, and what it takes with it.
  static (String?, Object?) _target(String label) {
    final sport = _sportsByLabel[label];
    if (sport != null) return (SiteRoutes.sport, sport);
    return (_linkRoutes[label], null);
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.greenDark,
      child: ContentWidth(
        child: Padding(
          padding: const EdgeInsets.only(top: 56, bottom: 24),
          child: Column(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final linkColumns = [
                    for (final (title, links) in _linkColumns)
                      _LinkColumn(title: title, links: links, target: _target),
                  ];

                  if (constraints.maxWidth >= 1000) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Expanded(flex: 3, child: _Brand()),
                        const SizedBox(width: 32),
                        for (final column in linkColumns) Expanded(flex: 2, child: column),
                        const SizedBox(width: 16),
                        const Expanded(flex: 3, child: _Newsletter()),
                      ],
                    );
                  }

                  final wideBlock = min(constraints.maxWidth, 340.0);
                  return Wrap(
                    spacing: 32,
                    runSpacing: 32,
                    children: [
                      SizedBox(width: wideBlock, child: const _Brand()),
                      for (final column in linkColumns) SizedBox(width: 150, child: column),
                      SizedBox(width: wideBlock, child: const _Newsletter()),
                    ],
                  );
                },
              ),
              const SizedBox(height: 40),
              Divider(height: 1, color: Colors.white.withValues(alpha: 0.12)),
              const SizedBox(height: 16),
              Text(
                '© ${DateTime.now().year} Sportstures. All rights reserved.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  /// Each icon with the profile behind it. An icon whose profile is not set
  /// yet is left out, rather than shown as something that cannot be clicked.
  static const _socials = [
    (Icons.facebook, SiteLinks.facebook, 'Facebook'),
    (Icons.camera_alt_outlined, SiteLinks.instagram, 'Instagram'),
    (Icons.alternate_email, SiteLinks.x, 'X'),
    (Icons.smart_display_outlined, SiteLinks.youtube, 'YouTube'),
  ];

  @override
  Widget build(BuildContext context) {
    final bodyStyle = TextStyle(
      color: Colors.white.withValues(alpha: 0.7),
      fontSize: 12,
      height: 1.6,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.asset(
          SiteImages.logo,
          height: 72,
          errorBuilder: (_, _, _) => const SizedBox(height: 72),
        ),
        const SizedBox(height: 16),
        Text(
          'A platform designed to connect schools through sport. Find fixtures, '
          'results and standings for school sports across South Africa.',
          style: bodyStyle,
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            const Icon(Icons.location_on_outlined, size: 14, color: AppColors.orange),
            const SizedBox(width: 6),
            // TODO: replace with the real office address from the design
            Flexible(child: Text('Johannesburg, South Africa', style: bodyStyle)),
          ],
        ),
        if (_socials.any((social) => SiteLinks.has(social.$2))) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              for (final (icon, url, name) in _socials)
                if (SiteLinks.has(url))
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Tooltip(
                      message: name,
                      child: InkWell(
                        onTap: () => openExternal(context, Uri.parse(url!)),
                        customBorder: const CircleBorder(),
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: const BoxDecoration(
                            color: AppColors.orange,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, size: 15, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
            ],
          ),
        ],
      ],
    );
  }
}

class _LinkColumn extends StatelessWidget {
  const _LinkColumn({required this.title, required this.links, required this.target});

  final String title;
  final List<String> links;
  final (String?, Object?) Function(String label) target;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 14),
        for (final link in links)
          Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: InkWell(
              onTap: () {
                final (route, arguments) = target(link);
                openSiteRoute(context, route, arguments: arguments);
              },
              child: Text(
                link,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
              ),
            ),
          ),
      ],
    );
  }
}

class _Newsletter extends StatefulWidget {
  const _Newsletter();

  @override
  State<_Newsletter> createState() => _NewsletterState();
}

class _NewsletterState extends State<_Newsletter> {
  final _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _subscribe() {
    final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(_email.text.trim());
    // TODO: send the address to the Node/JS backend newsletter endpoint
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(valid ? 'Thanks for subscribing!' : 'Enter a valid email address'),
      ));
    if (valid) _email.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Stay Updated',
          style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 14),
        Text(
          'Subscribe to our newsletter to get the latest fixtures, results and news.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12, height: 1.6),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 40,
                child: TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  onSubmitted: (_) => _subscribe(),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'Your email address',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.08),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 40,
              child: SiteButton(
                label: 'Subscribe',
                variant: SiteButtonVariant.orange,
                small: true,
                onPressed: _subscribe,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
