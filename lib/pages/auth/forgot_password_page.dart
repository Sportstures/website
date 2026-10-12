import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../widgets/site/site_routes.dart';
import '../../widgets/site/ui_kit.dart';
import 'auth_layout.dart';

/// Password reset request. Reached from "Forgot Password?" on the login page.
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      // TODO: POST to the Node/JS backend's password reset endpoint. Until that
      // exists this only confirms locally, and no email is sent.
      setState(() => _sent = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      panel: const AuthBrandPanel(child: _ResetPanelContent()),
      form: _sent ? _buildSent() : _buildForm(),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Reset your password',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.ink),
          ),
          const SizedBox(height: 8),
          const Text(
            'Enter the email address your school account uses and we will send you a link to set '
            'a new password.',
            style: TextStyle(fontSize: 13, color: AppColors.muted, height: 1.6),
          ),
          const SizedBox(height: 28),
          const Text(
            'Email address',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.ink),
          ),
          const SizedBox(height: 7),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(
              hintText: 'you@school.co.za',
              hintStyle: TextStyle(fontSize: 13, color: AppColors.muted),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              border: OutlineInputBorder(borderSide: BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.border)),
            ),
            validator: (value) {
              final text = value?.trim() ?? '';
              if (text.isEmpty) return 'Required';
              if (!text.contains('@') || !text.contains('.')) return 'Enter a valid email address';
              return null;
            },
          ),
          const SizedBox(height: 24),
          SiteButton(label: 'SEND RESET LINK', expand: true, onPressed: _submit),
          const SizedBox(height: 20),
          Center(
            child: _BackToLogin(),
          ),
        ],
      ),
    );
  }

  Widget _buildSent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 52,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.green.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.mark_email_read_outlined, size: 26, color: AppColors.green),
        ),
        const SizedBox(height: 20),
        const Text(
          'Check your inbox',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.ink),
        ),
        const SizedBox(height: 8),
        Text(
          'If an account exists for ${_emailController.text.trim()}, a reset link is on its way. '
          'The link expires in an hour.',
          style: const TextStyle(fontSize: 13, color: AppColors.muted, height: 1.6),
        ),
        const SizedBox(height: 10),
        const Text(
          'We do not say whether an address is registered, so that nobody can use this page to '
          'find out which schools have accounts.',
          style: TextStyle(fontSize: 11.5, color: AppColors.muted, height: 1.6),
        ),
        const SizedBox(height: 26),
        SiteButton(
          label: 'BACK TO LOGIN',
          expand: true,
          onPressed: () => openSiteRoute(context, SiteRoutes.login),
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: () => setState(() => _sent = false),
            child: const Text(
              'Use a different address',
              style: TextStyle(fontSize: 12, color: AppColors.green, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}

class _BackToLogin extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Remembered it? ',
          style: TextStyle(fontSize: 12, color: AppColors.muted),
        ),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => openSiteRoute(context, SiteRoutes.login),
            child: const Text(
              'Back to login',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.green,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ResetPanelContent extends StatelessWidget {
  const _ResetPanelContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Locked out?',
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'It happens. Give us the email on your school account and you will be back in the '
          'fixtures in a minute.',
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.8),
            height: 1.7,
          ),
        ),
        const SizedBox(height: 28),
        for (final line in const [
          'Reset links last one hour',
          'Only the account holder can reset',
          'Your fixtures stay exactly as they were',
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                const Icon(Icons.check_circle, size: 15, color: AppColors.greenBright),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    line,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
