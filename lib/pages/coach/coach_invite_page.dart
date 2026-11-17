import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../api/api_exception.dart';
import '../../api/invitations_api.dart';
import '../../api/session.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';
import '../../widgets/site/page_hero.dart';
import '../../widgets/site/site_routes.dart';
import '../../widgets/site/site_scaffold.dart';
import '../../widgets/site/ui_kit.dart';
import 'coach_guard.dart';

/// Invite a coach from another school: email them an official invitation, or copy a link to share.
class CoachInvitePage extends StatelessWidget {
  const CoachInvitePage({super.key});

  @override
  Widget build(BuildContext context) {
    return CoachGuard(
      currentRoute: SiteRoutes.coachInvite,
      title: 'Invite Another School',
      subtitle: 'Bring a coach from another school onto Sportstures.',
      builder: (context, coach) => const _Invite(),
    );
  }
}

class _Invite extends StatefulWidget {
  const _Invite();

  @override
  State<_Invite> createState() => _InviteState();
}

class _InviteState extends State<_Invite> {
  late final InvitationsApi _api = InvitationsApi(SessionScope.read(context).api);
  final _email = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  InvitationList? _sent;
  Invitation? _link;
  String? _loadError;
  bool _sending = false;
  String? _emailError;
  String? _emailDone;
  bool _linkBusy = false;
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final list = await _api.list();
      if (!mounted) return;
      setState(() {
        _sent = list;
        _link = list.invitations.where((i) => !i.isEmail && i.status == 'pending').firstOrNull;
        _loadError = null;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _loadError = e.message);
    }
  }

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  Future<void> _sendEmail() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final address = _email.text.trim();
    setState(() {
      _sending = true;
      _emailError = null;
      _emailDone = null;
    });
    try {
      await _api.inviteByEmail(address);
      if (!mounted) return;
      _email.clear();
      setState(() => _emailDone = 'Invitation sent to $address. We emailed them a link to register.');
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _emailError = switch (e.code) {
            'ALREADY_REGISTERED' => 'That address already has a Sportstures account.',
            'INVITE_SELF' => 'That is your own email address.',
            _ => e.fieldErrors.isNotEmpty ? e.fieldErrors.values.first : e.message,
          });
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _showLink() async {
    setState(() => _linkBusy = true);
    try {
      final link = await _api.shareLink();
      if (!mounted) return;
      setState(() => _link = link);
    } on ApiException catch (e) {
      if (mounted) setState(() => _loadError = e.message);
    } finally {
      if (mounted) setState(() => _linkBusy = false);
    }
  }

  Future<void> _copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    setState(() => _copied = true);
    Future<void>.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  Future<void> _cancel(Invitation invitation) async {
    try {
      await _api.cancel(invitation.id);
      if (invitation.link == _link?.link) _link = null;
      await _load();
    } on ApiException catch (e) {
      if (mounted) setState(() => _loadError = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SiteScaffold(
      currentRoute: SiteRoutes.coachInvite,
      children: [
        const PageHero(
          title: 'Invite Another School',
          breadcrumb: 'Invite Another School',
          subtitle: 'The more schools on Sportstures, the more fixtures you can play.',
        ),
        ContentWidth(
          child: Padding(
            padding: const EdgeInsets.only(top: 28, bottom: 56),
            child: TwoColumnLayout(
              main: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _emailCard(),
                  const SizedBox(height: 16),
                  _linkCard(),
                ],
              ),
              sidebar: _sentCard(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _emailCard() => SectionCard(
        title: 'Invite by email',
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Enter the school's email address. We'll send an official invitation with a link to register.",
                  style: TextStyle(fontSize: 13, color: AppColors.muted, height: 1.5),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.send,
                  onFieldSubmitted: (_) => _sendEmail(),
                  decoration: const InputDecoration(
                    labelText: 'School email address',
                    hintText: 'principal@otherschool.co.za',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  validator: (v) {
                    final value = (v ?? '').trim();
                    if (value.isEmpty) return 'Enter an email address';
                    if (!_emailPattern.hasMatch(value)) return 'Enter a valid email address';
                    return null;
                  },
                ),
                if (_emailError != null) _Note(_emailError!, error: true),
                if (_emailDone != null) _Note(_emailDone!),
                const SizedBox(height: 14),
                SiteButton(
                  label: _sending ? 'SENDING…' : 'SEND INVITATION',
                  icon: Icons.mail_outline,
                  small: true,
                  onPressed: _sending ? null : _sendEmail,
                ),
              ],
            ),
          ),
        ),
      );

  Widget _linkCard() {
    final link = _link;
    return SectionCard(
      title: 'Share a link',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Copy your invitation link and send it on WhatsApp, social media or email. '
              'Anyone who opens it can register as a coach.',
              style: TextStyle(fontSize: 13, color: AppColors.muted, height: 1.5),
            ),
            const SizedBox(height: 14),
            if (link == null)
              SiteButton(
                label: _linkBusy ? 'ONE MOMENT…' : 'GET MY INVITE LINK',
                icon: Icons.link,
                small: true,
                onPressed: _linkBusy ? null : _showLink,
              )
            else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(link.link, style: const TextStyle(fontSize: 13, color: AppColors.ink)),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  SiteButton(label: 'COPY LINK', icon: Icons.copy, small: true, onPressed: () => _copy(link.link)),
                  const SizedBox(width: 12),
                  if (_copied) const Text('Copied. Paste it into a message.', style: TextStyle(fontSize: 12, color: AppColors.green, fontWeight: FontWeight.w700)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sentCard() {
    final list = _sent;
    return SectionCard(
      title: 'Invitations sent',
      trailing: list == null || list.joined == 0 ? null : Text('${list.joined} joined', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.green)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: _loadError != null
            ? Column(children: [EmptyState(_loadError!), const SizedBox(height: 8), SiteButton(label: 'TRY AGAIN', small: true, onPressed: _load)])
            : list == null
                ? const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
                : list.invitations.isEmpty
                    ? const EmptyState('No invitations yet. Send one and it will show here.')
                    : DividedColumn(children: [for (final i in list.invitations) _row(i)]),
      ),
    );
  }

  Widget _row(Invitation i) {
    final (label, color) = switch (i.status) {
      'accepted' => ('Joined', AppColors.green),
      'expired' => ('Expired', AppColors.muted),
      _ => i.isEmail ? ('Sent', AppColors.orange) : (i.joined == 0 ? ('Active', AppColors.orange) : ('Active', AppColors.green)),
    };
    final title = i.isEmail ? (i.email ?? '') : 'Share link';
    final detail = i.isEmail
        ? (i.status == 'pending' && i.expiresAt != null ? 'Expires ${formatShortDate(i.expiresAt!.toLocal())}' : null)
        : (i.joined == 1 ? '1 coach joined' : '${i.joined} coaches joined');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink)),
                if (detail != null) Text(detail, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
              ],
            ),
          ),
          StatusPill(label, color: color),
          if (i.status != 'accepted')
            IconButton(
              tooltip: 'Cancel invitation',
              icon: const Icon(Icons.close, size: 16, color: AppColors.muted),
              onPressed: () => _cancel(i),
            ),
        ],
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note(this.message, {this.error = false});

  final String message;
  final bool error;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Text(message, style: TextStyle(fontSize: 12, height: 1.4, fontWeight: FontWeight.w600, color: error ? Colors.red.shade700 : AppColors.green)),
      );
}
