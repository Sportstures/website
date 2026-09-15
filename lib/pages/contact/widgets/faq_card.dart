import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import 'contact_card.dart';

// TODO: confirm FAQ answers (especially pricing) before launch
const _faqs = [
  (
    'How do I register my school on Sportstures?',
    'Click "Register School" at the top of any page and follow the steps. You\'ll add your '
        'personal details, your school\'s information and your login credentials.',
  ),
  (
    'Is there a cost to use the platform?',
    'Send us a message using the form above and our team will talk you through the options '
        'for your school.',
  ),
  (
    'How do I update fixtures or results?',
    'School administrators and coaches can add fixtures and post results once they have '
        'logged in to their school account.',
  ),
  (
    'Can parents and fans use Sportstures?',
    'Yes. Anyone can browse fixtures, results, standings and rankings without an account.',
  ),
  (
    'Who can I contact for technical support?',
    'Email support@sportstures.co.za or choose "Technical Support" in the form above.',
  ),
];

class FaqCard extends StatelessWidget {
  const FaqCard({super.key});

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(6));

    return ContactCard(
      title: 'Frequently asked questions',
      child: Column(
        children: [
          for (final (question, answer) in _faqs)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ExpansionTile(
                title: Text(
                  question,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink),
                ),
                dense: true,
                shape: shape,
                collapsedShape: shape,
                backgroundColor: AppColors.surface,
                collapsedBackgroundColor: AppColors.surface,
                iconColor: AppColors.green,
                collapsedIconColor: AppColors.muted,
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                expandedAlignment: Alignment.centerLeft,
                children: [
                  Text(answer, style: const TextStyle(fontSize: 12, color: AppColors.muted, height: 1.5)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
