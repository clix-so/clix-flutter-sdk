/// The log level for Clix that mirrors the iOS SDK ClixLogLevel implementation
enum ClixLogLevel {
  /// No logs.
  none(0),
  /// Error logs.
  error(1),
  /// Warning logs.
  warn(2),
  /// Info logs.
  info(3),
  /// Debug logs.
  debug(4);

  const ClixLogLevel(this.value);

  final int value;

  /// Check if this level should log at the given level
  bool shouldLog(ClixLogLevel level) {
    return value >= level.value;
  }

  /// Comparison operators
  bool operator <(ClixLogLevel other) => value < other.value;
  bool operator <=(ClixLogLevel other) => value <= other.value;
  bool operator >(ClixLogLevel other) => value > other.value;
  bool operator >=(ClixLogLevel other) => value >= other.value;
}
