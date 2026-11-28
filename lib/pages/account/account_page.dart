import 'package:flutter/material.dart';

import '../../api/account_api.dart';
import '../../api/api_exception.dart';
import '../../api/session.dart';
import '../../theme/app_colors.dart';
import '../../widgets/site/page_hero.dart';
import '../../widgets/site/site_routes.dart';
import '../../widgets/site/site_scaffold.dart';
import '../../widgets/site/ui_kit.dart';
import '../signup/steps/account_setup_step.dart';

/// The signed-in person's profile, password and email address.
class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    final user = session.user;
    return SiteScaffold(
      currentRoute: SiteRoutes.account,
      children: [
        const PageHero(title: 'My Account', breadcrumb: 'My Account', subtitle: 'Your details, password and email address.'),
        ContentWidth(
          child: Padding(
            padding: const EdgeInsets.only(top: 28, bottom: 56),
            child: user != null
                // Keyed by person, so signing in as someone else starts afresh.
                ? _Account(key: ValueKey(user.id))
                : session.isRestoring
                    ? const Center(child: CircularProgressIndicator())
                    : SectionCard(
                        title: 'Log in to continue',
                        child: Column(children: [
                          const EmptyState('Log in to see your account.'),
                          SiteButton(label: 'LOG IN', small: true, onPressed: () => openSiteRoute(context, SiteRoutes.login)),
                          const SizedBox(height: 12),
                        ]),
                      ),
          ),
        ),
      ],
    );
  }
}

class _Account extends StatefulWidget {
  const _Account({super.key});

  @override
  State<_Account> createState() => _AccountState();
}

class _AccountState extends State<_Account> {
  late final AccountApi _api = AccountApi(SessionScope.read(context));

  Profile? _profile;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final profile = await _api.profile();
      if (mounted) setState(() => _profile = profile);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    if (profile == null) {
      return _error == null
          ? const Center(child: CircularProgressIndicator())
          : SectionCard(
              title: "Couldn't load your account",
              child: Column(children: [
                EmptyState(_error!),
                SiteButton(label: 'TRY AGAIN', small: true, onPressed: _load),
                const SizedBox(height: 12),
              ]),
            );
    }
    return TwoColumnLayout(
      main: _ProfileForm(api: _api, profile: profile, onSaved: (p) => setState(() => _profile = p)),
      sidebar: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PasswordForm(api: _api),
          const SizedBox(height: 16),
          _EmailForm(api: _api, current: profile.email, onChanged: (p) => setState(() => _profile = p)),
        ],
      ),
    );
  }
}

InputDecoration _input(String label) =>
    InputDecoration(labelText: label, border: const OutlineInputBorder(), isDense: true, counterText: '');

String _message(ApiException e) => switch (e.code) {
      'WRONG_PASSWORD' => 'That password is not right.',
      'SAME_PASSWORD' => 'Choose a password different from your current one.',
      'SAME_EMAIL' => 'That is already your email address.',
      'EMAIL_TAKEN' => 'Another account already uses that email address.',
      'INVALID_OTP' => 'That code is wrong or has expired.',
      'TOO_MANY_REQUESTS' => 'Too many tries. Wait a minute and try again.',
      _ => e.fieldErrors.isNotEmpty ? e.fieldErrors.values.first : e.message,
    };

class _Status extends StatelessWidget {
  const _Status({this.error, this.done});

  final String? error;
  final String? done;

  @override
  Widget build(BuildContext context) {
    final text = error ?? done;
    if (text == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Text(text,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: error != null ? Colors.red.shade700 : AppColors.green)),
    );
  }
}

Widget _card(String title, GlobalKey<FormState> form, List<Widget> children) => SectionCard(
      title: title,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Form(key: form, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children)),
      ),
    );

class _ProfileForm extends StatefulWidget {
  const _ProfileForm({required this.api, required this.profile, required this.onSaved});

  final AccountApi api;
  final Profile profile;
  final ValueChanged<Profile> onSaved;

  @override
  State<_ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<_ProfileForm> {
  final _form = GlobalKey<FormState>();
  late final _first = TextEditingController(text: widget.profile.firstName);
  late final _last = TextEditingController(text: widget.profile.lastName);
  late final _phone = TextEditingController(text: widget.profile.phone ?? '');
  late String? _born = widget.profile.dateOfBirth;
  late String? _gender = const ['male', 'female'].contains(widget.profile.gender) ? widget.profile.gender : null;
  bool _saving = false;
  String? _error;
  String? _done;

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_born ?? '') ?? DateTime(now.year - 20),
      firstDate: DateTime(now.year - 99),
      lastDate: now,
      initialEntryMode: DatePickerEntryMode.input,
    );
    if (picked != null && mounted) {
      setState(() => _born = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}');
    }
  }

  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    final p = widget.profile;
    final first = _first.text.trim();
    final last = _last.text.trim();
    final phone = _phone.text.trim();
    final changes = <String, Object?>{
      if (first != p.firstName) 'firstName': first,
      if (last != p.lastName) 'lastName': last,
      // An empty phone removes it.
      if (phone != (p.phone ?? '')) 'phone': phone,
      if (_born != null && _born != p.dateOfBirth) 'dateOfBirth': _born,
      if (_gender != null && _gender != p.gender) 'gender': _gender,
    };
    if (changes.isEmpty) {
      setState(() {
        _error = null;
        _done = 'Nothing has changed.';
      });
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
      _done = null;
    });
    try {
      final saved = await widget.api.update(changes);
      if (!mounted) return;
      widget.onSaved(saved);
      setState(() => _done = 'Your details are saved.');
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = _message(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _name(String? v) => (v ?? '').trim().isEmpty ? 'Required' : null;

  @override
  Widget build(BuildContext context) => _card('Your details', _form, [
        TextFormField(controller: _first, maxLength: 100, decoration: _input('First name'), validator: _name),
        const SizedBox(height: 12),
        TextFormField(controller: _last, maxLength: 100, decoration: _input('Last name'), validator: _name),
        const SizedBox(height: 12),
        TextFormField(
          controller: _phone,
          maxLength: 20,
          keyboardType: TextInputType.phone,
          decoration: _input('Phone (optional)'),
          validator: (v) => RegExp(r'^[+0-9 ()-]*$').hasMatch((v ?? '').trim()) ? null : 'Use digits, spaces, +, - and brackets',
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.cake_outlined, size: 16),
              label: Text(_born == null ? 'Date of birth' : 'Born $_born'),
            ),
            for (final (value, label) in [('male', 'Male'), ('female', 'Female')])
              ChoiceChip(label: Text(label), selected: _gender == value, onSelected: (_) => setState(() => _gender = value)),
          ],
        ),
        _Status(error: _error, done: _done),
        const SizedBox(height: 14),
        SiteButton(label: _saving ? 'SAVING…' : 'SAVE DETAILS', small: true, onPressed: _saving ? null : _save),
      ]);
}

class _PasswordForm extends StatefulWidget {
  const _PasswordForm({required this.api});

  final AccountApi api;

  @override
  State<_PasswordForm> createState() => _PasswordFormState();
}

class _PasswordFormState extends State<_PasswordForm> {
  final _form = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _again = TextEditingController();
  bool _saving = false;
  String? _error;
  String? _done;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _again.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _error = null;
      _done = null;
    });
    try {
      await widget.api.changePassword(_current.text, _next.text);
      if (!mounted) return;
      _current.clear();
      _next.clear();
      _again.clear();
      setState(() => _done = 'Password changed. Other devices have been signed out.');
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = _message(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _secret(String label, TextEditingController c, String? Function(String?) validator) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(key: ValueKey(label), controller: c, obscureText: true, decoration: _input(label), validator: validator),
      );

  @override
  Widget build(BuildContext context) => _card('Change password', _form, [
        _secret('Current password', _current, (v) => (v ?? '').isEmpty ? 'Required' : null),
        _secret('New password', _next, (v) => AccountSetupStep.passwordProblem(v ?? '')),
        _secret('Repeat new password', _again, (v) => v == _next.text ? null : 'The passwords do not match'),
        _Status(error: _error, done: _done),
        const SizedBox(height: 8),
        SiteButton(label: _saving ? 'ONE MOMENT…' : 'CHANGE PASSWORD', small: true, onPressed: _saving ? null : _save),
      ]);
}

class _EmailForm extends StatefulWidget {
  const _EmailForm({required this.api, required this.current, required this.onChanged});

  final AccountApi api;
  final String current;
  final ValueChanged<Profile> onChanged;

  @override
  State<_EmailForm> createState() => _EmailFormState();
}

class _EmailFormState extends State<_EmailForm> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _code = TextEditingController();

  /// The address a code was sent to, while waiting for it.
  String? _pending;
  bool _busy = false;
  String? _error;
  String? _done;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
      _done = null;
    });
    try {
      await action();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = _message(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _send() => _run(() async {
        final address = _email.text.trim();
        await widget.api.requestEmailChange(address, _password.text);
        if (!mounted) return;
        _password.clear();
        setState(() => _pending = address);
      });

  void _confirm() => _run(() async {
        final profile = await widget.api.confirmEmailChange(_code.text);
        if (!mounted) return;
        widget.onChanged(profile);
        _email.clear();
        _code.clear();
        setState(() {
          _pending = null;
          _done = 'Your email is changed. Log in with ${profile.email} from now on.';
        });
      });

  @override
  Widget build(BuildContext context) {
    const muted = TextStyle(fontSize: 12, color: AppColors.muted, height: 1.5);
    return _card('Change email', _form, [
      Text('Current: ${widget.current}', style: muted),
      const SizedBox(height: 12),
      if (_pending == null) ...[
        TextFormField(
          key: const ValueKey('New email address'),
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          decoration: _input('New email address'),
          validator: (v) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch((v ?? '').trim()) ? null : 'Enter a valid email address',
        ),
        const SizedBox(height: 12),
        TextFormField(
          key: const ValueKey('Your password'),
          controller: _password,
          obscureText: true,
          decoration: _input('Your password'),
          validator: (v) => (v ?? '').isEmpty ? 'Required' : null,
        ),
        _Status(error: _error, done: _done),
        const SizedBox(height: 12),
        SiteButton(label: _busy ? 'SENDING…' : 'SEND CODE', small: true, onPressed: _busy ? null : _send),
      ] else ...[
        Text('We sent a 6-digit code to $_pending. Your email changes once you enter it.', style: muted),
        const SizedBox(height: 12),
        TextFormField(
          key: const ValueKey('6-digit code'),
          controller: _code,
          keyboardType: TextInputType.number,
          decoration: _input('6-digit code'),
          validator: (v) => RegExp(r'^[0-9]{6}$').hasMatch((v ?? '').trim()) ? null : 'Enter the 6 digits from the email',
        ),
        _Status(error: _error),
        const SizedBox(height: 12),
        Wrap(spacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
          SiteButton(label: _busy ? 'ONE MOMENT…' : 'CONFIRM', small: true, onPressed: _busy ? null : _confirm),
          TextButton(
            onPressed: () => setState(() {
              _pending = null;
              _code.clear();
              _error = null;
            }),
            child: const Text('Start again'),
          ),
        ]),
      ],
    ]);
  }
}
