import 'dart:developer' as developer;
import 'clix_log_level.dart';

class ClixLogger {
  static ClixLogLevel _logLevel = ClixLogLevel.info;

  static void setLogLevel(ClixLogLevel level) {
    _logLevel = level;
  }

  static void log({required ClixLogLevel level, required String message, Object? error}) {
    if (level > _logLevel) {
      return;
    }

    final timestamp = DateTime.now().toIso8601String();
    var logMessage = '[Clix][$timestamp] $message';
    if (error != null) {
      logMessage += ' - Error: $error';
    }

    switch (level) {
      case ClixLogLevel.debug:
        developer.log('[DEBUG]$logMessage', name: 'Clix');
        break;
      case ClixLogLevel.info:
        developer.log('[INFO]$logMessage', name: 'Clix');
        break;
      case ClixLogLevel.warn:
        developer.log('[WARN]$logMessage', name: 'Clix');
        break;
      case ClixLogLevel.error:
        developer.log('[ERROR]$logMessage', name: 'Clix', error: error);
        break;
      case ClixLogLevel.none:
        return;
    }
  }

  static void error(String message, [Object? error]) {
    log(level: ClixLogLevel.error, message: message, error: error);
  }

  static void warn(String message, [Object? error]) {
    log(level: ClixLogLevel.warn, message: message, error: error);
  }

  static void info(String message, [Object? error]) {
    log(level: ClixLogLevel.info, message: message, error: error);
  }

  static void debug(String message, [Object? error]) {
    log(level: ClixLogLevel.debug, message: message, error: error);
  }
}