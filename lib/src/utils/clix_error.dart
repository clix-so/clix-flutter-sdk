enum ClixError implements Exception {
  notInitialized('Clix SDK has not been initialized'),
  invalidConfiguration('Invalid configuration provided'),
  invalidURL('Invalid URL'),
  invalidResponse('Invalid response from server'),
  networkError('Network request failed'),
  encodingError('Failed to encode request data'),
  decodingError('Failed to decode response data'),
  timeoutError('Request timed out'),
  unknownError('Unknown error occurred');

  const ClixError(this.message);
  
  final String message;

  @override
  String toString() => 'ClixError: $message';
}