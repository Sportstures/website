import 'api_client.dart';

/// One invitation a coach has sent: an email to a school, or their shareable link.
class Invitation {
  const Invitation({
    required this.id,
    required this.isEmail,
    required this.email,
    required this.status,
    required this.link,
    required this.joined,
    required this.emailSent,
    required this.expiresAt,
  });

  factory Invitation.fromJson(Map<String, dynamic> json) => Invitation(
        id: json['id'] as int,
        isEmail: json['kind'] == 'email',
        email: json['email'] as String?,
        status: json['status'] as String? ?? 'pending',
        link: json['link'] as String,
        joined: (json['joined'] as num?)?.toInt() ?? 0,
        emailSent: json['emailSent'] == true,
        expiresAt: DateTime.tryParse('${json['expiresAt']}'),
      );

  final int id;
  final bool isEmail;
  final String? email;

  /// `pending`, `accepted`, `expired` or `cancelled`.
  final String status;

  /// The registration link: `<website>/signup?invite=<code>`.
  final String link;

  /// Coaches who registered through this invitation (a share link can bring in many).
  final int joined;
  final bool emailSent;
  final DateTime? expiresAt;
}

/// What the sign-up page shows when someone opens an invitation link.
class InvitationInfo {
  const InvitationInfo({required this.inviterName, required this.schoolName, required this.email});

  factory InvitationInfo.fromJson(Map<String, dynamic> json) => InvitationInfo(
        inviterName: json['inviterName'] as String? ?? '',
        schoolName: json['schoolName'] as String?,
        email: json['email'] as String?,
      );

  final String inviterName;
  final String? schoolName;

  /// Set when the invitation was emailed, so the form can fill it in.
  final String? email;

  /// "Sipho Williams from Jeppe High", or just the name, or "A coach".
  String get from {
    final who = inviterName.trim().isEmpty ? 'A coach' : inviterName.trim();
    final school = schoolName;
    return school == null || school.isEmpty ? who : '$who from $school';
  }
}

class InvitationList {
  const InvitationList({required this.invitations, required this.joined});

  final List<Invitation> invitations;

  /// Coaches who signed up through any of the invitations.
  final int joined;
}

class InvitationsApi {
  InvitationsApi(this.api);

  final ApiClient api;

  /// Emails an invitation to [email]. Throws [ApiException] (codes `ALREADY_REGISTERED`,
  /// `INVITE_SELF`, `INVITE_LIMIT`, `EMAIL_FAILED`) when it cannot.
  Future<Invitation> inviteByEmail(String email) async {
    final body = await api.post('/api/invitations', body: {'email': email.trim()}) as Map<String, dynamic>;
    return Invitation.fromJson(Map<String, dynamic>.from(body['invitation'] as Map));
  }

  /// The coach's own shareable link (made the first time, then reused).
  Future<Invitation> shareLink() async {
    final body = await api.post('/api/invitations', body: <String, Object?>{}) as Map<String, dynamic>;
    return Invitation.fromJson(Map<String, dynamic>.from(body['invitation'] as Map));
  }

  Future<InvitationList> list() async {
    final body = await api.get('/api/invitations') as Map<String, dynamic>;
    return InvitationList(
      invitations: [for (final i in body['invitations'] as List) Invitation.fromJson(Map<String, dynamic>.from(i as Map))],
      joined: (body['joined'] as num?)?.toInt() ?? 0,
    );
  }

  Future<void> cancel(int id) => api.delete('/api/invitations/$id');

  /// Public: who invited this person. Throws [ApiException] `INVITATION_INVALID` for a dead link.
  Future<InvitationInfo> lookup(String code) async => InvitationInfo.fromJson(
      await api.get('/api/invitations/${Uri.encodeComponent(code)}', auth: false) as Map<String, dynamic>);
}
