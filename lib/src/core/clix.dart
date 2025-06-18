import 'dart:async';

import 'clix_config.dart';
import '../services/storage_service.dart';
import '../services/clix_api_client.dart';
import '../services/device_service.dart';
import '../services/device_api_service.dart';
import '../services/event_service.dart';
import '../services/event_api_service.dart';
import '../services/notification_service.dart';
import '../services/firebase_service.dart';
import '../utils/clix_error.dart';
import '../utils/logging/clix_log_level.dart';
import '../utils/logging/clix_logger.dart';

/// Main Clix SDK class that mirrors the iOS SDK Clix implementation
/// All public methods are static, with async versions as primary interface
class Clix {
  static Clix? _shared;
  static bool _isInitializing = false;
  static final _initCompleter = Completer<void>();

  // Services - nullable until initialization
  StorageService? _storageService;
  EventService? _eventService;
  DeviceService? _deviceService;
  NotificationService? _notificationService;
  FirebaseService? _firebaseService;

  Clix._();

  /// Initialize Clix SDK (async version - recommended)
  static Future<void> initialize(ClixConfig config) async {
    if (_shared != null) {
      ClixLogger.warn('Clix is already initialized');
      return;
    }

    if (_isInitializing) {
      await _initCompleter.future;
      return;
    }

    _isInitializing = true;

    try {
      ClixLogger.setLogLevel(config.logLevel);
      ClixLogger.info('Initializing Clix SDK');

      final instance = Clix._();
      await instance._setConfig(config);

      _shared = instance;
      _initCompleter.complete();

      ClixLogger.info('Clix SDK initialized successfully');
    } catch (e) {
      _initCompleter.completeError(e);
      ClixLogger.error('Failed to initialize Clix SDK', e);
      rethrow;
    } finally {
      _isInitializing = false;
    }
  }

  /// Initialize Clix SDK (sync version - fire and forget)
  static void initializeSync(ClixConfig config) {
    initialize(config).catchError((e) {
      ClixLogger.error('Failed to initialize Clix SDK (sync)', e);
    });
  }

  /// Set configuration - mirrors iOS setConfig method
  Future<void> _setConfig(ClixConfig config) async {
    // Initialize storage service
    _storageService = StorageService();
    await _storageService!.initialize();

    // Store configuration
    await _storageService!.setString('project_id', config.projectId);
    await _storageService!.setString('api_key', config.apiKey);

    // Initialize API client
    final apiClient = ClixAPIClient(config: config);

    // Initialize API services
    final deviceAPIService = DeviceAPIService(apiClient: apiClient);
    final eventAPIService = EventAPIService(apiClient: apiClient);

    // Initialize device service
    _deviceService = DeviceService(
      deviceAPIService: deviceAPIService,
      storage: _storageService!,
    );
    
    // Initialize device service
    await _deviceService!.initialize();

    // Initialize event service
    _eventService = EventService(
      eventAPIService: eventAPIService,
      deviceService: _deviceService!,
    );

    // Initialize notification service
    _notificationService = NotificationService(
      eventService: _eventService!,
      storageService: _storageService!,
    );

    // Initialize Firebase service
    _firebaseService = FirebaseService();
    await _firebaseService!.initialize(
      storageService: _storageService!,
      onPushReceived: (data) => _notificationService!.handlePushReceived(data),
      onPushTapped: (data) => _notificationService!.handlePushTapped(data),
    );
  }

  /// Wait for initialization with timeout protection
  static Future<void> _waitForInitialization() async {
    if (_shared != null) return;
    if (_isInitializing) {
      await _initCompleter.future;
      return;
    }
    throw ClixError.notInitialized;
  }

  /// Get shared instance with timeout protection (for sync methods)
  static Clix? _getSharedWithTimeout() {
    if (_shared != null) return _shared;
    
    if (_isInitializing) {
      try {
        // Wait briefly for initialization (like iOS 500ms timeout)
        _initCompleter.future.timeout(const Duration(milliseconds: 500));
        return _shared;
      } catch (_) {
        ClixLogger.warn('Clix not yet initialized, cannot complete sync operation');
        return null;
      }
    }
    
    ClixLogger.warn('Clix not initialized, call Clix.initialize() first');
    return null;
  }

  // MARK: - User Management

  /// Set user ID (async version - recommended)
  static Future<void> setUserId(String userId) async {
    await _waitForInitialization();
    try {
      await _shared!._deviceService!.setUserId(userId);
    } catch (e) {
      throw ClixError.unknownErrorWithReason('Failed to set user ID: $e');
    }
  }

  /// Set user ID (sync version - fire and forget)
  static void setUserIdSync(String userId) {
    final instance = _getSharedWithTimeout();
    if (instance != null) {
      instance._deviceService!.setUserId(userId).catchError((e) {
        ClixLogger.error('Failed to set user ID (sync)', e);
      });
    }
  }

  /// Remove user ID (async version - recommended)
  static Future<void> removeUserId() async {
    await _waitForInitialization();
    try {
      await _shared!._deviceService!.removeUserId();
    } catch (e) {
      throw ClixError.unknownErrorWithReason('Failed to remove user ID: $e');
    }
  }

  /// Remove user ID (sync version - fire and forget)
  static void removeUserIdSync() {
    final instance = _getSharedWithTimeout();
    if (instance != null) {
      instance._deviceService!.removeUserId().catchError((e) {
        ClixLogger.error('Failed to remove user ID (sync)', e);
      });
    }
  }

  // MARK: - User Properties

  /// Set user property (async version - recommended)
  static Future<void> setUserProperty(String key, dynamic value) async {
    await _waitForInitialization();
    try {
      await _shared!._deviceService!.setUserProperty(key, value);
    } catch (e) {
      throw ClixError.unknownErrorWithReason('Failed to set user property: $e');
    }
  }

  /// Set user property (sync version - fire and forget)
  static void setUserPropertySync(String key, dynamic value) {
    final instance = _getSharedWithTimeout();
    if (instance != null) {
      instance._deviceService!.setUserProperty(key, value).catchError((e) {
        ClixLogger.error('Failed to set user property (sync)', e);
      });
    }
  }

  /// Set multiple user properties (async version - recommended)
  static Future<void> setUserProperties(Map<String, dynamic> userProperties) async {
    await _waitForInitialization();
    try {
      await _shared!._deviceService!.setUserProperties(userProperties);
    } catch (e) {
      throw ClixError.unknownErrorWithReason('Failed to set user properties: $e');
    }
  }

  /// Set multiple user properties (sync version - fire and forget)
  static void setUserPropertiesSync(Map<String, dynamic> userProperties) {
    final instance = _getSharedWithTimeout();
    if (instance != null) {
      instance._deviceService!.setUserProperties(userProperties).catchError((e) {
        ClixLogger.error('Failed to set user properties (sync)', e);
      });
    }
  }

  /// Remove user property (async version - recommended)
  static Future<void> removeUserProperty(String key) async {
    await _waitForInitialization();
    try {
      await _shared!._deviceService!.removeUserProperty(key);
    } catch (e) {
      throw ClixError.unknownErrorWithReason('Failed to remove user property: $e');
    }
  }

  /// Remove user property (sync version - fire and forget)
  static void removeUserPropertySync(String key) {
    final instance = _getSharedWithTimeout();
    if (instance != null) {
      instance._deviceService!.removeUserProperty(key).catchError((e) {
        ClixLogger.error('Failed to remove user property (sync)', e);
      });
    }
  }

  /// Remove multiple user properties (async version - recommended)
  static Future<void> removeUserProperties(List<String> keys) async {
    await _waitForInitialization();
    try {
      await _shared!._deviceService!.removeUserProperties(keys);
    } catch (e) {
      throw ClixError.unknownErrorWithReason('Failed to remove user properties: $e');
    }
  }

  /// Remove multiple user properties (sync version - fire and forget)
  static void removeUserPropertiesSync(List<String> keys) {
    final instance = _getSharedWithTimeout();
    if (instance != null) {
      instance._deviceService!.removeUserProperties(keys).catchError((e) {
        ClixLogger.error('Failed to remove user properties (sync)', e);
      });
    }
  }

  // MARK: - Device Information

  /// Get device ID (async version - recommended)
  static Future<String?> getDeviceId() async {
    await _waitForInitialization();
    return _shared!._deviceService!.getDeviceId();
  }

  /// Get device ID (sync version with timeout protection)
  static String? getDeviceIdSync() {
    final instance = _getSharedWithTimeout();
    return instance?._deviceService?.getDeviceId();
  }

  /// Get push token (async version - recommended)
  static Future<String?> getPushToken() async {
    await _waitForInitialization();
    return _shared!._firebaseService!.getCurrentToken();
  }

  /// Get push token (sync version with timeout protection)
  static String? getPushTokenSync() {
    final instance = _getSharedWithTimeout();
    return instance?._firebaseService?.currentToken;
  }

  // MARK: - Logging

  /// Set log level - mirrors iOS setLogLevel method
  static void setLogLevel(ClixLogLevel level) {
    ClixLogger.setLogLevel(level);
  }

  // MARK: - Internal Event Tracking (mirrors iOS internal trackEvent)

  /// Track event internally - used by notification service
  static void trackEvent(
    String name, {
    Map<String, dynamic>? properties,
    String? messageId,
  }) {
    final instance = _getSharedWithTimeout();
    if (instance != null) {
      instance._eventService!.trackEvent(
        name,
        properties: properties,
        messageId: messageId,
      ).catchError((e) {
        ClixLogger.error('Failed to track internal event', e);
      });
    }
  }

  // MARK: - Utility Methods

  /// Check if SDK is initialized
  static bool get isInitialized => _shared != null;
}