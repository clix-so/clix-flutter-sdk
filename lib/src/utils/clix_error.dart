/// ClixError enum that mirrors the iOS SDK ClixError implementation
enum ClixError implements Exception {
  notInitialized('Clix SDK is not initialized. Call Clix.initialize() first.'),
  invalidConfiguration('Invalid SDK configuration.'),
  invalidURL('The provided URL is invalid.'),
  invalidResponse('The response was invalid or permission was denied.'),
  encodingError('Failed to encode request body.'),
  unknownError('An unknown error occurred.');

  const ClixError(this.message);

  final String message;

  /// Creates a ClixError for network errors with underlying error
  static ClixErrorWithCause networkError(String underlyingError) {
    return ClixErrorWithCause._('Network request failed: $underlyingError');
  }

  /// Creates a ClixError for decoding errors with underlying error
  static ClixErrorWithCause decodingError(String underlyingError) {
    return ClixErrorWithCause._('Failed to decode response body: $underlyingError');
  }

  /// Creates a ClixError for unknown errors with custom reason
  static ClixErrorWithCause unknownErrorWithReason(String reason) {
    return ClixErrorWithCause._('An unknown error occurred: $reason');
  }

  @override
  String toString() => message;
}

/// ClixError variant that includes underlying cause information
class ClixErrorWithCause implements Exception {
  final String message;

  ClixErrorWithCause._(this.message);

  @override
  String toString() => message;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ClixErrorWithCause && other.message == message;
  }

  @override
  int get hashCode => message.hashCode;
}