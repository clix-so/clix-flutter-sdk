import 'clix_log_level.dart';

/// ClixLogger that mirrors the iOS SDK ClixLogger implementation
class ClixLogger {
  static ClixLogLevel _logLevel = ClixLogLevel.info;
  static final _dateFormatter = DateTime.now;

  /// Set the logging level
  static void setLogLevel(ClixLogLevel level) {
    _logLevel = level;
  }

  /// Log a message at the specified level
  static void log({required ClixLogLevel level, required String message, Object? error}) {
    if (level < _logLevel) {
      return;
    }

    final timestamp = _dateFormatter().toIso8601String();
    var logMessage = '[Clix][$timestamp] $message';
    if (error != null) {
      logMessage += ' - Error: $error';
    }

    switch (level) {
      case ClixLogLevel.debug:
        print('[DEBUG] $logMessage');
        break;
      case ClixLogLevel.info:
        print('[INFO] $logMessage');
        break;
      case ClixLogLevel.warn:
        print('[WARN] $logMessage');
        break;
      case ClixLogLevel.error:
        print('[ERROR] $logMessage');
        break;
      case ClixLogLevel.none:
        return;
    }
  }

  /// Log error message
  static void error(String message, [Object? error]) {
    log(level: ClixLogLevel.error, message: message, error: error);
  }

  /// Log warning message
  static void warn(String message, [Object? error]) {
    log(level: ClixLogLevel.warn, message: message, error: error);
  }

  /// Log info message
  static void info(String message, [Object? error]) {
    log(level: ClixLogLevel.info, message: message, error: error);
  }

  /// Log debug message
  static void debug(String message, [Object? error]) {
    log(level: ClixLogLevel.debug, message: message, error: error);
  }
}