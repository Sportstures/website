import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_exception.dart';
import 'token_store.dart';

/// Where the backend lives. Override at build time:
/// `flutter run --dart-define=API_BASE_URL=https://api.example.com`
const apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:5000');

/// Talks to the Sportstures backend. It adds the Bearer token, and when the
/// access token has expired it refreshes the pair once and retries the request.
class ApiClient {
  ApiClient({
    http.Client? httpClient,
    String baseUrl = apiBaseUrl,
    TokenStore? tokenStore,
    this.timeout = const Duration(seconds: 20),
  })  : _http = httpClient ?? http.Client(),
        _base = Uri.parse(baseUrl),
        tokens = tokenStore ?? MemoryTokenStore();

  final http.Client _http;
  final Uri _base;
  final Duration timeout;
  final TokenStore tokens;

  /// Called when the refresh token no longer works, so the app can send the
  /// user to the login page. Tokens have already been cleared by then.
  void Function()? onSessionExpired;

  // Refresh tokens are single use, so parallel requests must share one refresh.
  Future<bool>? _refreshing;

  Future<dynamic> get(String path, {Map<String, Object?>? query, bool auth = true}) =>
      _send('GET', path, query: query, auth: auth);

  Future<dynamic> post(String path, {Object? body, bool auth = true}) =>
      _send('POST', path, body: body, auth: auth);

  Future<dynamic> put(String path, {Object? body}) => _send('PUT', path, body: body);

  Future<dynamic> patch(String path, {Object? body}) => _send('PATCH', path, body: body);

  Future<dynamic> delete(String path) => _send('DELETE', path);

  /// Uploads one image as multipart/form-data (field "photo") with PUT, like the profile photo and team logo.
  Future<dynamic> putPhoto(String path, List<int> bytes, {String filename = 'photo'}) async {
    Future<http.Response> once() async {
      final request = http.MultipartRequest('PUT', _uri(path, null));
      request.headers['Accept'] = 'application/json';
      final saved = await tokens.read();
      if (saved != null) request.headers['Authorization'] = 'Bearer ${saved.accessToken}';
      request.files.add(http.MultipartFile.fromBytes('photo', bytes, filename: filename));
      try {
        final streamed = await _http.send(request).timeout(const Duration(seconds: 60));
        return await http.Response.fromStream(streamed);
      } catch (_) {
        throw ApiException.network();
      }
    }

    var response = await once();
    if (response.statusCode == 401 && _code(response) == 'TOKEN_EXPIRED' && await _refresh()) {
      response = await once();
    }
    return _unwrap(response);
  }

  Uri _uri(String path, Map<String, Object?>? query) {
    final params = <String, String>{
      for (final e in (query ?? const {}).entries)
        if (e.value != null && '${e.value}'.isNotEmpty) e.key: '${e.value}',
    };
    return _base.replace(
      path: '${_base.path.replaceAll(RegExp(r'/+$'), '')}$path',
      queryParameters: params.isEmpty ? null : params,
    );
  }

  Future<dynamic> _send(
    String method,
    String path, {
    Object? body,
    Map<String, Object?>? query,
    bool auth = true,
  }) async {
    var response = await _once(method, path, body: body, query: query, auth: auth);

    // An expired access token is the one 401 worth retrying.
    if (auth && response.statusCode == 401 && _code(response) == 'TOKEN_EXPIRED') {
      if (await _refresh()) {
        response = await _once(method, path, body: body, query: query, auth: auth);
      }
    }
    return _unwrap(response);
  }

  Future<http.Response> _once(
    String method,
    String path, {
    Object? body,
    Map<String, Object?>? query,
    required bool auth,
  }) async {
    final request = http.Request(method, _uri(path, query));
    request.headers['Accept'] = 'application/json';
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    if (auth) {
      final saved = await tokens.read();
      if (saved != null) request.headers['Authorization'] = 'Bearer ${saved.accessToken}';
    }
    try {
      final streamed = await _http.send(request).timeout(timeout);
      return await http.Response.fromStream(streamed).timeout(timeout);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException.network();
    }
  }

  Future<bool> _refresh() => _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);

  Future<bool> _doRefresh() async {
    final saved = await tokens.read();
    if (saved == null) return await _expire();
    try {
      final response = await _once('POST', '/api/auth/refresh',
          body: {'refreshToken': saved.refreshToken}, auth: false);
      if (response.statusCode != 200) return await _expire();
      final data = jsonDecode(response.body);
      await tokens.write(Tokens(
        accessToken: data['accessToken'] as String,
        refreshToken: data['refreshToken'] as String,
      ));
      return true;
    } on ApiException {
      // Could not reach the server: keep the tokens, the user may just be offline.
      return false;
    } catch (_) {
      return _expire();
    }
  }

  Future<bool> _expire() async {
    await tokens.clear();
    onSessionExpired?.call();
    return false;
  }

  Object? _decode(http.Response response) {
    if (response.body.isEmpty) return null;
    try {
      return jsonDecode(response.body);
    } catch (_) {
      return null;
    }
  }

  String? _code(http.Response response) {
    final body = _decode(response);
    if (body is Map && body['error'] is Map) return '${(body['error'] as Map)['code']}';
    return null;
  }

  dynamic _unwrap(http.Response response) {
    final status = response.statusCode;
    if (status >= 200 && status < 300) return _decode(response);
    throw ApiException.fromResponse(status, _decode(response));
  }

  void close() => _http.close();
}
