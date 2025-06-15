import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'clix_config.dart';
import 'clix_environment.dart';
import 'clix_version.dart';
import 'clix_app_delegate.dart';
import '../services/storage_service.dart';
import '../services/device_service.dart';
import '../services/event_service.dart';
import '../services/notification_service.dart';
import '../services/token_service.dart';
import '../services/clix_api_client.dart';
import '../services/device_api_service.dart';
import '../services/event_api_service.dart';
import '../models/clix_push_notification_payload.dart';
import '../utils/clix_error.dart';
import '../utils/clix_log_level.dart';
import '../utils/logger.dart';

typedef NotificationHandler = void Function(ClixPushNotificationPayload payload);

/// Main Clix SDK class matching iOS SDK interface
/// Provides static methods for all public APIs
final class Clix {
  static Clix? _shared;
  static bool _isInitializing = false;
  static final _initializationCompleter = Completer<void>();

  // These fields are used for dependency injection and are required for the SDK to function properly
  @pragma('vm:prefer-inline')
  final ClixConfig _config;
  @pragma('vm:prefer-inline')
  final ClixEnvironment _environment;
  @pragma('vm:prefer-inline')
  final StorageService _storage;
  final ClixAPIClient _apiClient;
  @pragma('vm:prefer-inline')
  final DeviceAPIService _deviceAPIService;
  @pragma('vm:prefer-inline')
  final EventAPIService _eventAPIService;
  final TokenService _tokenService;
  final DeviceService _deviceService;
  final EventService _eventService;
  final NotificationService _notificationService;

  Clix._({
    required ClixConfig config,
    required ClixEnvironment environment,
    required StorageService storage,
    required ClixAPIClient apiClient,
    required DeviceAPIService deviceAPIService,
    required EventAPIService eventAPIService,
    required TokenService tokenService,
    required DeviceService deviceService,
    required EventService eventService,
    required NotificationService notificationService,
  }) : _config = config,
       _environment = environment,
       _storage = storage,
       _apiClient = apiClient,
       _deviceAPIService = deviceAPIService,
       _eventAPIService = eventAPIService,
       _tokenService = tokenService,
       _deviceService = deviceService,
       _eventService = eventService,
       _notificationService = notificationService;

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

      // Create environment
      final environment = ClixEnvironment.current();

      // Initialize ClixAppDelegate
      await ClixAppDelegate.initialize();

      // Initialize services in dependency order
      final storage = StorageService();
      await storage.initialize();

      final apiClient = ClixAPIClient(
        config: config,
        environment: environment,
      );

      final deviceAPIService = DeviceAPIService(apiClient: apiClient);
      final eventAPIService = EventAPIService(apiClient: apiClient);

      final tokenService = TokenService(storage: storage);
      await tokenService.initialize();

      final deviceService = DeviceService(
        deviceAPIService: deviceAPIService,
        storage: storage,
        environment: environment,
      );
      await deviceService.initialize();

      final eventService = EventService(
        eventAPIService: eventAPIService,
        deviceService: deviceService,
      );

      final notificationService = NotificationService(
        eventService: eventService,
      );

      final instance = Clix._(
        config: config,
        environment: environment,
        storage: storage,
        apiClient: apiClient,
        deviceAPIService: deviceAPIService,
        eventAPIService: eventAPIService,
        tokenService: tokenService,
        deviceService: deviceService,
        eventService: eventService,
        notificationService: notificationService,
      );

      await instance._setupFirebaseMessaging();

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
    await _shared!._deviceService.setUserId(userId);
  }

  /// Set user ID (sync version - fire and forget)
  static void setUserIdSync(String userId) {
    final instance = _getShared(timeout: const Duration(milliseconds: 100));
    if (instance != null) {
      instance._deviceService.setUserId(userId).catchError((e, stackTrace) {
        ClixLogger.error('Failed to set user ID (sync)', e, stackTrace);
      });
    } else {
      ClixLogger.warning('Clix not initialized, cannot set user ID');
    }
  }

  /// Remove user ID (async version - recommended)
  static Future<void> removeUserId() async {
    await _waitForInitialization();
    await _shared!._deviceService.removeUserId();
  }

  /// Remove user ID (sync version - fire and forget)
  static void removeUserIdSync() {
    final instance = _getShared(timeout: const Duration(milliseconds: 100));
    if (instance != null) {
      instance._deviceService.removeUserId().catchError((e, stackTrace) {
        ClixLogger.error('Failed to remove user ID (sync)', e, stackTrace);
      });
    } else {
      ClixLogger.warning('Clix not initialized, cannot remove user ID');
    }
  }

  // MARK: - User Properties (Static API)

  /// Set user property (async version - recommended)
  static Future<void> setUserProperty(String key, dynamic value) async {
    await _waitForInitialization();
    await _shared!._deviceService.setUserProperty(key, value);
  }

  /// Set user property (sync version - fire and forget)
  static void setUserPropertySync(String key, dynamic value) {
    final instance = _getShared(timeout: const Duration(milliseconds: 100));
    if (instance != null) {
      instance._deviceService.setUserProperty(key, value).catchError((e, stackTrace) {
        ClixLogger.error('Failed to set user property (sync)', e, stackTrace);
      });
    } else {
      ClixLogger.warning('Clix not initialized, cannot set user property');
    }
  }

  /// Set multiple user properties (async version - recommended)
  static Future<void> setUserProperties(Map<String, dynamic> userProperties) async {
    await _waitForInitialization();
    await _shared!._deviceService.setUserProperties(userProperties);
  }

  /// Set multiple user properties (sync version - fire and forget)
  static void setUserPropertiesSync(Map<String, dynamic> userProperties) {
    final instance = _getShared(timeout: const Duration(milliseconds: 100));
    if (instance != null) {
      instance._deviceService.setUserProperties(userProperties).catchError((e, stackTrace) {
        ClixLogger.error('Failed to set user properties (sync)', e, stackTrace);
      });
    } else {
      ClixLogger.warning('Clix not initialized, cannot set user properties');
    }
  }

  /// Remove user property (async version - recommended)
  static Future<void> removeUserProperty(String key) async {
    await _waitForInitialization();
    await _shared!._deviceService.removeUserProperty(key);
  }

  /// Remove user property (sync version - fire and forget)
  static void removeUserPropertySync(String key) {
    final instance = _getShared(timeout: const Duration(milliseconds: 100));
    if (instance != null) {
      instance._deviceService.removeUserProperty(key).catchError((e, stackTrace) {
        ClixLogger.error('Failed to remove user property (sync)', e, stackTrace);
      });
    } else {
      ClixLogger.warning('Clix not initialized, cannot remove user property');
    }
  }

  /// Remove multiple user properties (async version - recommended)
  static Future<void> removeUserProperties(List<String> keys) async {
    await _waitForInitialization();
    await _shared!._deviceService.removeUserProperties(keys);
  }

  /// Remove multiple user properties (sync version - fire and forget)
  static void removeUserPropertiesSync(List<String> keys) {
    final instance = _getShared(timeout: const Duration(milliseconds: 100));
    if (instance != null) {
      instance._deviceService.removeUserProperties(keys).catchError((e, stackTrace) {
        ClixLogger.error('Failed to remove user properties (sync)', e, stackTrace);
      });
    } else {
      ClixLogger.warning('Clix not initialized, cannot remove user properties');
    }
  }

  // MARK: - Event Tracking (Static API)

  /// Track event (async version - recommended)
  static Future<void> trackEvent(String name, {Map<String, dynamic>? properties}) async {
    await _waitForInitialization();
    await _shared!._eventService.trackEvent(name, properties: properties);
  }

  /// Track event (sync version - fire and forget)
  static void trackEventSync(String name, {Map<String, dynamic>? properties}) {
    final instance = _getShared(timeout: const Duration(milliseconds: 100));
    if (instance != null) {
      instance._eventService.trackEvent(name, properties: properties).catchError((e, stackTrace) {
        ClixLogger.error('Failed to track event (sync)', e, stackTrace);
      });
    } else {
      ClixLogger.warning('Clix not initialized, cannot track event');
    }
  }

  // MARK: - Device Information (Static API)

  /// Get device ID (async version - recommended)
  static Future<String?> getDeviceId() async {
    await _waitForInitialization();
    return _shared!._deviceService.deviceId;
  }

  /// Get device ID (sync version with timeout protection)
  static String? getDeviceIdSync() {
    final instance = _getShared(timeout: const Duration(milliseconds: 100));
    return instance?._deviceService.deviceId;
  }

  /// Get push token (async version - recommended)
  static Future<String?> getPushToken() async {
    await _waitForInitialization();
    return _shared!._deviceService.pushToken;
  }

  /// Get push token (sync version with timeout protection)
  static String? getPushTokenSync() {
    final instance = _getShared(timeout: const Duration(milliseconds: 100));
    return instance?._deviceService.pushToken;
  }

  // MARK: - Logging (Static API)

  /// Set log level
  static void setLogLevel(ClixLogLevel level) {
    ClixLogger.setLogLevel(level);
  }

  // MARK: - Notification Handling (Static API)

  /// Set notification received handler
  static void setNotificationReceivedHandler(NotificationHandler? handler) {
    final instance = _getShared();
    if (instance != null) {
      instance._notificationService.setReceivedHandler(handler);
    } else {
      ClixLogger.warning('Clix not initialized, cannot set notification handler');
    }
  }

  /// Set notification tapped handler
  static void setNotificationTappedHandler(NotificationHandler? handler) {
    final instance = _getShared();
    if (instance != null) {
      instance._notificationService.setTappedHandler(handler);
    } else {
      ClixLogger.warning('Clix not initialized, cannot set notification handler');
    }
  }

  /// Get notification received stream
  static Stream<ClixPushNotificationPayload>? get onNotificationReceived {
    final instance = _getShared();
    return instance?._notificationService.onNotificationReceived;
  }

  /// Get notification tapped stream
  static Stream<ClixPushNotificationPayload>? get onNotificationTapped {
    final instance = _getShared();
    return instance?._notificationService.onNotificationTapped;
  }

  // MARK: - Internal Methods

  Future<void> _setupFirebaseMessaging() async {
    try {
      final token = await ClixAppDelegate.getToken();
      if (token != null) {
        await _tokenService.updateToken(token, 'FCM');
        await _deviceService.updatePushToken(token, 'FCM');
      }

      // Set up token refresh handler
      ClixAppDelegate.setTokenRefreshHandler((token) async {
        await _tokenService.updateToken(token, 'FCM');
        await _deviceService.updatePushToken(token, 'FCM');
      });

      // Set up message handlers
      ClixAppDelegate.setForegroundMessageHandler(_handleForegroundMessage);
      ClixAppDelegate.setBackgroundMessageHandler(_handleMessageOpenedApp);
      await ClixAppDelegate.handleInitialMessage(_handleMessageOpenedApp);

    } catch (e, stackTrace) {
      ClixLogger.error('Failed to setup Firebase Messaging', e, stackTrace);
    }
  }

  void _handleForegroundMessage(ClixPushNotificationPayload payload) {
    ClixLogger.info('Received foreground message: ${payload.messageId}');
    _notificationService.handleNotificationReceived(payload);
  }

  void _handleMessageOpenedApp(ClixPushNotificationPayload payload) {
    ClixLogger.info('Message opened app: ${payload.messageId}');
    _notificationService.handleNotificationTapped(payload);
  }

  // MARK: - Utility Methods

  /// Check if SDK is initialized
  static bool get isInitialized => _shared != null;

  /// Dispose SDK (for testing purposes)
  static void dispose() {
    _shared?._apiClient.dispose();
    _shared?._notificationService.dispose();
    _shared = null;
  }
}
