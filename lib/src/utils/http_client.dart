import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'logger.dart';
import 'clix_error.dart';

/// HTTP method enumeration
enum HttpMethod { get, post, put, delete }

/// HTTP request model
class HttpRequest {
  final String url;
  final HttpMethod method;
  final Map<String, String>? headers;
  final Map<String, dynamic>? queryParameters;
  final dynamic body;

  const HttpRequest({
    required this.url,
    required this.method,
    this.headers,
    this.queryParameters,
    this.body,
  });
}

/// HTTP response model
class HttpResponse<T> {
  final T data;
  final int statusCode;
  final Map<String, String> headers;

  const HttpResponse({
    required this.data,
    required this.statusCode,
    required this.headers,
  });

  bool get isSuccess => statusCode >= 200 && statusCode < 300;
}

/// HTTP client for Clix API requests
class ClixHttpClient {
  final Duration _timeout;
  final http.Client _client;

  ClixHttpClient({
    Duration timeout = const Duration(seconds: 30),
  })  : _timeout = timeout,
        _client = http.Client();

  /// Perform HTTP request with automatic JSON handling
  Future<HttpResponse<T>> request<T>(
    HttpRequest request, {
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      ClixLogger.debug(
          'HTTP ${request.method.name.toUpperCase()} ${request.url}');

      final uri = _buildUri(request.url, request.queryParameters);
      final headers = _buildHeaders(request.headers);

      late http.Response response;

      switch (request.method) {
        case HttpMethod.get:
          response = await _client.get(uri, headers: headers).timeout(_timeout);
          break;
        case HttpMethod.post:
          response = await _client
              .post(
                uri,
                headers: headers,
                body: _encodeBody(request.body),
              )
              .timeout(_timeout);
          break;
        case HttpMethod.put:
          response = await _client
              .put(
                uri,
                headers: headers,
                body: _encodeBody(request.body),
              )
              .timeout(_timeout);
          break;
        case HttpMethod.delete:
          response =
              await _client.delete(uri, headers: headers).timeout(_timeout);
          break;
      }

      ClixLogger.debug('HTTP ${response.statusCode} ${request.url}');

      if (!_isSuccessStatusCode(response.statusCode)) {
        ClixLogger.error('HTTP request failed: ${request.url}');
        ClixLogger.error('Response status: ${response.statusCode}');
        ClixLogger.error('Response body: ${response.body}');
        throw ClixError.now(
          code: 'HTTP_ERROR',
          message: 'HTTP request failed with status ${response.statusCode}',
          details: response.body,
        );
      }

      final data = _decodeResponse<T>(response, fromJson);

      return HttpResponse<T>(
        data: data,
        statusCode: response.statusCode,
        headers: response.headers,
      );
    } on TimeoutException catch (e) {
      ClixLogger.error('HTTP request timeout: ${request.url}', e);
      throw ClixError.timeoutError;
    } on SocketException catch (e) {
      ClixLogger.error('Network error: ${request.url}', e);
      throw ClixError.networkError;
    } catch (e) {
      ClixLogger.error('HTTP request failed: ${request.url}', e);
      if (e is ClixError) rethrow;
      throw ClixError.now(
        code: 'HTTP_ERROR',
        message: 'HTTP request failed: $e',
        details: e,
      );
    }
  }

  /// Perform GET request
  Future<HttpResponse<T>> get<T>(
    String url, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    return request<T>(
      HttpRequest(
        url: url,
        method: HttpMethod.get,
        headers: headers,
        queryParameters: queryParameters,
      ),
      fromJson: fromJson,
    );
  }

  /// Perform POST request
  Future<HttpResponse<T>> post<T>(
    String url, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    dynamic body,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    return request<T>(
      HttpRequest(
        url: url,
        method: HttpMethod.post,
        headers: headers,
        queryParameters: queryParameters,
        body: body,
      ),
      fromJson: fromJson,
    );
  }

  /// Perform PUT request
  Future<HttpResponse<T>> put<T>(
    String url, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    dynamic body,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    return request<T>(
      HttpRequest(
        url: url,
        method: HttpMethod.put,
        headers: headers,
        queryParameters: queryParameters,
        body: body,
      ),
      fromJson: fromJson,
    );
  }

  /// Perform DELETE request
  Future<HttpResponse<T>> delete<T>(
    String url, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    return request<T>(
      HttpRequest(
        url: url,
        method: HttpMethod.delete,
        headers: headers,
        queryParameters: queryParameters,
      ),
      fromJson: fromJson,
    );
  }

  /// Download file from URL
  Future<List<int>> downloadFile(String url) async {
    try {
      ClixLogger.debug('Downloading file: $url');

      final response = await _client.get(Uri.parse(url)).timeout(_timeout);

      if (!_isSuccessStatusCode(response.statusCode)) {
        throw ClixError.now(
          code: 'DOWNLOAD_ERROR',
          message: 'Failed to download file: ${response.statusCode}',
        );
      }

      return response.bodyBytes;
    } catch (e) {
      ClixLogger.error('File download failed: $url', e);
      if (e is ClixError) rethrow;
      throw ClixError.now(
        code: 'DOWNLOAD_ERROR',
        message: 'File download failed: $e',
      );
    }
  }

  /// Close the HTTP client
  void close() {
    _client.close();
  }

  // Private helper methods

  Uri _buildUri(String url, Map<String, dynamic>? queryParameters) {
    final uri = Uri.parse(url);
    if (queryParameters == null || queryParameters.isEmpty) {
      return uri;
    }

    final params =
        queryParameters.map((key, value) => MapEntry(key, value.toString()));

    return uri.replace(queryParameters: params);
  }

  Map<String, String> _buildHeaders(Map<String, String>? headers) {
    final defaultHeaders = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (headers != null) {
      defaultHeaders.addAll(headers);
    }

    return defaultHeaders;
  }

  String? _encodeBody(dynamic body) {
    if (body == null) return null;
    if (body is String) return body;
    if (body is Map || body is List) {
      try {
        return jsonEncode(body);
      } catch (e) {
        throw ClixError.encodingError;
      }
    }
    return body.toString();
  }

  T _decodeResponse<T>(
      http.Response response, T Function(Map<String, dynamic>)? fromJson) {
    if (response.body.isEmpty) {
      return {} as T;
    }

    try {
      final decoded = jsonDecode(response.body);

      if (fromJson != null && decoded is Map<String, dynamic>) {
        return fromJson(decoded);
      }

      return decoded as T;
    } catch (e) {
      ClixLogger.error('Failed to decode response', e);
      throw ClixError.decodingError;
    }
  }

  bool _isSuccessStatusCode(int statusCode) {
    return statusCode >= 200 && statusCode < 300;
  }
}
