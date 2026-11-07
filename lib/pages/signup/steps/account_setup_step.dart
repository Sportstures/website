import 'package:flutter/material.dart';

import '../signup_form_data.dart';
import '../widgets/form_fields.dart';

class AccountSetupStep extends StatelessWidget {
  const AccountSetupStep({super.key, required this.data});

  final SignupFormData data;

  /// Mirrors the backend: 8 to 72 characters with at least one letter and one number.
  static String? passwordProblem(String v) {
    if (v.length < 8) return 'Password must be at least 8 characters';
    if (v.length > 72) return 'Password must be 72 characters or fewer';
    if (!RegExp(r'[A-Za-z]').hasMatch(v) || !RegExp(r'd').hasMatch(v)) {
      return 'Use at least one letter and one number';
    }
    return null;
  }

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  Widget build(BuildContext context) {
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StepHeader(
            title: 'Account setup',
            subtitle:
                'Set up your secure login credentials to access fixtures, manage stats, and connect.',
          ),
          SignupTextField(
            label: 'Email Address',
            hint: 'e.g. coach.jim@greenwood.com',
            controller: data.email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Required';
              return _emailPattern.hasMatch(v.trim()) ? null : 'Enter a valid email address';
            },
          ),
          const SizedBox(height: 18),
          SignupTextField(
            label: 'Password',
            controller: data.password,
            isPassword: true,
            autofillHints: const [AutofillHints.newPassword],
            validator: (v) {
              if (v == null || v.isEmpty) return 'Required';
              return passwordProblem(v);
            },
          ),
          const SizedBox(height: 18),
          SignupTextField(
            label: 'Confirm Password',
            controller: data.confirmPassword,
            isPassword: true,
            autofillHints: const [AutofillHints.newPassword],
            validator: (v) {
              if (v == null || v.isEmpty) return 'Required';
              return v == data.password.text ? null : 'Passwords do not match';
            },
          ),
        ],
      ),
    );
  }
}
