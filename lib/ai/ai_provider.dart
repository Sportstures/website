import 'ai_service.dart';
import 'local_ai_service.dart';

/// The AI implementation the whole site talks to.
///
/// This is the single swap point. Today it reads the sample match history that
/// ships with the app; once `Sportstures/backend-` exposes its AI endpoints,
/// assign a `BackendAiService` here and every page follows without changing.
/// Tests can reassign it to a stub.
AiService aiService = const LocalAiService();
