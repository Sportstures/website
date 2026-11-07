/// An error answered by the Sportstures backend, or a failure to reach it.
///
/// The backend always answers errors as
/// `{ "error": { "code", "message", "details"? } }`, except coach signup
/// validation (422) which answers `{ "errors": { field: message } }`.
class ApiException implements Exception {
  const ApiException({
    required this.status,
    required this.code,
    required this.message,
    this.fieldErrors = const {},
  });

  /// HTTP status, or 0 when the server could not be reached.
  final int status;

  /// Machine-readable code such as `INVALID_CREDENTIALS` or `JERSEY_TAKEN`.
  final String code;

  /// Text that is safe to show the user.
  final String message;

  /// Field name -> message, for forms. Empty when the error is not about fields.
  final Map<String, String> fieldErrors;

  static const networkCode = 'NETWORK';
  static const unknownCode = 'UNKNOWN';

  bool get isNetwork => code == networkCode;
  bool get isUnauthorized => status == 401;

  factory ApiException.network() => const ApiException(
        status: 0,
        code: networkCode,
        message: 'Could not reach Sportstures. Check your connection and try again.',
      );

  /// Builds an exception from a response status and its decoded JSON body.
  factory ApiException.fromResponse(int status, Object? body) {
    if (body is Map) {
      final error = body['error'];
      if (error is Map) {
        final fields = <String, String>{};
        final details = error['details'];
        if (details is List) {
          for (final d in details) {
            if (d is Map && d['field'] != null) {
              fields.putIfAbsent('${d['field']}', () => '${d['message'] ?? ''}');
            }
          }
        }
        return ApiException(
          status: status,
          code: '${error['code'] ?? unknownCode}',
          message: '${error['message'] ?? 'Something went wrong.'}',
          fieldErrors: fields,
        );
      }
      final errors = body['errors'];
      if (errors is Map) {
        final fields = {for (final e in errors.entries) '${e.key}': '${e.value}'};
        return ApiException(
          status: status,
          code: 'VALIDATION_ERROR',
          message: fields.values.isNotEmpty ? fields.values.first : 'Invalid input',
          fieldErrors: fields,
        );
      }
    }
    return ApiException(
      status: status,
      code: unknownCode,
      message: status >= 500
          ? 'Sportstures had a problem. Please try again shortly.'
          : 'Something went wrong.',
    );
  }

  @override
  String toString() => 'ApiException($status $code: $message)';
}
