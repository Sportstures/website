import 'package:flutter/material.dart';

import '../widgets/site/site_routes.dart';

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

  // TODO: confirm exact hex values against the Figma file
  static const _forestGreen = Color(0xFF1E4A3D);
  static const _accentOrange = Color(0xFFF5A623);

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
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 1000, maxHeight: 620),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 700;
              if (isWide) {
                return Row(
                  children: [
                    Expanded(flex: 5, child: _buildLeftPanel()),
                    Expanded(flex: 5, child: _buildRightPanel()),
                  ],
                );
              }
              // On narrow screens, just show the form
              return SingleChildScrollView(child: _buildRightPanel());
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLeftPanel() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_forestGreen.withOpacity(0.95), _forestGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        image: const DecorationImage(
          // TODO: replace with the actual stadium/field background asset
          image: AssetImage('assets/images/stadium_bg.png'),
          fit: BoxFit.cover,
          opacity: 0.35,
        ),
      ),
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
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
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                height: 1.25,
              ),
              children: [
                const TextSpan(text: 'THE HOME OF ', style: TextStyle(color: Colors.white)),
                TextSpan(text: 'SCHOOL SPORTS', style: TextStyle(color: _accentOrange)),
                const TextSpan(text: ' FIXTURES.', style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(width: 60, height: 3, color: _accentOrange),
          const SizedBox(height: 24),
          _bulletPoint('Real-time match fixtures & schedules'),
          const SizedBox(height: 12),
          _bulletPoint('Live score updates and historical stats'),
          const SizedBox(height: 12),
          _bulletPoint('Regional standings and championship races'),
          const SizedBox(height: 28),
          Text(
            'Join thousands of athletes, coaches, and parents across the region tracking their favorite sports teams.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bulletPoint(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 3),
          width: 16,
          height: 16,
          decoration: const BoxDecoration(
            color: _accentOrange,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check, size: 10, color: Colors.white),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.3),
          ),
        ),
      ],
    );
  }

  Widget _buildRightPanel() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Image.asset(
                // TODO: replace with the real school/org crest logo
                'assets/images/logo.png',
                height: 48,
                errorBuilder: (_, __, ___) => const SizedBox(height: 48),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Welcome Back',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Please enter your details to access your portal',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 28),
            const Text('Username/Email Address',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                hintText: 'e.g. coach@martinview.high.edu',
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Password',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                GestureDetector(
                  onTap: () {
                    // TODO: forgot password flow
                  },
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(
                        color: _forestGreen, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility,
                      size: 18),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: _handleSignIn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _forestGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Sign In',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 18),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Don't have an account? ",
                    style: TextStyle(color: Colors.grey[700], fontSize: 12),
                  ),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pushNamed(SiteRoutes.signup),
                      child: const Text(
                        'Register and Sign up',
                        style: TextStyle(
                            color: _forestGreen, fontSize: 12, fontWeight: FontWeight.w600),
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
