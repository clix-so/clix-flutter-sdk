import 'dart:developer' as dev;
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'clix_log_level.dart';

/// Enhanced Clix Logger for structured logging with multiple outputs
class ClixLogger {
  static ClixLogLevel _currentLogLevel = ClixLogLevel.info;
  static bool _enableFileLogging = false;
  static bool _enableRemoteLogging = false;
  static String? _logFilePath;
  static final List<Map<String, dynamic>> _logBuffer = [];
  static const int _maxBufferSize = 100;
  static void Function(Map<String, dynamic> logEntry)? _customLogHandler;
  
  /// Initialize the logger with advanced options
  static Future<void> initialize({
    ClixLogLevel logLevel = ClixLogLevel.info,
    bool enableFileLogging = false,
    bool enableRemoteLogging = false,
    String? logFilePath,
    void Function(Map<String, dynamic> logEntry)? customLogHandler,
  }) async {
    _currentLogLevel = logLevel;
    _enableFileLogging = enableFileLogging;
    _enableRemoteLogging = enableRemoteLogging;
    _logFilePath = logFilePath;
    _customLogHandler = customLogHandler;
    
    if (_enableFileLogging && _logFilePath != null) {
      await _initializeFileLogging();
    }
    
    info('Clix Logger initialized with level: ${logLevel.name}');
  }
  
  /// Set the current log level
  static void setLogLevel(ClixLogLevel level) {
    _currentLogLevel = level;
    debug('Log level changed to: ${level.name}');
  }

  static void verbose(String message, [dynamic error, StackTrace? stackTrace]) {
    _log(ClixLogLevel.verbose, message, error, stackTrace);
  }

  /// Log debug message
  static void debug(String message, [Object? error, StackTrace? stackTrace]) {
    _log(ClixLogLevel.debug, message, error, stackTrace);
  }
  
  /// Log info message
  static void info(String message, [Object? error, StackTrace? stackTrace]) {
    _log(ClixLogLevel.info, message, error, stackTrace);
  }
  
  /// Log warning message
  static void warning(String message, [Object? error, StackTrace? stackTrace]) {
    _log(ClixLogLevel.warning, message, error, stackTrace);
  }
  
  /// Log error message
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    _log(ClixLogLevel.error, message, error, stackTrace);
  }
  
  /// Log performance metrics
  static void performance(String operation, Duration duration, {
    Map<String, dynamic>? metadata,
  }) {
    final perfData = {
      'operation': operation,
      'duration_ms': duration.inMilliseconds,
      'metadata': metadata,
    };
    
    _log(
      ClixLogLevel.info,
      'Performance: $operation took ${duration.inMilliseconds}ms',
      null,
      null,
      category: 'performance',
      data: perfData,
    );
  }
  
  /// Log network requests
  static void network(String method, String url, {
    int? statusCode,
    Duration? duration,
    Map<String, String>? headers,
    String? requestBody,
    String? responseBody,
  }) {
    final networkData = {
      'method': method,
      'url': url,
      'status_code': statusCode,
      'duration_ms': duration?.inMilliseconds,
      'headers': headers,
      'request_body': requestBody,
      'response_body': responseBody,
    };
    
    final statusText = statusCode != null ? ' [$statusCode]' : '';
    final durationText = duration != null ? ' (${duration.inMilliseconds}ms)' : '';
    
    _log(
      ClixLogLevel.debug,
      'Network: $method $url$statusText$durationText',
      null,
      null,
      category: 'network',
      data: networkData,
    );
  }
  
  /// Log user events
  static void userEvent(String event, Map<String, dynamic>? properties) {
    _log(
      ClixLogLevel.info,
      'User Event: $event',
      null,
      null,
      category: 'user_event',
      data: {
        'event': event,
        'properties': properties,
      },
    );
  }
  
  /// Log push notification events
  static void pushNotification(String event, Map<String, dynamic>? payload) {
    _log(
      ClixLogLevel.info,
      'Push Notification: $event',
      null,
      null,
      category: 'push_notification',
      data: {
        'event': event,
        'payload': payload,
      },
    );
  }
  
  /// Get recent logs for debugging
  static List<Map<String, dynamic>> getRecentLogs({int? limit}) {
    final logs = List<Map<String, dynamic>>.from(_logBuffer);
    if (limit != null && limit < logs.length) {
      return logs.sublist(logs.length - limit);
    }
    return logs;
  }
  
  /// Clear log buffer
  static void clearLogs() {
    _logBuffer.clear();
    debug('Log buffer cleared');
  }
  
  /// Export logs as JSON string
  static String exportLogs() {
    return jsonEncode({
      'timestamp': DateTime.now().toIso8601String(),
      'logs': _logBuffer,
      'metadata': {
        'platform': Platform.operatingSystem,
        'version': Platform.operatingSystemVersion,
        'is_debug': kDebugMode,
      },
    });
  }
  
  static void _log(
    ClixLogLevel level,
    String message,
    Object? error,
    StackTrace? stackTrace, {
    String? category,
    Map<String, dynamic>? data,
  }) {
    if (!_currentLogLevel.shouldLog(level)) return;
    
    final timestamp = DateTime.now();
    final logEntry = {
      'timestamp': timestamp.toIso8601String(),
      'level': level.name,
      'message': message,
      'category': category ?? 'general',
      'error': error?.toString(),
      'stack_trace': stackTrace?.toString(),
      'data': data,
    };
    
    // Add to buffer
    _logBuffer.add(logEntry);
    if (_logBuffer.length > _maxBufferSize) {
      _logBuffer.removeAt(0);
    }
    
    // Console logging
    _logToConsole(level, message, error, stackTrace);
    
    // File logging
    if (_enableFileLogging) {
      _logToFile(logEntry);
    }
    
    // Remote logging
    if (_enableRemoteLogging) {
      _logToRemote(logEntry);
    }
    
    // Custom handler
    _customLogHandler?.call(logEntry);
  }
  
  static void _logToConsole(
    ClixLogLevel level,
    String message,
    Object? error,
    StackTrace? stackTrace,
  ) {
    final prefix = '[CLIX] ${level.name.toUpperCase()}';
    final timestamp = DateTime.now().toIso8601String();
    final logMessage = '$timestamp $prefix: $message';
    
    if (kDebugMode) {
      // Use dart:developer log for better debugging support
      dev.log(
        logMessage,
        name: 'Clix',
        error: error,
        stackTrace: stackTrace,
        level: _getLevelValue(level),
      );
    } else {
      // Use print for release mode if needed
      debugPrint(logMessage);
      if (error != null) debugPrint('Error: $error');
    }
  }
  
  static Future<void> _initializeFileLogging() async {
    if (_logFilePath == null) return;
    
    try {
      final file = File(_logFilePath!);
      if (!await file.exists()) {
        await file.create(recursive: true);
      }
      debug('File logging initialized: $_logFilePath');
    } catch (e) {
      error('Failed to initialize file logging: $e');
    }
  }
  
  static void _logToFile(Map<String, dynamic> logEntry) {
    if (_logFilePath == null) return;
    
    try {
      final file = File(_logFilePath!);
      final logLine = '${jsonEncode(logEntry)}\n';
      file.writeAsStringSync(logLine, mode: FileMode.append);
    } catch (e) {
      // Avoid infinite recursion by not logging this error
      if (kDebugMode) {
        print('Failed to write to log file: $e');
      }
    }
  }
  
  static void _logToRemote(Map<String, dynamic> logEntry) {
    // Implement remote logging here
    // This could send logs to a centralized logging service
    // For now, just store in buffer for later transmission
  }
  
  static int _getLevelValue(ClixLogLevel level) {
    switch (level) {
      case ClixLogLevel.verbose:
        return 400;
      case ClixLogLevel.debug:
        return 500;
      case ClixLogLevel.info:
        return 800;
      case ClixLogLevel.warning:
        return 900;
      case ClixLogLevel.error:
        return 1000;
      case ClixLogLevel.none:
        return 0;
    }
  }
}

/// Performance measurement utility
class ClixPerformanceLogger {
  static final Map<String, DateTime> _startTimes = {};
  
  /// Start measuring performance for an operation
  static void start(String operation) {
    _startTimes[operation] = DateTime.now();
  }
  
  /// End measuring and log performance
  static void end(String operation, {Map<String, dynamic>? metadata}) {
    final startTime = _startTimes.remove(operation);
    if (startTime != null) {
      final duration = DateTime.now().difference(startTime);
      ClixLogger.performance(operation, duration, metadata: metadata);
    }
  }
  
  /// Measure and log a synchronous operation
  static T measure<T>(String operation, T Function() fn, {
    Map<String, dynamic>? metadata,
  }) {
    final startTime = DateTime.now();
    try {
      final result = fn();
      final duration = DateTime.now().difference(startTime);
      ClixLogger.performance(operation, duration, metadata: metadata);
      return result;
    } catch (e) {
      final duration = DateTime.now().difference(startTime);
      ClixLogger.performance(operation, duration, metadata: {
        ...metadata ?? {},
        'error': e.toString(),
      });
      rethrow;
    }
  }
  
  /// Measure and log an asynchronous operation
  static Future<T> measureAsync<T>(String operation, Future<T> Function() fn, {
    Map<String, dynamic>? metadata,
  }) async {
    final startTime = DateTime.now();
    try {
      final result = await fn();
      final duration = DateTime.now().difference(startTime);
      ClixLogger.performance(operation, duration, metadata: metadata);
      return result;
    } catch (e) {
      final duration = DateTime.now().difference(startTime);
      ClixLogger.performance(operation, duration, metadata: {
        ...metadata ?? {},
        'error': e.toString(),
      });
      rethrow;
    }
  }
}