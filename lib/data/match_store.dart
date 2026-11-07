import 'package:flutter/widgets.dart';

import '../ai/ai_provider.dart';
import '../ai/local_ai_service.dart';
import '../api/api_client.dart';
import '../api/api_exception.dart';
import 'api_matches.dart';
import 'sports_data.dart';

enum MatchLoad { idle, loading, loaded, failed }

/// Holds the match data the Fixtures, Results and Standings pages draw: either
/// loaded from the backend, or the sample data that ships with the app (used by
/// tests and by pages built outside the app).
class MatchStore extends ChangeNotifier {
  MatchStore.api(ApiClient api)
      : _source = ApiMatchSource(api),
        _state = MatchLoad.idle;

  /// Always has data and never calls the backend.
  MatchStore.sample()
      : _source = null,
        _state = MatchLoad.loaded,
        _data = SportsData.instance;

  final ApiMatchSource? _source;
  MatchLoad _state;
  SportsData? _data;
  String? _error;
  DateTime? _loadedAt;

  MatchLoad get state => _state;
  SportsData? get data => _data;

  /// A message safe to show when [state] is [MatchLoad.failed].
  String? get error => _error;

  /// Data older than this is fetched again the next time a page asks.
  static const staleAfter = Duration(minutes: 2);

  /// Loads the data if there is none yet (or it is old). Safe to call from every page.
  Future<void> ensureLoaded() async {
    if (_source == null || _state == MatchLoad.loading) return;
    final fresh = _loadedAt != null && DateTime.now().difference(_loadedAt!) < staleAfter;
    if (_state == MatchLoad.loaded && fresh) return;
    await reload();
  }

  /// Fetches the data again. A failed refresh keeps the data already on screen.
  Future<void> reload() async {
    final source = _source;
    if (source == null || _state == MatchLoad.loading) return;
    final hadData = _data != null;
    _state = hadData ? _state : MatchLoad.loading;
    _error = null;
    notifyListeners();
    try {
      _data = await source.load();
      _loadedAt = DateTime.now();
      _state = MatchLoad.loaded;
      // The AI cards read their history through this one swap point.
      aiService = LocalAiService(history: _data!.results);
    } on ApiException catch (e) {
      _error = e.message;
      if (!hadData) _state = MatchLoad.failed;
    } catch (_) {
      _error = 'Something went wrong loading matches.';
      if (!hadData) _state = MatchLoad.failed;
    }
    notifyListeners();
  }
}

/// Makes the [MatchStore] available to pages: `MatchScope.maybeOf(context)`.
/// A page with no scope above it uses the sample data.
class MatchScope extends InheritedNotifier<MatchStore> {
  const MatchScope({super.key, required MatchStore store, required super.child}) : super(notifier: store);

  static MatchStore? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<MatchScope>()?.notifier;
}
