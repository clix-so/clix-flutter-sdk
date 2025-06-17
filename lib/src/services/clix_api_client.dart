import 'dart:convert';

import '../core/clix_config.dart';
import '../core/clix_version.dart';
import '../utils/logger.dart';
import '../utils/http_client.dart';

/// Base API client for Clix services
/// Handles authentication headers and base URL configuration
class ClixAPIClient {
  final ClixConfig _config;
  final ClixHttpClient _httpClient;

  ClixAPIClient({
    required ClixConfig config,
    ClixHttpClient? httpClient,
  })  : _config = config,
        _httpClient = httpClient ?? ClixHttpClient();

  /// Get common headers for all API requests
  Map<String, String> get _commonHeaders {
    final headers = <String, String>{
      'X-Clix-Project-ID': _config.projectId,
      'X-Clix-API-Key': _config.apiKey,
      'User-Agent': 'Clix-Flutter-SDK/${ClixVersion.version}',
    };

    // Add extra headers if provided
    if (_config.extraHeaders != null) {
      headers.addAll(_config.extraHeaders!);
    }

    return headers;
  }

  /// Build full URL from endpoint path
  String _buildUrl(String path) {
    final baseUrl = _config.endpoint.endsWith('/')
        ? _config.endpoint.substring(0, _config.endpoint.length - 1)
        : _config.endpoint;

    // Add /api/v1 prefix to match iOS SDK structure
    const apiBasePath = '/api/v1';
    final fullPath = path.startsWith('/') ? path : '/$path';
    return '$baseUrl$apiBasePath$fullPath';
  }

  /// Perform GET request with authentication
  Future<HttpResponse<T>> get<T>(
    String path, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    final url = _buildUrl(path);
    final requestHeaders = <String, String>{
      ..._commonHeaders,
      if (headers != null) ...headers,
    };

    ClixLogger.debug('API GET $path');

    return _httpClient.get<T>(
      url,
      headers: requestHeaders,
      queryParameters: queryParameters,
      fromJson: fromJson,
    );
  }

  /// Perform POST request with authentication
  Future<HttpResponse<T>> post<T>(
    String path, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    dynamic body,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    final url = _buildUrl(path);
    final requestHeaders = <String, String>{
      ..._commonHeaders,
      if (headers != null) ...headers,
    };

    ClixLogger.debug('API POST $path');
    if (body != null) {
      ClixLogger.debug('Request Body: ${jsonEncode(body)}');
    }
    if (queryParameters?.isNotEmpty == true) {
      ClixLogger.debug('Query Parameters: $queryParameters');
    }

    final response = await _httpClient.post<T>(
      url,
      headers: requestHeaders,
      queryParameters: queryParameters,
      body: body,
      fromJson: fromJson,
    );

    ClixLogger.debug('Response Status: ${response.statusCode}');
    if (response.data != null) {
      ClixLogger.debug('Response Body: ${jsonEncode(response.data)}');
    }

    return response;
  }

  /// Perform PUT request with authentication
  Future<HttpResponse<T>> put<T>(
    String path, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    dynamic body,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    final url = _buildUrl(path);
    final requestHeaders = <String, String>{
      ..._commonHeaders,
      if (headers != null) ...headers,
    };

    ClixLogger.debug('API PUT $path');

    return _httpClient.put<T>(
      url,
      headers: requestHeaders,
      queryParameters: queryParameters,
      body: body,
      fromJson: fromJson,
    );
  }

  /// Perform DELETE request with authentication
  Future<HttpResponse<T>> delete<T>(
    String path, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    final url = _buildUrl(path);
    final requestHeaders = <String, String>{
      ..._commonHeaders,
      if (headers != null) ...headers,
    };

    ClixLogger.debug('API DELETE $path');

    return _httpClient.delete<T>(
      url,
      headers: requestHeaders,
      queryParameters: queryParameters,
      fromJson: fromJson,
    );
  }

  /// Close the underlying HTTP client
  void close() {
    _httpClient.close();
  }
}
