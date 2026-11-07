import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../api/api_exception.dart';
import '../../../api/session.dart';
import '../../../theme/app_colors.dart';
import '../widgets/form_fields.dart';

/// Step 4. The backend emails a six-digit code; entering it confirms the address.
class VerifyStep extends StatefulWidget {
  const VerifyStep({
    super.key,
    required this.session,
    required this.email,
    required this.onVerified,
    this.initialCooldown = 60,
  });

  final Session session;
  final String email;

  /// Called after a correct code. The user is the signed-in coach, or null for
  /// a learner (who must log in next).
  final ValueChanged<AppUser?> onVerified;

  /// Seconds before "resend" works. 60 right after signing up, because the
  /// backend has just sent a code; 0 when the person arrives without one.
  final int initialCooldown;

  @override
  State<VerifyStep> createState() => _VerifyStepState();
}

class _VerifyStepState extends State<VerifyStep> {
  final _code = TextEditingController();
  Timer? _timer;
  late int _cooldown = widget.initialCooldown;
  bool _busy = false;
  String? _error;
  String? _notice;

  @override
  void initState() {
    super.initState();
    if (_cooldown > 0) _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _cooldown = _cooldown > 0 ? _cooldown - 1 : 0);
      if (_cooldown == 0) t.cancel();
    });
  }

  Future<void> _verify() async {
    final code = _code.text.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      setState(() => _error = 'Enter the 6-digit code from your email');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });
    try {
      final user = await widget.session.verifyOtp(widget.email, code);
      if (!mounted) return;
      widget.onVerified(user);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.code == 'INVALID_OTP' ? 'That code is wrong or has expired. Check it or ask for a new one.' : e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resend() async {
    setState(() {
      _error = null;
      _notice = null;
    });
    try {
      final wait = await widget.session.resendOtp(widget.email);
      if (!mounted) return;
      setState(() {
        _notice = 'A new code is on its way to ${widget.email}.';
        _cooldown = wait > 0 ? wait : 60;
      });
      _startTimer();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StepHeader(
          title: 'Verify your email',
          subtitle: 'We sent a 6-digit code to ${widget.email}. It expires after 10 minutes.',
        ),
        const FieldLabel('Verification code'),
        TextField(
          controller: _code,
          keyboardType: TextInputType.number,
          autofillHints: const [AutofillHints.oneTimeCode],
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
          onSubmitted: (_) => _verify(),
          style: const TextStyle(fontSize: 20, letterSpacing: 8, color: AppColors.ink),
          decoration: InputDecoration(
            hintText: '000000',
            filled: true,
            fillColor: Colors.white,
            errorText: _error,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        if (_notice != null) ...[
          const SizedBox(height: 8),
          Text(_notice!, style: const TextStyle(color: AppColors.green, fontSize: 12)),
        ],
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 46,
          child: ElevatedButton(
            onPressed: _busy ? null : _verify,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.orange,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: const StadiumBorder(),
            ),
            child: _busy
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Verify', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: _cooldown > 0 ? null : _resend,
            child: Text(_cooldown > 0 ? 'Resend code in ${_cooldown}s' : 'Resend code'),
          ),
        ),
      ],
    );
  }
}
