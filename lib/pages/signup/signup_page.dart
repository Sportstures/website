import 'package:flutter/material.dart';

import '../../widgets/site/site_routes.dart';
import 'signup_form_data.dart';
import 'signup_theme.dart';
import 'steps/account_setup_step.dart';
import 'steps/personal_info_step.dart';
import 'steps/school_details_step.dart';
import 'widgets/signup_brand_panel.dart';
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
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 1040, maxHeight: 680),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 760;
              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Expanded(flex: 4, child: SignupBrandPanel()),
                    Expanded(flex: 6, child: _buildFormPanel(horizontalPadding: 48)),
                  ],
                );
              }
              // On narrow screens, just show the form
              return _buildFormPanel(horizontalPadding: 24);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFormPanel({required double horizontalPadding}) {
    return ColoredBox(
      color: SignupColors.panel,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(horizontalPadding, 28, horizontalPadding, 0),
            child: SignupStepper(currentStep: _step),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 28),
                child: ConstrainedBox(
                  // Vertically centre short steps; longer ones scroll.
                  constraints: BoxConstraints(minHeight: constraints.maxHeight - 56),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                ),
              ),
            ),
          ),
        ],
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
              foregroundColor: SignupColors.text,
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
                backgroundColor: SignupColors.orange,
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
            style: TextStyle(color: SignupColors.muted, fontSize: 12),
          ),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: _goToLogin,
              child: const Text(
                'Login',
                style: TextStyle(
                  color: SignupColors.orange,
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

class _TermsNotice extends StatelessWidget {
  const _TermsNotice();

  @override
  Widget build(BuildContext context) {
    const linkStyle = TextStyle(
      color: SignupColors.text,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.underline,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: SignupColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      // TODO: link to the Terms & Conditions and Privacy Policy pages
      child: const Text.rich(
        TextSpan(
          style: TextStyle(color: SignupColors.muted, fontSize: 11),
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
