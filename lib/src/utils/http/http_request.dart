import 'http_method.dart';

/// HTTP request structure that mirrors the iOS SDK HTTPRequest implementation
class HTTPRequest {
  final Uri url;
  final HTTPMethod method;
  final Map<String, String>? headers;
  final Map<String, dynamic>? params;
  final Map<String, dynamic>? body;

  const HTTPRequest({
    required this.url,
    required this.method,
    this.headers,
    this.params,
    this.body,
  });
}