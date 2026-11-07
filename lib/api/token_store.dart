import 'package:shared_preferences/shared_preferences.dart';

/// The pair of tokens the backend hands out. Refresh tokens are single use, so
/// always save the newest pair.
class Tokens {
  const Tokens({required this.accessToken, required this.refreshToken});

  final String accessToken;
  final String refreshToken;
}

/// Where the tokens live between requests and between visits.
abstract class TokenStore {
  Future<Tokens?> read();
  Future<void> write(Tokens tokens);
  Future<void> clear();
}

/// Keeps tokens in memory only. Used by tests, and a safe fallback.
class MemoryTokenStore implements TokenStore {
  Tokens? _tokens;

  @override
  Future<Tokens?> read() async => _tokens;

  @override
  Future<void> write(Tokens tokens) async => _tokens = tokens;

  @override
  Future<void> clear() async => _tokens = null;
}

/// Keeps tokens in the browser's local storage (via shared_preferences), so a
/// visitor stays signed in after a reload.
///
/// Local storage can be read by any script on the page, so keep the site free of
/// third-party scripts. The access token is short lived (15 minutes).
class PrefsTokenStore implements TokenStore {
  static const _accessKey = 'sportstures.accessToken';
  static const _refreshKey = 'sportstures.refreshToken';

  @override
  Future<Tokens?> read() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final access = prefs.getString(_accessKey);
      final refresh = prefs.getString(_refreshKey);
      if (access == null || refresh == null) return null;
      return Tokens(accessToken: access, refreshToken: refresh);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(Tokens tokens) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_accessKey, tokens.accessToken);
      await prefs.setString(_refreshKey, tokens.refreshToken);
    } catch (_) {
      // Storage can be blocked (private window). The session then lasts until reload.
    }
  }

  @override
  Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_accessKey);
      await prefs.remove(_refreshKey);
    } catch (_) {}
  }
}
