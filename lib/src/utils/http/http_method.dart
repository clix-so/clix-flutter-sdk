/// HTTP methods enum that mirrors the iOS SDK HTTPMethod implementation
enum HTTPMethod {
  get('GET'),
  post('POST'),
  put('PUT'),
  delete('DELETE');

  const HTTPMethod(this.value);

  final String value;
}