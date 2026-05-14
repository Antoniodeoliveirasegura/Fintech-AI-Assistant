import 'dart:convert';

import 'package:http/http.dart' as http;
import '../utils/app_config.dart';
import '../utils/app_logger.dart';

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

class ApiException implements Exception {
  final int? statusCode;
  final String message;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() =>
      statusCode == null ? message : 'HTTP $statusCode: $message';
}

class HttpApiClient implements ApiClient {
  HttpApiClient({String? baseUrl, this.authToken, http.Client? client})
    : baseUrl = baseUrl ?? AppConfig.apiBaseUrl,
      _client = client ?? http.Client();

  @override
  final String baseUrl;

  String? authToken;
  final http.Client _client;

  Map<String, String> _defaultHeaders() => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (authToken != null) 'Authorization': 'Bearer $authToken',
  };

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? queryParams,
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse(
      '$baseUrl$path',
    ).replace(queryParameters: queryParams);
    final response = await _client
        .get(uri, headers: {..._defaultHeaders(), ...?headers})
        .timeout(const Duration(seconds: 15));

    AppLogger.debug('GET $path -> ${response.statusCode}', scope: 'api');
    return _decode(response);
  }

  @override
  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await _client
        .post(
          uri,
          headers: {..._defaultHeaders(), ...?headers},
          body: body == null ? null : jsonEncode(body),
        )
        .timeout(const Duration(seconds: 15));

    AppLogger.debug('POST $path -> ${response.statusCode}', scope: 'api');
    return _decode(response);
  }

  Map<String, dynamic> _decode(http.Response response) {
    final statusCode = response.statusCode;
    final decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;

    if (statusCode >= 200 && statusCode < 300) return decoded;

    final message =
        decoded['message'] as String? ??
        decoded['detail'] as String? ??
        'Request failed';
    throw ApiException(message, statusCode: statusCode);
  }

  void dispose() => _client.close();
}
