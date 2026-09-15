import 'package:flutter/material.dart';

import '../signup_form_data.dart';
import '../widgets/form_fields.dart';

class AccountSetupStep extends StatelessWidget {
  const AccountSetupStep({super.key, required this.data});

  final SignupFormData data;

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
            label: 'Username',
            hint: 'e.g. coach_jim',
            controller: data.username,
            autofillHints: const [AutofillHints.newUsername],
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Required';
              return v.contains(' ') ? 'Username cannot contain spaces' : null;
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
              return v.length < 8 ? 'Password must be at least 8 characters' : null;
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
