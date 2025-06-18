import 'dart:convert';

import '../core/clix_config.dart';
import '../core/clix_version.dart';
import '../utils/logging/clix_logger.dart';
import '../utils/http/http_client.dart';
import '../utils/http/http_method.dart';
import '../utils/http/http_request.dart';
import '../utils/http/http_response.dart';

/// Base API client for Clix services
/// Handles authentication headers and base URL configuration
class ClixAPIClient {
  final ClixConfig _config;
  final HTTPClient _httpClient;

  ClixAPIClient({
    required ClixConfig config,
    HTTPClient? httpClient,
  })  : _config = config,
        _httpClient = httpClient ?? HTTPClient.shared;

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
  Future<HTTPResponse<T>> get<T>(
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

    final request = HTTPRequest(
      method: HTTPMethod.get,
      url: Uri.parse(url),
      headers: requestHeaders,
      params: queryParameters,
    );

    ClixLogger.debug('Making request to: $url');
    return await _httpClient.request(request) as HTTPResponse<T>;
  }

  /// Perform POST request with authentication
  Future<HTTPResponse<T>> post<T>(
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

    final request = HTTPRequest(
      method: HTTPMethod.post,
      url: Uri.parse(url),
      headers: requestHeaders,
      params: queryParameters,
      body: body,
    );

    ClixLogger.debug('Making request to: $url');
    final response = await _httpClient.request(request);

    ClixLogger.debug('Response Status: ${response.statusCode}');
    ClixLogger.debug('Response Body: ${response.data}');

    return response as HTTPResponse<T>;
  }

  /// Perform PUT request with authentication
  Future<HTTPResponse<T>> put<T>(
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

    final request = HTTPRequest(
      method: HTTPMethod.put,
      url: Uri.parse(url),
      headers: requestHeaders,
      params: queryParameters,
      body: body,
    );

    ClixLogger.debug('Making request to: $url');
    return await _httpClient.request(request) as HTTPResponse<T>;
  }

  /// Perform DELETE request with authentication
  Future<HTTPResponse<T>> delete<T>(
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

    final request = HTTPRequest(
      method: HTTPMethod.delete,
      url: Uri.parse(url),
      headers: requestHeaders,
      params: queryParameters,
    );

    ClixLogger.debug('Making request to: $url');
    return await _httpClient.request(request) as HTTPResponse<T>;
  }

  /// Close the underlying HTTP client
  void close() {
    // HTTPClient.shared doesn't need to be closed
  }
}
