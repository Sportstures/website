import 'api_client.dart';
import 'session.dart';

/// The signed-in person's own details, as the account page edits them.
class Profile {
  const Profile({required this.firstName, required this.lastName, required this.email, this.phone, this.dateOfBirth, this.gender});

  final String firstName;
  final String lastName;
  final String email;
  final String? phone;

  /// `YYYY-MM-DD`.
  final String? dateOfBirth;

  /// `male` or `female`.
  final String? gender;

  factory Profile.fromJson(Map<String, dynamic> json) {
    final born = json['dateOfBirth'] as String?;
    return Profile(
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      dateOfBirth: born == null || born.length < 10 ? born : born.substring(0, 10),
      gender: json['gender'] as String?,
    );
  }
}

/// Changes to the account after signup. Each call keeps the [Session] up to date.
class AccountApi {
  AccountApi(this.session);

  final Session session;

  ApiClient get _client => session.api;

  Future<Profile> profile() async {
    final data = await _client.get('/api/auth/me') as Map<String, dynamic>;
    return Profile.fromJson(Map<String, dynamic>.from(data['user'] as Map));
  }

  /// Sends only [changes].
  Future<Profile> update(Map<String, Object?> changes) async {
    final data = await _client.patch('/api/me/profile', body: changes) as Map<String, dynamic>;
    final user = Map<String, dynamic>.from(data['user'] as Map);
    session.userChanged(user);
    return Profile.fromJson(user);
  }

  /// The server signs other devices out and answers with new tokens for this one.
  Future<void> changePassword(String current, String next) async {
    final data = await _client.put('/api/me/password', body: {'currentPassword': current, 'newPassword': next}) as Map<String, dynamic>;
    await session.signInWith(data);
  }

  /// Emails a code to the new address. Nothing changes until it is confirmed.
  Future<void> requestEmailChange(String newEmail, String password) =>
      _client.post('/api/me/email', body: {'newEmail': newEmail.trim(), 'password': password});

  Future<Profile> confirmEmailChange(String code) async {
    final data = await _client.post('/api/me/email/verify', body: {'code': code.trim()}) as Map<String, dynamic>;
    final user = Map<String, dynamic>.from(data['user'] as Map);
    session.userChanged(user);
    return Profile.fromJson(user);
  }
}
