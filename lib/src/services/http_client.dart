import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/clix_config.dart';
import '../core/clix_environment.dart';
import '../core/clix_version.dart';
import '../utils/logger.dart';

class ClixHttpException implements Exception {
  final int statusCode;
  final String message;
  final String? body;
  final Uri? uri;

  const ClixHttpException({
    required this.statusCode,
    required this.message,
    this.body,
    this.uri,
  });

  @override
  String toString() => 'ClixHttpException($statusCode): $message';
}

class ClixHttpClient {
  static const String _apiVersion = '/api/v1';
  static const Duration _defaultTimeout = Duration(seconds: 30);
  static const int _maxRetries = 3;
  
  final ClixConfig _config;
  final ClixEnvironment _environment;
  final http.Client _httpClient;
  final Duration _timeout;

  ClixHttpClient({
    required ClixConfig config,
    required ClixEnvironment environment,
    http.Client? httpClient,
    Duration? timeout,
  })  : _config = config,
        _environment = environment,
        _httpClient = httpClient ?? http.Client(),
        _timeout = timeout ?? _defaultTimeout;

  Map<String, String> get _defaultHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-Clix-Project-ID': _config.projectId,
        'X-Clix-API-Key': _config.apiKey,
        'X-Clix-App-Identifier': _environment.appIdentifier,
        'User-Agent': 'clix-flutter-sdk@${ClixVersion.version}',
        ..._config.extraHeaders ?? {},
      };

  Uri _buildUri(String path, [Map<String, String>? queryParams]) {
    final endpoint = '${_config.endpoint}$_apiVersion$path';
    return Uri.parse(endpoint).replace(queryParameters: queryParams);
  }

  Future<T> _executeRequest<T>(
    Future<http.Response> Function() request, {
    required T Function(Map<String, dynamic>) parser,
    int retryCount = 0,
  }) async {
    try {
      final response = await request().timeout(_timeout);
      
      ClixLogger.debug('Response status: ${response.statusCode}');
      ClixLogger.verbose('Response body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty) {
          return parser({});
        }
        
        final Map<String, dynamic> data;
        try {
          data = jsonDecode(response.body) as Map<String, dynamic>;
        } catch (e) {
          throw ClixHttpException(
            statusCode: response.statusCode,
            message: 'Invalid JSON response',
            body: response.body,
            uri: response.request?.url,
          );
        }
        
        return parser(data);
      } else if (_shouldRetry(response.statusCode) && retryCount < _maxRetries) {
        ClixLogger.warning(
          'Request failed with ${response.statusCode}, retrying... '
          '(${retryCount + 1}/$_maxRetries)'
        );
        await Future.delayed(Duration(seconds: retryCount + 1));
        return _executeRequest(
          request,
          parser: parser,
          retryCount: retryCount + 1,
        );
      } else {
        throw ClixHttpException(
          statusCode: response.statusCode,
          message: 'HTTP request failed',
          body: response.body,
          uri: response.request?.url,
        );
      }
    } on TimeoutException catch (e) {
      if (retryCount < _maxRetries) {
        ClixLogger.warning(
          'Request timeout, retrying... (${retryCount + 1}/$_maxRetries)'
        );
        await Future.delayed(Duration(seconds: retryCount + 1));
        return _executeRequest(
          request,
          parser: parser,
          retryCount: retryCount + 1,
        );
      }
      ClixLogger.error('Request timeout after $_maxRetries retries', e);
      rethrow;
    } catch (e, stackTrace) {
      ClixLogger.error('HTTP request failed', e, stackTrace);
      rethrow;
    }
  }

  bool _shouldRetry(int statusCode) {
    return statusCode >= 500 || statusCode == 429; // Server errors and rate limiting
  }

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? queryParams,
    Map<String, String>? headers,
  }) async {
    final uri = _buildUri(path, queryParams);
    final requestHeaders = {..._defaultHeaders, ...?headers};
    
    ClixLogger.debug('GET ${uri.toString()}');
    
    return _executeRequest(
      () => _httpClient.get(uri, headers: requestHeaders),
      parser: (data) => data,
    );
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Object? body,
    Map<String, String>? headers,
  }) async {
    final uri = _buildUri(path);
    final requestHeaders = {..._defaultHeaders, ...?headers};
    final requestBody = body != null ? jsonEncode(body) : null;
    
    ClixLogger.debug('POST ${uri.toString()}');
    if (requestBody != null) {
      ClixLogger.verbose('Request body: $requestBody');
    }
    
    return _executeRequest(
      () => _httpClient.post(uri, headers: requestHeaders, body: requestBody),
      parser: (data) => data,
    );
  }

  Future<Map<String, dynamic>> put(
    String path, {
    Object? body,
    Map<String, String>? headers,
  }) async {
    final uri = _buildUri(path);
    final requestHeaders = {..._defaultHeaders, ...?headers};
    final requestBody = body != null ? jsonEncode(body) : null;
    
    ClixLogger.debug('PUT ${uri.toString()}');
    if (requestBody != null) {
      ClixLogger.verbose('Request body: $requestBody');
    }
    
    return _executeRequest(
      () => _httpClient.put(uri, headers: requestHeaders, body: requestBody),
      parser: (data) => data,
    );
  }

  Future<Map<String, dynamic>> delete(
    String path, {
    Map<String, String>? queryParams,
    Map<String, String>? headers,
  }) async {
    final uri = _buildUri(path, queryParams);
    final requestHeaders = {..._defaultHeaders, ...?headers};
    
    ClixLogger.debug('DELETE ${uri.toString()}');
    
    return _executeRequest(
      () => _httpClient.delete(uri, headers: requestHeaders),
      parser: (data) => data,
    );
  }

  Future<http.Response> downloadFile(String url) async {
    try {
      ClixLogger.debug('Downloading file from: $url');
      final response = await _httpClient.get(Uri.parse(url)).timeout(_timeout);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response;
      } else {
        throw ClixHttpException(
          statusCode: response.statusCode,
          message: 'Failed to download file',
          uri: Uri.parse(url),
        );
      }
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to download file', e, stackTrace);
      rethrow;
    }
  }

  void dispose() {
    _httpClient.close();
  }
}