import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../widgets/site/site_routes.dart';
import 'contact_card.dart';

// TODO: confirm these contact details before launch
const _channels = [
  (Icons.phone, 'Phone', ['+27 11 123 4567', 'Mon – Fri, 08:00 – 16:30']),
  (Icons.mail_outline, 'Email', ['info@sportstures.co.za', 'We aim to reply within 24 hours']),
  (Icons.location_on_outlined, 'Location', ['Bryanston, Johannesburg', 'Gauteng, South Africa']),
  (Icons.support_agent, 'Support', ['support@sportstures.co.za', 'For technical support & platform help']),
];

class ContactInfoCard extends StatelessWidget {
  const ContactInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ContactCard(
      title: 'Get in touch',
      subtitle: 'Have a question or need assistance? Reach out to us using any of the channels below.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (icon, label, lines) in _channels)
            Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: const BoxDecoration(color: AppColors.ink, shape: BoxShape.circle),
                    child: Icon(icon, size: 17, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label.toUpperCase(),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.ink),
                        ),
                        const SizedBox(height: 2),
                        SelectableText(
                          lines.first,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink),
                        ),
                        Text(lines.last, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 4),
          Row(
            children: [
              for (final icon in [Icons.facebook, Icons.close, Icons.camera_alt_outlined, Icons.smart_display])
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: InkWell(
                    // TODO: link to the real social media profiles
                    onTap: () => openSiteRoute(context, null),
                    customBorder: const CircleBorder(),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(color: AppColors.ink, shape: BoxShape.circle),
                      child: Icon(icon, size: 17, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
