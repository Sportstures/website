import 'package:flutter/widgets.dart';

import 'api_client.dart';
import 'api_exception.dart';
import 'token_store.dart';

/// The signed-in person, as the backend describes them.
class AppUser {
  const AppUser({
    required this.id,
    required this.role,
    this.firstName,
    this.lastName,
    this.email,
    this.team,
  });

  final int id;

  /// `learner`, `coach` or `admin`.
  final String role;
  final String? firstName;
  final String? lastName;
  final String? email;

  /// A coach's own team, as sent by the backend (`id`, `name`, `level`, `sport`, `school`).
  final Map<String, dynamic>? team;

  bool get isCoach => role == 'coach';
  bool get isLearner => role == 'learner';
  bool get isAdmin => role == 'admin';

  String get displayName => [firstName, lastName].whereType<String>().where((s) => s.isNotEmpty).join(' ');

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final profile = json['profile'];
    final team = json['team'] ?? (profile is Map ? profile['team'] : null);
    return AppUser(
      id: json['id'] as int,
      role: '${json['role']}',
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      email: json['email'] as String?,
      team: team is Map ? Map<String, dynamic>.from(team) : null,
    );
  }
}

/// Who is signed in. Pages listen to this to show login or account state.
class Session extends ChangeNotifier {
  Session(this.api) {
    api.onSessionExpired = _expired;
  }

  final ApiClient api;

  AppUser? _user;
  bool _restoring = false;

  AppUser? get user => _user;
  bool get isSignedIn => _user != null;

  /// True while a saved session is being checked at startup.
  bool get isRestoring => _restoring;

  /// Checks saved tokens at startup. Never throws: no valid session just means signed out.
  Future<void> restore() async {
    if (await api.tokens.read() == null) return;
    _restoring = true;
    notifyListeners();
    try {
      final data = await api.get('/api/auth/me') as Map<String, dynamic>;
      _user = AppUser.fromJson(data['user'] as Map<String, dynamic>);
    } on ApiException catch (e) {
      // Offline keeps the tokens for next time; anything else means they are no good.
      if (!e.isNetwork) await api.tokens.clear();
    } finally {
      _restoring = false;
      notifyListeners();
    }
  }

  /// Signs in. Throws [ApiException] (e.g. `INVALID_CREDENTIALS`, `EMAIL_NOT_VERIFIED`).
  Future<AppUser> login(String email, String password) async {
    final data = await api.post('/api/auth/login',
        body: {'email': email.trim(), 'password': password}, auth: false) as Map<String, dynamic>;
    return _accept(data);
  }

  /// Confirms the emailed code. Coaches are signed in by this call and the user is returned.
  /// Learners must log in afterwards, so this returns null for them.
  Future<AppUser?> verifyOtp(String email, String code) async {
    final data = await api.post('/api/auth/verify-otp',
        body: {'email': email.trim(), 'code': code.trim()}, auth: false) as Map<String, dynamic>;
    if (data['accessToken'] == null) return null;
    return _accept(data);
  }

  /// Asks for a new code. Returns how many seconds to wait before the next resend.
  Future<int> resendOtp(String email) async {
    final data = await api.post('/api/auth/resend-otp', body: {'email': email.trim()}, auth: false) as Map<String, dynamic>;
    return (data['retryAfterSeconds'] as num?)?.toInt() ?? 0;
  }

  Future<void> logout() async {
    final saved = await api.tokens.read();
    _user = null;
    notifyListeners();
    if (saved != null) {
      try {
        await api.post('/api/auth/logout', body: {'refreshToken': saved.refreshToken}, auth: false);
      } on ApiException {
        // The server will expire the token itself; signing out locally is what matters.
      }
    }
    await api.tokens.clear();
  }

  Future<AppUser> _accept(Map<String, dynamic> data) async {
    await api.tokens.write(Tokens(
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
    ));
    _user = AppUser.fromJson(data['user'] as Map<String, dynamic>);
    notifyListeners();
    return _user!;
  }

  void _expired() {
    if (_user == null) return;
    _user = null;
    notifyListeners();
  }
}

/// Makes the [Session] available to every page: `SessionScope.of(context)`.
class SessionScope extends InheritedNotifier<Session> {
  const SessionScope({super.key, required Session session, required super.child}) : super(notifier: session);

  static Session of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<SessionScope>();
    assert(scope != null, 'No SessionScope above this widget');
    return scope!.notifier!;
  }

  /// Like [of] but does not rebuild when the session changes.
  static Session read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<SessionScope>();
    assert(scope != null, 'No SessionScope above this widget');
    return scope!.notifier!;
  }
}
