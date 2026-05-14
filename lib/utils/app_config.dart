import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  const AppConfig._();

  static String get apiBaseUrl =>
      dotenv.maybeGet('API_BASE_URL') ?? 'https://api.example.com';

  static bool get useMockApi {
    final raw = dotenv.maybeGet('USE_MOCK_API') ?? 'true';
    return raw.toLowerCase() != 'false';
  }

  static String? get aiAgentBaseUrl => dotenv.maybeGet('AI_AGENT_BASE_URL');

  static bool get hasAiAgentKey {
    final key = dotenv.maybeGet('AI_AGENT_API_KEY');
    return key != null && key.trim().isNotEmpty;
  }
}
