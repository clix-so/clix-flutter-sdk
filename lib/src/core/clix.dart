import 'dart:async';

import 'clix_config.dart';
import 'clix_version.dart';
import '../services/platform_service.dart';
import '../services/storage_service.dart';
import '../models/clix_push_notification_payload.dart';
import '../utils/clix_error.dart';
import '../utils/clix_log_level.dart';
import '../utils/logger.dart';

typedef NotificationHandler = void Function(ClixPushNotificationPayload payload);

/// Main Clix SDK class matching iOS SDK interface
/// Provides static methods for all public APIs
class Clix {
  static Clix? _shared;
  static bool _isInitializing = false;
  static final _initializationCompleter = Completer<void>();

  final ClixConfig _config;
  final StorageService _storage;
  
  // Notification handlers
  static NotificationHandler? _notificationReceivedHandler;
  static NotificationHandler? _notificationTappedHandler;

  Clix._({
    required ClixConfig config,
    required StorageService storage,
  }) : _config = config,
       _storage = storage;

  /// Initialize Clix SDK (async version - recommended)
  static Future<void> initialize(ClixConfig config) async {
    if (_shared != null) {
      ClixLogger.warning('Clix is already initialized');
      return;
    }

    if (_isInitializing) {
      await _initializationCompleter.future;
      return;
    }

    _isInitializing = true;

    try {
      ClixLogger.setLogLevel(config.logLevel);
      ClixLogger.info('Initializing Clix SDK v${ClixVersion.version}');

      // Initialize storage
      final storage = StorageService();
      await storage.initialize();

      // Initialize platform service with config
      await PlatformService.initialize(
        projectId: config.projectId,
        apiKey: config.apiKey,
      );

      // Start listening to platform events
      await PlatformService.startListening();

      final instance = Clix._(
        config: config,
        storage: storage,
      );

      await instance._setupPushMessaging();

      _shared = instance;
      _initializationCompleter.complete();

      ClixLogger.info('Clix SDK initialized successfully');
    } catch (e, stackTrace) {
      _initializationCompleter.completeError(e);
      ClixLogger.error('Failed to initialize Clix SDK', e, stackTrace);
      rethrow;
    } finally {
      _isInitializing = false;
    }
  }

  /// Initialize Clix SDK (sync version - fire and forget)
  static void initializeSync(ClixConfig config) {
    initialize(config).catchError((e, stackTrace) {
      ClixLogger.error('Failed to initialize Clix SDK (sync)', e, stackTrace);
    });
  }

  /// Wait for initialization to complete (used internally by other methods)
  static Future<void> _waitForInitialization() async {
    if (_shared != null) return;
    if (_isInitializing) {
      await _initializationCompleter.future;
      return;
    }
    throw ClixError.notInitialized;
  }

  /// Get shared instance with timeout for sync methods
  static Clix? _getShared({Duration? timeout}) {
    if (_shared != null) return _shared;

    if (timeout != null && _isInitializing) {
      // For sync methods, wait briefly for initialization
      try {
        _initializationCompleter.future.timeout(timeout);
        return _shared;
      } catch (_) {
        return null;
      }
    }

    return null;
  }

  // MARK: - User Management (Static API)

  /// Set user ID (async version - recommended)
  static Future<void> setUserId(String userId) async {
    await _waitForInitialization();
    await PlatformService.setUserId(userId);
    await _shared!._storage.setString('userId', userId);
  }

  /// Set user ID (sync version - fire and forget)
  static void setUserIdSync(String userId) {
    final instance = _getShared(timeout: const Duration(milliseconds: 100));
    if (instance != null) {
      PlatformService.setUserId(userId).catchError((e, stackTrace) {
        ClixLogger.error('Failed to set user ID (sync)', e, stackTrace);
      });
      instance._storage.setString('userId', userId).catchError((e, stackTrace) {
        ClixLogger.error('Failed to save user ID (sync)', e, stackTrace);
      });
    } else {
      ClixLogger.warning('Clix not initialized, cannot set user ID');
    }
  }

  /// Remove user ID (async version - recommended)
  static Future<void> removeUserId() async {
    await _waitForInitialization();
    await PlatformService.removeUserId();
    await _shared!._storage.remove('userId');
  }

  /// Remove user ID (sync version - fire and forget)
  static void removeUserIdSync() {
    final instance = _getShared(timeout: const Duration(milliseconds: 100));
    if (instance != null) {
      PlatformService.removeUserId().catchError((e, stackTrace) {
        ClixLogger.error('Failed to remove user ID (sync)', e, stackTrace);
      });
      instance._storage.remove('userId').catchError((e, stackTrace) {
        ClixLogger.error('Failed to remove user ID from storage (sync)', e, stackTrace);
      });
    } else {
      ClixLogger.warning('Clix not initialized, cannot remove user ID');
    }
  }

  // MARK: - User Properties (Static API)

  /// Set user property (async version - recommended)
  static Future<void> setUserProperty(String key, dynamic value) async {
    await _waitForInitialization();
    await PlatformService.setUserProperty(key, value);
  }

  /// Set user property (sync version - fire and forget)
  static void setUserPropertySync(String key, dynamic value) {
    final instance = _getShared(timeout: const Duration(milliseconds: 100));
    if (instance != null) {
      PlatformService.setUserProperty(key, value).catchError((e, stackTrace) {
        ClixLogger.error('Failed to set user property (sync)', e, stackTrace);
      });
    } else {
      ClixLogger.warning('Clix not initialized, cannot set user property');
    }
  }

  /// Set multiple user properties (async version - recommended)
  static Future<void> setUserProperties(Map<String, dynamic> userProperties) async {
    await _waitForInitialization();
    await PlatformService.setUserProperties(userProperties);
  }

  /// Set multiple user properties (sync version - fire and forget)
  static void setUserPropertiesSync(Map<String, dynamic> userProperties) {
    final instance = _getShared(timeout: const Duration(milliseconds: 100));
    if (instance != null) {
      PlatformService.setUserProperties(userProperties).catchError((e, stackTrace) {
        ClixLogger.error('Failed to set user properties (sync)', e, stackTrace);
      });
    } else {
      ClixLogger.warning('Clix not initialized, cannot set user properties');
    }
  }

  /// Remove user property (async version - recommended)
  static Future<void> removeUserProperty(String key) async {
    await _waitForInitialization();
    await PlatformService.removeUserProperty(key);
  }

  /// Remove user property (sync version - fire and forget)
  static void removeUserPropertySync(String key) {
    final instance = _getShared(timeout: const Duration(milliseconds: 100));
    if (instance != null) {
      PlatformService.removeUserProperty(key).catchError((e, stackTrace) {
        ClixLogger.error('Failed to remove user property (sync)', e, stackTrace);
      });
    } else {
      ClixLogger.warning('Clix not initialized, cannot remove user property');
    }
  }

  /// Remove multiple user properties (async version - recommended)
  static Future<void> removeUserProperties(List<String> keys) async {
    await _waitForInitialization();
    await PlatformService.removeUserProperties(keys);
  }

  /// Remove multiple user properties (sync version - fire and forget)
  static void removeUserPropertiesSync(List<String> keys) {
    final instance = _getShared(timeout: const Duration(milliseconds: 100));
    if (instance != null) {
      PlatformService.removeUserProperties(keys).catchError((e, stackTrace) {
        ClixLogger.error('Failed to remove user properties (sync)', e, stackTrace);
      });
    } else {
      ClixLogger.warning('Clix not initialized, cannot remove user properties');
    }
  }

  // MARK: - Device Information (Static API)

  /// Get device ID (async version - recommended)
  static Future<String?> getDeviceId() async {
    await _waitForInitialization();
    return PlatformService.getDeviceId();
  }

  /// Get device ID (sync version with timeout protection)
  static String? getDeviceIdSync() {
    final instance = _getShared(timeout: const Duration(milliseconds: 100));
    if (instance != null) {
      // Return cached device ID if available
      return instance._storage.getString('deviceId');
    }
    return null;
  }

  /// Get push token (async version - recommended)
  static Future<String?> getPushToken() async {
    await _waitForInitialization();
    return PlatformService.getPushToken();
  }

  /// Get push token (sync version with timeout protection)
  static String? getPushTokenSync() {
    final instance = _getShared(timeout: const Duration(milliseconds: 100));
    if (instance != null) {
      // Return cached push token if available
      return instance._storage.getString('pushToken');
    }
    return null;
  }

  // MARK: - Logging (Static API)

  /// Set log level
  static void setLogLevel(ClixLogLevel level) {
    ClixLogger.setLogLevel(level);
    PlatformService.setLogLevel(level.index).catchError((e) {
      ClixLogger.error('Failed to set log level on platform', e);
    });
  }

  // MARK: - Notification Handling (Static API)

  /// Set notification received handler
  static void setNotificationReceivedHandler(NotificationHandler? handler) {
    _notificationReceivedHandler = handler;
  }

  /// Set notification tapped handler
  static void setNotificationTappedHandler(NotificationHandler? handler) {
    _notificationTappedHandler = handler;
  }

  /// Get notification received stream
  static Stream<ClixPushNotificationPayload>? get onNotificationReceived {
    return PlatformService.onForegroundNotification;
  }

  /// Get notification tapped stream
  static Stream<ClixPushNotificationPayload>? get onNotificationTapped {
    return PlatformService.onNotificationTapped;
  }

  // MARK: - Push Notification Management

  /// Set push token
  static Future<void> setPushToken(String token) async {
    await _waitForInitialization();
    await _shared!._storage.setString('pushToken', token);
  }

  /// Get shared instance (for internal use)
  static Clix get instance {
    if (_shared == null) {
      throw ClixError.notInitialized;
    }
    return _shared!;
  }

  // MARK: - Internal Methods

  Future<void> _setupPushMessaging() async {
    try {
      // Get initial token
      final token = await PlatformService.getPushToken();
      if (token != null) {
        await _storage.setString('pushToken', token);
      }

      // Get device ID and cache it
      final deviceId = await PlatformService.getDeviceId();
      if (deviceId != null) {
        await _storage.setString('deviceId', deviceId);
      }

      // Set up token refresh handler
      PlatformService.onTokenRefresh.listen((token) async {
        await _storage.setString('pushToken', token);
      });

      // Set up notification handlers
      PlatformService.onForegroundNotification.listen((payload) {
        ClixLogger.info('Received foreground notification: ${payload.messageId}');
        _notificationReceivedHandler?.call(payload);
      });

      PlatformService.onNotificationTapped.listen((payload) {
        ClixLogger.info('Notification tapped: ${payload.messageId}');
        _notificationTappedHandler?.call(payload);
      });

    } catch (e, stackTrace) {
      ClixLogger.error('Failed to setup Push Messaging', e, stackTrace);
    }
  }

  // MARK: - Utility Methods

  /// Check if SDK is initialized
  static bool get isInitialized => _shared != null;

  /// Dispose SDK (for testing purposes)
  static void dispose() {
    PlatformService.dispose();
    _shared = null;
  }
}