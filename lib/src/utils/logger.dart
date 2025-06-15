import 'package:flutter/foundation.dart';
import 'clix_log_level.dart';

class ClixLogger {
  static ClixLogLevel _logLevel = ClixLogLevel.error;

  static void setLogLevel(ClixLogLevel level) {
    _logLevel = level;
  }

  static void verbose(String message, [dynamic error, StackTrace? stackTrace]) {
    _log(ClixLogLevel.verbose, message, error, stackTrace);
  }

  static void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    _log(ClixLogLevel.debug, message, error, stackTrace);
  }

  static void info(String message, [dynamic error, StackTrace? stackTrace]) {
    _log(ClixLogLevel.info, message, error, stackTrace);
  }

  static void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    _log(ClixLogLevel.warning, message, error, stackTrace);
  }

  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _log(ClixLogLevel.error, message, error, stackTrace);
  }

  static void _log(ClixLogLevel level, String message, dynamic error, StackTrace? stackTrace) {
    if (!_logLevel.shouldLog(level)) return;

    final timestamp = DateTime.now().toIso8601String();
    final levelStr = level.name.toUpperCase();
    final logMessage = '[$timestamp] [Clix] [$levelStr] $message';

    if (kDebugMode) {
      debugPrint(logMessage);
      if (error != null) {
        debugPrint('Error: $error');
      }
      if (stackTrace != null) {
        debugPrint('StackTrace: $stackTrace');
      }
    }
  }
}