import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/clix_config.dart';
import '../core/clix_environment.dart';
import '../utils/clix_error.dart';
import '../utils/logger.dart';

class ClixAPIClient {
  final ClixConfig _config;
  final ClixEnvironment _environment;
  final http.Client _httpClient;

  ClixAPIClient({
    required ClixConfig config,
    required ClixEnvironment environment,
  }) : _config = config,
       _environment = environment,
       _httpClient = http.Client();

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
  }) async {
    return _request('POST', path, body: body, queryParams: queryParams);
  }

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? queryParams,
  }) async {
    return _request('GET', path, queryParams: queryParams);
  }

  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
  }) async {
    return _request('PUT', path, body: body, queryParams: queryParams);
  }

  Future<void> delete(
    String path, {
    Map<String, String>? queryParams,
  }) async {
    await _request('DELETE', path, queryParams: queryParams);
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
  }) async {
    try {
      final uri = _buildUri(path, queryParams);
      final headers = _buildHeaders();

      ClixLogger.verbose('$method $uri');
      if (body != null) {
        ClixLogger.verbose('Request body: ${jsonEncode(body)}');
      }

      late http.Response response;

      switch (method) {
        case 'GET':
          response = await _httpClient.get(uri, headers: headers);
          break;
        case 'POST':
          response = await _httpClient.post(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'PUT':
          response = await _httpClient.put(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'DELETE':
          response = await _httpClient.delete(uri, headers: headers);
          break;
        default:
          throw ClixError.invalidURL;
      }

      ClixLogger.verbose('Response status: ${response.statusCode}');
      ClixLogger.verbose('Response body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty) {
          return {};
        }
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw ClixError.networkError;
      }
    } catch (e) {
      ClixLogger.error('API request failed: $method $path', e);
      if (e is ClixError) {
        rethrow;
      }
      throw ClixError.networkError;
    }
  }

  Uri _buildUri(String path, Map<String, String>? queryParams) {
    final uri = Uri.parse('${_config.endpoint}$path');
    if (queryParams != null && queryParams.isNotEmpty) {
      return uri.replace(queryParameters: queryParams);
    }
    return uri;
  }

  Map<String, String> _buildHeaders() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'X-Clix-Project-Id': _config.projectId,
      'X-Clix-API-Key': _config.apiKey,
      'X-Clix-SDK-Type': _environment.sdkType,
      'X-Clix-SDK-Version': _environment.sdkVersion,
      'X-Clix-App-Identifier': _environment.appIdentifier,
      'X-Clix-App-Name': _environment.appName,
      'X-Clix-App-Version': _environment.appVersion,
    };

    // Add extra headers if available
    if (_config.extraHeaders != null) {
      _config.extraHeaders!.forEach((key, value) {
        headers[key] = value;
      });
    }

    return headers;
  }

  void dispose() {
    _httpClient.close();
  }
}
