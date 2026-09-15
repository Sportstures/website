import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

/// Bordered white card with an uppercase heading, shared by the contact page panels.
class ContactCard extends StatelessWidget {
  const ContactCard({super.key, required this.title, required this.child, this.subtitle});

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.green),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(subtitle!, style: const TextStyle(fontSize: 12, color: AppColors.muted, height: 1.5)),
          ],
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}
