import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/site/site_routes.dart';
import 'auth/auth_layout.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleSignIn() {
    if (_formKey.currentState?.validate() ?? false) {
      // TODO: wire up to Node/JS backend auth endpoint
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      panel: const AuthBrandPanel(child: _LoginPanelContent()),
      form: _buildForm(),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Welcome Back',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.ink),
            ),
            const SizedBox(height: 6),
            const Text(
              'Please enter your details to access your portal',
              style: TextStyle(color: AppColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 28),
            const _FieldLabel('Username/Email Address'),
            TextFormField(
              controller: _emailController,
              autofillHints: const [AutofillHints.username],
              style: _fieldTextStyle,
              decoration: _fieldDecoration(hint: 'e.g. coach@northviewhigh.co.za'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const _FieldLabel('Password', bottomSpacing: 0),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    // TODO: forgot password flow
                    onTap: () => openSiteRoute(context, null),
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: AppColors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              autofillHints: const [AutofillHints.password],
              style: _fieldTextStyle,
              onFieldSubmitted: (_) => _handleSignIn(),
              decoration: _fieldDecoration(
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    size: 18,
                    color: AppColors.muted,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _handleSignIn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Sign In', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Don't have an account? ",
                    style: TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pushNamed(SiteRoutes.signup),
                      child: const Text(
                        'Register and Sign up',
                        style: TextStyle(
                          color: AppColors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _fieldTextStyle = TextStyle(fontSize: 13, color: AppColors.ink);

InputDecoration _fieldDecoration({String? hint, Widget? suffixIcon}) {
  OutlineInputBorder border(Color color, [double width = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: color, width: width),
      );
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(fontSize: 13, color: AppColors.muted),
    filled: true,
    fillColor: AppColors.surface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    suffixIcon: suffixIcon,
    enabledBorder: border(AppColors.border),
    focusedBorder: border(AppColors.green, 1.5),
    errorBorder: border(Colors.red.shade400),
    focusedErrorBorder: border(Colors.red.shade400, 1.5),
  );
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text, {this.bottomSpacing = 6});

  final String text;
  final double bottomSpacing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottomSpacing),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink),
      ),
    );
  }
}

class _LoginPanelContent extends StatelessWidget {
  const _LoginPanelContent();

  static const _benefits = [
    'Real-time match fixtures & schedules',
    'Live score updates and historical stats',
    'Regional standings and championship races',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'OFFICIAL SCHOOL SPORTS PORTAL',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text.rich(
          TextSpan(
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              height: 1.2,
              color: Colors.white,
            ),
            children: [
              TextSpan(text: 'THE HOME OF '),
              TextSpan(text: 'SCHOOL SPORTS', style: TextStyle(color: AppColors.orange)),
              TextSpan(text: ' FIXTURES.'),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(width: 60, height: 3, color: AppColors.orange),
        const SizedBox(height: 26),
        for (final benefit in _benefits)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 3),
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(color: AppColors.orange, shape: BoxShape.circle),
                  child: const Icon(Icons.check, size: 10, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    benefit,
                    style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.3),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        Text(
          'Join thousands of athletes, coaches, and parents across the region tracking '
          'their favourite school teams.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 12,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
