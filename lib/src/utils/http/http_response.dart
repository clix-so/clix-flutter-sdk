/// HTTP response structure that mirrors the iOS SDK HTTPResponse implementation
class HTTPResponse<T> {
  final int statusCode;
  final String data;
  final Map<String, String> headers;

  const HTTPResponse({
    required this.statusCode,
    required this.data,
    required this.headers,
  });

  bool get isSuccess => statusCode >= 200 && statusCode < 300;
}