import 'package:flutter/material.dart';

import '../../api/api_exception.dart';
import '../../api/session.dart';
import '../../theme/app_colors.dart';
import '../../widgets/site/site_routes.dart';
import '../../widgets/site/ui_kit.dart';
import '../signup/steps/account_setup_step.dart';
import 'auth_layout.dart';

/// Password reset: ask for a code by email, then set a new password with it. Reached from "Forgot Password?" on the login page.
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

enum _Step { email, code, done }

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailForm = GlobalKey<FormState>();
  final _codeForm = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  _Step _step = _Step.email;
  bool _busy = false;
  String? _error;
  String? _notice;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function(Session session) action) async {
    if (_busy) return;
    final session = SessionScope.read(context);
    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });
    try {
      await action(session);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = switch (e.code) {
            'INVALID_OTP' => 'That code is wrong or has expired. Check it, or ask for a new one.',
            'TOO_MANY_REQUESTS' => 'Too many tries. Wait a minute, then ask for a new code.',
            _ => e.fieldErrors.isNotEmpty ? e.fieldErrors.values.first : e.message,
          });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _sendCode() {
    if (!(_emailForm.currentState?.validate() ?? false)) return;
    _run((session) async {
      await session.forgotPassword(_email.text);
      if (mounted) setState(() => _step = _Step.code);
    });
  }

  void _resend() => _run((session) async {
        await session.forgotPassword(_email.text);
        if (mounted) setState(() => _notice = 'We sent a new code, if the account exists.');
      });

  void _reset() {
    if (!(_codeForm.currentState?.validate() ?? false)) return;
    _run((session) async {
      await session.resetPassword(_email.text, _code.text, _password.text);
      if (mounted) setState(() => _step = _Step.done);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      panel: const AuthBrandPanel(child: _ResetPanelContent()),
      form: switch (_step) {
        _Step.email => _buildEmail(),
        _Step.code => _buildCode(),
        _Step.done => _buildDone(),
      },
    );
  }

  static const _title = TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.ink);
  static const _text = TextStyle(fontSize: 13, color: AppColors.muted, height: 1.6);

  Widget _field(
    String label,
    TextEditingController controller, {
    required String? Function(String?) validator,
    String? hint,
    bool secret = false,
    TextInputType? keyboard,
    Iterable<String>? autofill,
    VoidCallback? onSubmit,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.ink)),
          const SizedBox(height: 7),
          TextFormField(
            key: ValueKey(label),
            controller: controller,
            obscureText: secret,
            keyboardType: keyboard,
            autofillHints: autofill,
            onFieldSubmitted: onSubmit == null ? null : (_) => onSubmit(),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(fontSize: 13, color: AppColors.muted),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              border: const OutlineInputBorder(borderSide: BorderSide(color: AppColors.border)),
              enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppColors.border)),
            ),
            validator: validator,
          ),
        ],
      ),
    );
  }

  List<Widget> get _messages => [
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(_error!, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.red.shade700, height: 1.5)),
          ),
        if (_notice != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(_notice!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.green)),
          ),
      ];

  Widget _buildEmail() {
    return Form(
      key: _emailForm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Reset your password', style: _title),
          const SizedBox(height: 8),
          const Text('Enter the email address on your account and we will send you a 6-digit code.', style: _text),
          const SizedBox(height: 28),
          _field(
            'Email address',
            _email,
            hint: 'you@school.co.za',
            keyboard: TextInputType.emailAddress,
            autofill: const [AutofillHints.email],
            onSubmit: _sendCode,
            validator: (value) {
              final text = value?.trim() ?? '';
              if (text.isEmpty) return 'Required';
              if (!text.contains('@') || !text.contains('.')) return 'Enter a valid email address';
              return null;
            },
          ),
          const SizedBox(height: 10),
          ..._messages,
          SiteButton(label: _busy ? 'SENDING…' : 'SEND CODE', expand: true, onPressed: _busy ? null : _sendCode),
          const SizedBox(height: 20),
          Center(child: _BackToLogin()),
        ],
      ),
    );
  }

  Widget _buildCode() {
    return Form(
      key: _codeForm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Enter your code', style: _title),
          const SizedBox(height: 8),
          Text(
            'If an account exists for ${_email.text.trim()}, a 6-digit code is on its way. It expires in 10 minutes.',
            style: _text,
          ),
          const SizedBox(height: 24),
          _field(
            '6-digit code',
            _code,
            keyboard: TextInputType.number,
            autofill: const [AutofillHints.oneTimeCode],
            validator: (v) => RegExp(r'^[0-9]{6}$').hasMatch((v ?? '').trim()) ? null : 'Enter the 6 digits from the email',
          ),
          _field(
            'New password',
            _password,
            secret: true,
            autofill: const [AutofillHints.newPassword],
            validator: (v) => AccountSetupStep.passwordProblem(v ?? ''),
          ),
          _field(
            'Repeat new password',
            _confirm,
            secret: true,
            onSubmit: _reset,
            validator: (v) => v == _password.text ? null : 'The passwords do not match',
          ),
          const SizedBox(height: 10),
          ..._messages,
          SiteButton(label: _busy ? 'ONE MOMENT…' : 'SET NEW PASSWORD', expand: true, onPressed: _busy ? null : _reset),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            children: [
              TextButton(onPressed: _busy ? null : _resend, child: const Text('Send a new code')),
              TextButton(
                onPressed: () => setState(() {
                  _step = _Step.email;
                  _code.clear();
                  _error = null;
                  _notice = null;
                }),
                child: const Text('Use a different address'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDone() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 52,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: AppColors.green.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: const Icon(Icons.check, size: 26, color: AppColors.green),
        ),
        const SizedBox(height: 20),
        const Text('Password changed', style: _title),
        const SizedBox(height: 8),
        const Text('You have been signed out everywhere. Log in with your new password.', style: _text),
        const SizedBox(height: 26),
        SiteButton(label: 'BACK TO LOGIN', expand: true, onPressed: () => openSiteRoute(context, SiteRoutes.login)),
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
          'Reset codes last 10 minutes',
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
