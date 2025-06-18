import 'dart:convert';
import 'dart:io';
import '../clix_error.dart';
import 'http_method.dart';
import 'http_request.dart';
import 'http_response.dart';

/// HTTP client that mirrors the iOS SDK HTTPClient implementation using Dart's built-in HttpClient
class HTTPClient {
  static HTTPClient get shared => _instance;
  static final HTTPClient _instance = HTTPClient._internal();

  final HttpClient _client;

  HTTPClient._internal() : _client = HttpClient();

  HTTPClient.withClient(this._client);

  Map<String, String> _buildRequestHeaders(Map<String, String>? headers) {
    final result = <String, String>{'Content-Type': 'application/json'};
    headers?.forEach((key, value) => result[key] = value);
    return result;
  }

  Uri _buildRequestURL(Uri url, Map<String, dynamic>? params) {
    if (params == null || params.isEmpty) {
      return url;
    }
    
    final queryParams = params.map((key, value) => MapEntry(key, value.toString()));
    return url.replace(queryParameters: {...url.queryParameters, ...queryParams});
  }

  Future<HTTPResponse<T>> request<T>(HTTPRequest request) async {
    try {
      final finalURL = _buildRequestURL(request.url, request.params);
      final headers = _buildRequestHeaders(request.headers);
      
      late HttpClientRequest clientRequest;
      
      switch (request.method) {
        case HTTPMethod.get:
          clientRequest = await _client.getUrl(finalURL);
          break;
        case HTTPMethod.post:
          clientRequest = await _client.postUrl(finalURL);
          break;
        case HTTPMethod.put:
          clientRequest = await _client.putUrl(finalURL);
          break;
        case HTTPMethod.delete:
          clientRequest = await _client.deleteUrl(finalURL);
          break;
      }

      // Set headers
      headers.forEach((key, value) {
        clientRequest.headers.set(key, value);
      });

      // Add body for POST/PUT requests
      if (request.body != null && 
          (request.method == HTTPMethod.post || request.method == HTTPMethod.put)) {
        final bodyData = jsonEncode(request.body);
        clientRequest.write(bodyData);
      }

      final response = await clientRequest.close();
      final responseBody = await response.transform(utf8.decoder).join();
      
      final responseHeaders = <String, String>{};
      response.headers.forEach((name, values) {
        responseHeaders[name] = values.join(', ');
      });

      return HTTPResponse<T>(
        statusCode: response.statusCode,
        data: responseBody,
        headers: responseHeaders,
      );
    } catch (e) {
      throw ClixError.networkError(e.toString());
    }
  }

  void close() {
    _client.close();
  }
}