/// Comprehensive error class for Clix SDK
class ClixError implements Exception {
  /// Error code for categorization
  final String code;
  
  /// Human-readable error message
  final String message;
  
  /// Additional error details
  final dynamic details;
  
  /// Context where the error occurred
  final String? context;
  
  /// Timestamp when error occurred
  final DateTime timestamp;
  
  /// Whether this error is recoverable
  final bool recoverable;
  
  ClixError({
    required this.code,
    required this.message,
    this.details,
    this.context,
    DateTime? timestamp,
    this.recoverable = false,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Create ClixError with current timestamp
  factory ClixError.now({
    required String code,
    required String message,
    dynamic details,
    String? context,
    bool recoverable = false,
  }) {
    return ClixError(
      code: code,
      message: message,
      details: details,
      context: context,
      timestamp: DateTime.now(),
      recoverable: recoverable,
    );
  }

  // Predefined error types
  static ClixError get notInitialized => ClixError.now(
    code: 'NOT_INITIALIZED',
    message: 'Clix SDK has not been initialized',
  );

  static ClixError get invalidConfiguration => ClixError.now(
    code: 'INVALID_CONFIGURATION',
    message: 'Invalid configuration provided',
  );

  static ClixError get invalidURL => ClixError.now(
    code: 'INVALID_URL',
    message: 'Invalid URL',
  );

  static ClixError get invalidResponse => ClixError.now(
    code: 'INVALID_RESPONSE',
    message: 'Invalid response from server',
    recoverable: true,
  );

  static ClixError get networkError => ClixError.now(
    code: 'NETWORK_ERROR',
    message: 'Network request failed',
    recoverable: true,
  );

  static ClixError get encodingError => ClixError.now(
    code: 'ENCODING_ERROR',
    message: 'Failed to encode request data',
  );

  static ClixError get decodingError => ClixError.now(
    code: 'DECODING_ERROR',
    message: 'Failed to decode response data',
  );

  static ClixError get timeoutError => ClixError.now(
    code: 'TIMEOUT_ERROR',
    message: 'Request timed out',
    recoverable: true,
  );

  static ClixError get unknownError => ClixError.now(
    code: 'UNKNOWN_ERROR',
    message: 'Unknown error occurred',
  );

  /// Convert to map for serialization
  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'message': message,
      'details': details,
      'context': context,
      'timestamp': timestamp.toIso8601String(),
      'recoverable': recoverable,
    };
  }

  /// Create from map
  factory ClixError.fromMap(Map<String, dynamic> map) {
    return ClixError(
      code: map['code'] ?? 'UNKNOWN_ERROR',
      message: map['message'] ?? 'Unknown error occurred',
      details: map['details'],
      context: map['context'],
      timestamp: map['timestamp'] != null 
        ? DateTime.parse(map['timestamp'])
        : DateTime.now(),
      recoverable: map['recoverable'] ?? false,
    );
  }

  /// Convert to JSON string
  String toJson() {
    return '{"code":"$code","message":"$message","timestamp":"${timestamp.toIso8601String()}"}';
  }

  @override
  String toString() {
    final contextStr = context != null ? ' (context: $context)' : '';
    return 'ClixError[$code]: $message$contextStr';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ClixError &&
        other.code == code &&
        other.message == message &&
        other.context == context;
  }

  @override
  int get hashCode => code.hashCode ^ message.hashCode ^ context.hashCode;
}