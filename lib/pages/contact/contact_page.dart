import 'package:flutter/material.dart';

import '../../widgets/site/page_hero.dart';
import '../../widgets/site/photo_background.dart';
import '../../widgets/site/site_routes.dart';
import '../../widgets/site/site_scaffold.dart';
import 'widgets/contact_form_card.dart';
import 'widgets/contact_info_card.dart';
import 'widgets/faq_card.dart';
import 'widgets/find_us_card.dart';
import 'widgets/partner_banner.dart';

class ContactPage extends StatefulWidget {
  const ContactPage({super.key});

  @override
  State<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  final _formKey = GlobalKey<ContactFormCardState>();

  /// "Learn more" on the partner banner jumps to the form, ready for a partnership enquiry.
  void _startPartnershipEnquiry() {
    _formKey.currentState?.selectEnquiry(EnquiryType.partnerships);
    final formContext = _formKey.currentContext;
    if (formContext != null) {
      Scrollable.ensureVisible(formContext, duration: const Duration(milliseconds: 400), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SiteScaffold(
      currentRoute: SiteRoutes.contact,
      children: [
        PageHero(
          title: 'Contact us',
          subtitle: "We're here to help! Whether you have a question, need support, or want to "
              'partner with us, our team would love to hear from you.',
          trailing: Image.asset(
            SiteImages.logo,
            height: 150,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
        ),
        ContentWidth(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ResponsivePair(
                  breakpoint: 860,
                  leftFlex: 2,
                  rightFlex: 3,
                  left: const ContactInfoCard(),
                  right: ContactFormCard(key: _formKey),
                ),
                const SizedBox(height: 24),
                const _ResponsivePair(
                  breakpoint: 760,
                  left: FindUsCard(),
                  right: FaqCard(),
                ),
                const SizedBox(height: 32),
                PartnerBanner(onLearnMore: _startPartnershipEnquiry),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Two cards side by side at equal height, stacked below [breakpoint].
class _ResponsivePair extends StatelessWidget {
  const _ResponsivePair({
    required this.breakpoint,
    required this.left,
    required this.right,
    this.leftFlex = 1,
    this.rightFlex = 1,
  });

  final double breakpoint;
  final Widget left;
  final Widget right;
  final int leftFlex;
  final int rightFlex;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= breakpoint) {
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: leftFlex, child: left),
                const SizedBox(width: 20),
                Expanded(flex: rightFlex, child: right),
              ],
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [left, const SizedBox(height: 20), right],
        );
      },
    );
  }
}
