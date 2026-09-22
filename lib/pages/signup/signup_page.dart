import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../widgets/site/site_routes.dart';
import '../auth/auth_layout.dart';
import 'signup_form_data.dart';
import 'steps/account_setup_step.dart';
import 'steps/personal_info_step.dart';
import 'steps/school_details_step.dart';
import 'widgets/signup_stepper.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _data = SignupFormData();
  int _step = 0;

  /// Index of the last step with a screen. Verify and Complete are shown in
  /// the stepper but have not been designed yet.
  static const _lastBuiltStep = 2;

  @override
  void dispose() {
    _data.dispose();
    super.dispose();
  }

  void _handleNext() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_step < _lastBuiltStep) {
      setState(() => _step++);
      return;
    }
    // TODO: submit _data to the Node/JS backend, then continue to the Verify step
  }

  void _handleBack() => setState(() => _step--);

  /// Sign-up can be reached from the landing page or from login, so rebuild
  /// the stack as home → login rather than just popping.
  void _goToLogin() {
    Navigator.of(context).pushNamedAndRemoveUntil(SiteRoutes.login, (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      formMaxWidth: 560,
      panel: const AuthBrandPanel(child: _SignupPanelContent()),
      form: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SignupStepper(currentStep: _step),
            const SizedBox(height: 32),
            _buildStepContent(),
            const SizedBox(height: 28),
            _buildActions(),
            const SizedBox(height: 16),
            _buildLoginLink(),
            const SizedBox(height: 24),
            const _TermsNotice(),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    return switch (_step) {
      0 => PersonalInfoStep(data: _data),
      1 => SchoolDetailsStep(data: _data),
      _ => AccountSetupStep(data: _data),
    };
  }

  Widget _buildActions() {
    return Row(
      children: [
        if (_step > 0) ...[
          TextButton(
            onPressed: _handleBack,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.ink,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
            child: const Text('Back', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: SizedBox(
            height: 46,
            child: ElevatedButton(
              onPressed: _handleNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: const StadiumBorder(),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Next Step', style: TextStyle(fontWeight: FontWeight.w600)),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 16),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginLink() {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Already have an account? ',
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: _goToLogin,
              child: const Text(
                'Login',
                style: TextStyle(
                  color: AppColors.orange,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignupPanelContent extends StatelessWidget {
  const _SignupPanelContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Empowering your\nschool's athletic journey.",
          style: TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.w900,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          "Join your school's sporting community to connect, compete, and track every "
          'match result live.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 13,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 26),
        Row(
          children: [
            const Text(
              'Active Leagues',
              style: TextStyle(
                color: AppColors.orange,
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
              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ],
    );
  }
}

class _TermsNotice extends StatelessWidget {
  const _TermsNotice();

  @override
  Widget build(BuildContext context) {
    const linkStyle = TextStyle(
      color: AppColors.ink,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.underline,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      // TODO: link to the Terms & Conditions and Privacy Policy pages
      child: const Text.rich(
        TextSpan(
          style: TextStyle(color: AppColors.muted, fontSize: 11),
          children: [
            TextSpan(text: 'By continuing, you agree to our '),
            TextSpan(text: 'Terms & Conditions', style: linkStyle),
            TextSpan(text: ' and acknowledge our '),
            TextSpan(text: 'Privacy Policy', style: linkStyle),
            TextSpan(text: '.'),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
