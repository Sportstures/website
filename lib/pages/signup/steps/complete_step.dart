import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../widgets/form_fields.dart';

/// Step 5. Coaches are signed in by verifying; learners must log in.
class CompleteStep extends StatelessWidget {
  const CompleteStep({super.key, required this.signedIn, required this.onContinue});

  /// True when verifying also signed the person in (coaches).
  final bool signedIn;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check_circle, color: AppColors.green, size: 44),
        const SizedBox(height: 16),
        StepHeader(
          title: "You're all set",
          subtitle: signedIn
              ? 'Your email is verified and you are signed in.'
              : 'Your email is verified. Log in with your email and password to continue.',
        ),
        SizedBox(
          width: double.infinity,
          height: 46,
          child: ElevatedButton(
            onPressed: onContinue,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.orange,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: const StadiumBorder(),
            ),
            child: Text(signedIn ? 'Go to the site' : 'Log in', style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
}
