import 'package:flutter/material.dart';

import '../signup_theme.dart';

class SignupBrandPanel extends StatelessWidget {
  const SignupBrandPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      // TODO: add the faint players photo from the design once there is a clean
      // export. stadium_bg.png has the login panel's text baked into it.
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [SignupColors.green, SignupColors.greenDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(32, 28, 32, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(
                'assets/images/logo.png',
                height: 36,
                errorBuilder: (_, _, _) => const SizedBox(height: 36),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sportstures',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // TODO: confirm tagline wording against the Figma file
                  Text(
                    'HOME OF SCHOOL SPORTS',
                    style: TextStyle(
                      color: SignupColors.orange,
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          const Text(
            "Empowering your\nschool's athletic journey.",
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            "Join your school's sporting community to connect, compete, and track every match result live.",
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Text(
                'Active Leagues',
                style: TextStyle(
                  color: SignupColors.orange,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                width: 1,
                height: 12,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                color: Colors.white.withValues(alpha: 0.4),
              ),
              const Text(
                '150+ Schools',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            '© ${DateTime.now().year} Sportstures. All rights reserved.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 10),
          ),
        ],
      ),
    );
  }
}
