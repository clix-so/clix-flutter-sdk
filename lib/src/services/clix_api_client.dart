import 'dart:convert';
import 'package:http/http.dart' as http;

import '../core/clix_config.dart';
import '../core/clix_version.dart';
import '../utils/logging/clix_logger.dart';

class ClixAPIClient {
  final ClixConfig _config;
  final http.Client _httpClient;

  ClixAPIClient({
    required ClixConfig config,
    http.Client? httpClient,
  })  : _config = config,
        _httpClient = httpClient ?? http.Client();

  Future<Map<String, String>> get _commonHeaders async {
    final version = await ClixVersion.version;
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'X-Clix-Project-ID': _config.projectId,
      'X-Clix-API-Key': _config.apiKey,
      'User-Agent': 'Clix-Flutter-SDK/$version',
    };

    if (_config.extraHeaders != null) {
      headers.addAll(_config.extraHeaders!);
    }

    return headers;
  }

  String _buildUrl(String path) {
    final baseUrl = _config.endpoint.endsWith('/')
        ? _config.endpoint.substring(0, _config.endpoint.length - 1)
        : _config.endpoint;

    const apiBasePath = '/api/v1';
    final fullPath = path.startsWith('/') ? path : '/$path';
    return '$baseUrl$apiBasePath$fullPath';
  }

  Uri _buildUri(String path, Map<String, dynamic>? queryParameters) {
    final url = _buildUrl(path);
    final uri = Uri.parse(url);
    
    if (queryParameters != null && queryParameters.isNotEmpty) {
      return uri.replace(queryParameters: queryParameters.map((key, value) => MapEntry(key, value.toString())));
    }
    
    return uri;
  }

  Future<http.Response> get(
    String path, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
  }) async {
    final uri = _buildUri(path, queryParameters);
    final commonHeaders = await _commonHeaders;
    final requestHeaders = <String, String>{
      ...commonHeaders,
      if (headers != null) ...headers,
    };

    ClixLogger.debug('API GET $path');
    ClixLogger.debug('Making request to: $uri');

    final response = await _httpClient.get(uri, headers: requestHeaders);
    
    ClixLogger.debug('Response Status: ${response.statusCode}');
    ClixLogger.debug('Response Body: ${response.body}');
    
    return response;
  }

  Future<http.Response> post(
    String path, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    dynamic body,
  }) async {
    final uri = _buildUri(path, queryParameters);
    final commonHeaders = await _commonHeaders;
    final requestHeaders = <String, String>{
      ...commonHeaders,
      if (headers != null) ...headers,
    };

    ClixLogger.debug('API POST $path');
    if (body != null) {
      ClixLogger.debug('Request Body: ${jsonEncode(body)}');
    }
    if (queryParameters?.isNotEmpty == true) {
      ClixLogger.debug('Query Parameters: $queryParameters');
    }

    final encodedBody = body != null ? jsonEncode(body) : null;
    
    final response = await _httpClient.post(
      uri,
      headers: requestHeaders,
      body: encodedBody,
    );

    ClixLogger.debug('Response Status: ${response.statusCode}');
    ClixLogger.debug('Response Body: ${response.body}');

    return response;
  }

  Future<http.Response> put(
    String path, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    dynamic body,
  }) async {
    final uri = _buildUri(path, queryParameters);
    final commonHeaders = await _commonHeaders;
    final requestHeaders = <String, String>{
      ...commonHeaders,
      if (headers != null) ...headers,
    };

    ClixLogger.debug('API PUT $path');

    final encodedBody = body != null ? jsonEncode(body) : null;
    
    final response = await _httpClient.put(
      uri,
      headers: requestHeaders,
      body: encodedBody,
    );

    ClixLogger.debug('Response Status: ${response.statusCode}');
    ClixLogger.debug('Response Body: ${response.body}');

    return response;
  }

  Future<http.Response> delete(
    String path, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
  }) async {
    final uri = _buildUri(path, queryParameters);
    final commonHeaders = await _commonHeaders;
    final requestHeaders = <String, String>{
      ...commonHeaders,
      if (headers != null) ...headers,
    };

    ClixLogger.debug('API DELETE $path');

    final response = await _httpClient.delete(uri, headers: requestHeaders);

    ClixLogger.debug('Response Status: ${response.statusCode}');
    ClixLogger.debug('Response Body: ${response.body}');

    return response;
  }

  void close() {
    _httpClient.close();
  }
}