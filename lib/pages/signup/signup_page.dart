import 'package:flutter/material.dart';

import '../../api/api_exception.dart';
import '../../api/invitations_api.dart';
import '../../api/session.dart';
import '../../theme/app_colors.dart';
import '../../widgets/site/site_routes.dart';
import '../auth/auth_layout.dart';
import 'signup_form_data.dart';
import 'steps/account_setup_step.dart';
import 'steps/complete_step.dart';
import 'steps/personal_info_step.dart';
import 'steps/school_details_step.dart';
import 'steps/verify_step.dart';
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

  static const _accountStep = 2;
  static const _verifyStep = 3;
  static const _completeStep = 4;

  bool _submitting = false;
  bool _signedInByVerify = false;
  bool _verifiedCoach = false;
  bool _startedWithoutCode = false;
  bool _argsRead = false;
  String? _error;
  String _verifyEmail = '';
  InvitationInfo? _invite;
  bool _inviteInvalid = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argsRead) return;
    _argsRead = true;
    // Login sends people with an unverified email straight to the code step.
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map && args['verifyEmail'] is String) {
      _verifyEmail = args['verifyEmail'] as String;
      _step = _verifyStep;
      _startedWithoutCode = true;
    }
    final code = _inviteCodeFrom(args);
    if (code != null) _openInvitation(code);
  }

  /// A link like `/signup?invite=<code>`, or the code passed as an argument.
  String? _inviteCodeFrom(Object? args) {
    if (args is Map && args['invite'] is String) return args['invite'] as String;
    final name = ModalRoute.of(context)?.settings.name;
    final code = name == null ? null : Uri.tryParse(name)?.queryParameters['invite'];
    return code == null || code.isEmpty ? null : code;
  }

  /// Checks the code and, if it is good, starts the form as a coach with the invited email filled in.
  Future<void> _openInvitation(String code) async {
    final api = SessionScope.read(context).api;
    try {
      final info = await InvitationsApi(api).lookup(code);
      if (!mounted) return;
      setState(() {
        _invite = info;
        _data.inviteCode = code;
        _data.update(() {
          _data.accountType = AccountType.coach;
          if (info.email != null && _data.email.text.isEmpty) _data.email.text = info.email!;
        });
      });
    } on ApiException {
      // A dead link must not stop anyone registering.
      if (mounted) setState(() => _inviteInvalid = true);
    }
  }

  @override
  void dispose() {
    _data.dispose();
    super.dispose();
  }

  Future<void> _handleNext() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_step < _accountStep) {
      setState(() {
        _step++;
        _error = null;
      });
      return;
    }
    await _submit();
  }

  Future<void> _submit() async {
    final session = SessionScope.read(context);
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      if (_data.isCoach) {
        await session.registerCoach(_data.coachPayload());
      } else {
        await session.registerLearner(_data.learnerPayload());
      }
      if (!mounted) return;
      setState(() {
        _verifyEmail = _data.email.text.trim();
        _step = _verifyStep;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = _describe(e));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  /// The backend can reject fields from earlier steps, so name them all.
  String _describe(ApiException e) {
    if (e.code == 'EMAIL_TAKEN') return 'An account with this email already exists. Try logging in instead.';
    if (e.fieldErrors.isEmpty) return e.message;
    return e.fieldErrors.entries.map((f) => '${_fieldName(f.key)}: ${f.value}').join('\n');
  }

  static String _fieldName(String key) => switch (key) {
        'dateOfBirth' => 'Date of birth',
        'school' || 'school.name' => 'School',
        'school.grade' => 'Grade',
        'school.className' => 'Class',
        'sport' || 'sport.name' || 'team.sport' => 'Sport',
        'team.name' => 'Team name',
        'team.level' => 'Team level',
        'coachingRole' => 'Coaching role',
        'experience' => 'Experience',
        'firstName' => 'First name',
        'lastName' => 'Last name',
        _ => key[0].toUpperCase() + key.substring(1),
      };

  void _handleBack() => setState(() {
        _step--;
        _error = null;
      });

  void _handleVerified(AppUser? user) => setState(() {
        _signedInByVerify = user != null;
        _verifiedCoach = user?.isCoach ?? false;
        _step = _completeStep;
      });

  void _handleContinue() {
    if (_signedInByVerify) {
      final navigator = Navigator.of(context);
      navigator.pushNamedAndRemoveUntil(SiteRoutes.home, (route) => false);
      if (_verifiedCoach) navigator.pushNamed(SiteRoutes.coach);
    } else {
      _goToLogin();
    }
  }

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
            if (_invite != null) _InviteBanner("${_invite!.from} invited you to join Sportstures. Register as a coach to get started."),
            if (_inviteInvalid) const _InviteBanner('This invitation link is not valid any more, but you can still register below.', muted: true),
            SignupStepper(currentStep: _step),
            const SizedBox(height: 32),
            _buildStepContent(),
            if (_step <= _accountStep) ...[
              if (_error != null) _ErrorBanner(_error!),
              const SizedBox(height: 28),
              _buildActions(),
            ],
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
      2 => AccountSetupStep(data: _data),
      _verifyStep => VerifyStep(
          session: SessionScope.read(context),
          email: _verifyEmail,
          onVerified: _handleVerified,
          initialCooldown: _startedWithoutCode ? 0 : 60,
        ),
      _ => CompleteStep(signedIn: _signedInByVerify, onContinue: _handleContinue),
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
              onPressed: _submitting ? null : _handleNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: const StadiumBorder(),
              ),
              child: _submitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_step == _accountStep ? 'Create account' : 'Next Step', style: const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward, size: 16),
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

class _InviteBanner extends StatelessWidget {
  const _InviteBanner(this.message, {this.muted = false});

  final String message;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final color = muted ? AppColors.muted : AppColors.green;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(muted ? Icons.info_outline : Icons.mark_email_read_outlined, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: TextStyle(color: AppColors.ink, fontSize: 13, height: 1.4, fontWeight: muted ? FontWeight.w400 : FontWeight.w600))),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border.all(color: Colors.red.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(message, style: TextStyle(color: Colors.red.shade800, fontSize: 12, height: 1.4)),
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
