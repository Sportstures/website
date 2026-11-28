import 'package:flutter/material.dart';

import '../../../api/api_exception.dart';
import '../../../api/session.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/site/ui_kit.dart';
import 'contact_card.dart';

enum EnquiryType {
  general('General Enquiry'),
  technical('Technical Support'),
  partnerships('Partnerships & Sponsorships'),
  registration('School Registration');

  const EnquiryType(this.label);

  final String label;
}

class ContactFormCard extends StatefulWidget {
  const ContactFormCard({super.key});

  @override
  State<ContactFormCard> createState() => ContactFormCardState();
}

class ContactFormCardState extends State<ContactFormCard> {
  /// Each subject and the support topic the backend files it under.
  static const _subjects = {
    'Registering my school': 'account',
    'Fixtures & results': 'matches',
    'Account & login': 'account',
    'Partnerships & sponsorship': 'other',
    'Something else': 'other',
  };

  var _sending = false;
  String? _error;

  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _message = TextEditingController();
  String? _subject;
  EnquiryType? _enquiry;
  var _showEnquiryError = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _message.dispose();
    super.dispose();
  }

  void selectEnquiry(EnquiryType type) => setState(() {
        _enquiry = type;
        _showEnquiryError = false;
      });

  Future<void> _send() async {
    if (_sending) return;
    final fieldsValid = _formKey.currentState?.validate() ?? false;
    setState(() => _showEnquiryError = _enquiry == null);
    if (!fieldsValid || _enquiry == null) return;

    final session = SessionScope.read(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      // Signed in, the server replies to the account's own name and email.
      final answer = await session.api.post('/api/support/messages', auth: session.isSignedIn, body: {
        'topic': _subjects[_subject],
        'subject': '$_subject (${_enquiry!.label})',
        'message': _message.text.trim(),
        'name': _name.text.trim(),
        'email': _email.text.trim(),
        'app': {'platform': 'web'},
      }) as Map<String, dynamic>;
      if (!mounted) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('${answer['message'] ?? 'Thanks. Your message has been sent.'}')));
    } on ApiException catch (e) {
      // Keep what was written so it can be sent again.
      if (mounted) {
        setState(() {
          _sending = false;
          _error = e.status == 429
              ? 'Too many messages just now. Please try again later.'
              : (e.fieldErrors.isNotEmpty ? e.fieldErrors.values.first : e.message);
        });
      }
      return;
    }

    _formKey.currentState!.reset();
    _name.clear();
    _email.clear();
    _message.clear();
    setState(() {
      _subject = null;
      _enquiry = null;
      _sending = false;
    });
  }

  InputDecoration _decoration(String hint) {
    OutlineInputBorder border(Color color) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: color),
        );
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 12, color: AppColors.muted),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      enabledBorder: border(AppColors.border),
      focusedBorder: border(AppColors.green),
      errorBorder: border(const Color(0xFFDC2626)),
      focusedErrorBorder: border(const Color(0xFFDC2626)),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text.rich(
        TextSpan(
          text: text,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.ink),
          children: const [TextSpan(text: ' *', style: TextStyle(color: Color(0xFFDC2626)))],
        ),
      ),
    );
  }

  static String? _required(String? value) => (value == null || value.trim().isEmpty) ? 'Required' : null;

  @override
  Widget build(BuildContext context) {
    const inputStyle = TextStyle(fontSize: 13, color: AppColors.ink);

    final name = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Your Name'),
        TextFormField(
          controller: _name,
          style: inputStyle,
          autofillHints: const [AutofillHints.name],
          decoration: _decoration('Enter your full name'),
          validator: _required,
        ),
      ],
    );
    final email = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Your Email'),
        TextFormField(
          controller: _email,
          style: inputStyle,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          decoration: _decoration('Enter your email address'),
          validator: (value) {
            if (value == null || value.trim().isEmpty) return 'Required';
            return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim())
                ? null
                : 'Enter a valid email address';
          },
        ),
      ],
    );

    return ContactCard(
      title: 'Send us a message',
      subtitle: "Fill out the form below and we'll get back to you as soon as possible.",
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Screen width rather than LayoutBuilder: this card sits in an
            // IntrinsicHeight row, which can't measure a LayoutBuilder.
            if (MediaQuery.sizeOf(context).width >= 560)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: name),
                  const SizedBox(width: 16),
                  Expanded(child: email),
                ],
              )
            else
              Column(children: [name, const SizedBox(height: 16), email]),
            const SizedBox(height: 16),
            _label('Subject'),
            DropdownButtonFormField<String>(
              key: ValueKey(_subject),
              initialValue: _subject,
              isExpanded: true,
              style: inputStyle,
              hint: const Text('What is this regarding?', style: TextStyle(fontSize: 12, color: AppColors.muted)),
              decoration: _decoration(''),
              items: [for (final subject in _subjects.keys) DropdownMenuItem(value: subject, child: Text(subject))],
              onChanged: (value) => _subject = value,
              validator: (value) => value == null ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            _label('Type of Enquiry'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final type in EnquiryType.values)
                  ChoiceChip(
                    label: Text(type.label),
                    selected: _enquiry == type,
                    onSelected: (_) => selectEnquiry(type),
                    showCheckmark: false,
                    labelStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _enquiry == type ? Colors.white : AppColors.ink,
                    ),
                    selectedColor: AppColors.green,
                    backgroundColor: AppColors.surface,
                    side: BorderSide(color: _enquiry == type ? AppColors.green : AppColors.border),
                  ),
              ],
            ),
            if (_showEnquiryError)
              const Padding(
                padding: EdgeInsets.only(top: 6, left: 12),
                child: Text('Choose the type of enquiry', style: TextStyle(fontSize: 12, color: Color(0xFFDC2626))),
              ),
            const SizedBox(height: 16),
            _label('Message'),
            TextFormField(
              controller: _message,
              style: inputStyle,
              minLines: 4,
              maxLines: 8,
              decoration: _decoration('Tell us more about your enquiry'),
              validator: (value) {
                final length = (value ?? '').trim().length;
                if (length == 0) return 'Required';
                if (length < 10) return 'Please write at least 10 characters';
                return length > 5000 ? 'Please keep it under 5000 characters' : null;
              },
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(_error!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFDC2626))),
              ),
            const SizedBox(height: 20),
            SiteButton(
              label: _sending ? 'SENDING…' : 'SEND MESSAGE',
              icon: Icons.send_outlined,
              expand: true,
              small: true,
              onPressed: _sending ? null : _send,
            ),
            const SizedBox(height: 10),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, size: 14, color: AppColors.muted),
                SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Your information is safe with us. We respect your privacy.',
                    style: TextStyle(fontSize: 11, color: AppColors.muted),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
