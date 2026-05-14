// ApiClient — abstraction over HTTP transport.
//
// PURPOSE
// This file exists to make the eventual migration from MockApiService to a
// real Django REST backend a localized change. Today no production code uses
// `HttpApiClient`; MockApiService returns hardcoded data via Future.delayed.
//
// MIGRATION PATH
// 1. Implement the methods below (uncomment the http package usage).
// 2. Inject `ApiClient` into a new `RemoteApiService` that mirrors the
//    MockApiService surface (getCurrentUser, getLoan, getPayments, login,
//    sendChatMessage).
// 3. Swap the singleton in lib/services/mock_api_service.dart — or expose
//    an `apiServiceProvider` (Riverpod) that returns the chosen impl based
//    on a build flag (`const bool.fromEnvironment('USE_MOCK_API')`).
// 4. Move `baseUrl` and any tokens to a config layer (dart-define or
//    flutter_dotenv). Never hardcode them at the call site.

import 'package:http/http.dart' as http;

abstract class ApiClient {
  String get baseUrl;

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? queryParams,
    Map<String, String>? headers,
  });

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, String>? headers,
    Object? body,
  });
}

class HttpApiClient implements ApiClient {
  HttpApiClient({
    required this.baseUrl,
    this.authToken,
    http.Client? client,
  }) : _client = client ?? http.Client();

  @override
  final String baseUrl;

  // ── Auth ──────────────────────────────────────────────────────────────
  // The token is held in memory only. In production this would come from
  // secure storage (flutter_secure_storage) and be refreshed on 401 via
  // a refresh-token endpoint.
  String? authToken;

  final http.Client _client;

  Map<String, String> _defaultHeaders() => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (authToken != null) 'Authorization': 'Bearer $authToken',
        // Real apps add: X-Request-Id (tracing), X-Client-Version, locale, etc.
      };

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? queryParams,
    Map<String, String>? headers,
  }) async {
    // Real implementation (left as TODO for the Django integration phase):
    //
    //   final uri = Uri.parse('$baseUrl$path').replace(queryParameters: queryParams);
    //   final mergedHeaders = {..._defaultHeaders(), ...?headers};
    //   final res = await _client.get(uri, headers: mergedHeaders).timeout(const Duration(seconds: 15));
    //   return _decode(res);
    //
    // Cross-cutting concerns to add here:
    // - Retry on 5xx with exponential backoff
    // - Centralized 401 handling -> trigger logout via AuthProvider
    // - Structured logging / Sentry breadcrumbs
    final _ = _defaultHeaders(); // ensures the helper stays referenced
    throw UnimplementedError(
      'HttpApiClient.get not yet wired — using MockApiService. path=$path',
    );
  }

  @override
  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    // TODO: implement — see notes on get().
    final _ = _defaultHeaders();
    throw UnimplementedError(
      'HttpApiClient.post not yet wired — using MockApiService. path=$path',
    );
  }

  // Reserved for the real implementation: decode body, surface API errors
  // as typed exceptions (NetworkException, AuthException, ValidationException).
  //
  // Map<String, dynamic> _decode(http.Response res) { ... }

  void dispose() => _client.close();
}
