import 'dart:async';

import 'clix_config.dart';
import 'clix_version.dart';
import '../services/platform_service.dart';
import '../services/storage_service.dart';
import '../services/clix_api_client.dart';
import '../services/device_service.dart';
import '../services/event_service.dart';
import '../services/token_service.dart';
import '../services/notification_service.dart';
import '../services/permission_service.dart';
import '../models/clix_push_notification_payload.dart';
import '../utils/clix_error.dart';
import '../utils/clix_log_level.dart';
import '../utils/logger.dart';

typedef NotificationHandler = void Function(
    ClixPushNotificationPayload payload);

/// Main Clix SDK class matching iOS SDK interface
/// Provides static methods for all public APIs
class Clix {
  static Clix? _shared;
  static bool _isInitializing = false;
  static final _initializationCompleter = Completer<void>();

  final ClixAPIClient _apiClient;
  final DeviceService _deviceService;
  final EventService _eventService;
  final TokenService _tokenService;
  final NotificationService _notificationService;

  // Notification handlers
  static NotificationHandler? _notificationReceivedHandler;
  static NotificationHandler? _notificationTappedHandler;

  Clix._({
    required ClixAPIClient apiClient,
    required DeviceService deviceService,
    required EventService eventService,
    required TokenService tokenService,
    required NotificationService notificationService,
  })  : _apiClient = apiClient,
        _deviceService = deviceService,
        _eventService = eventService,
        _tokenService = tokenService,
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

      // Initialize storage
      final storage = StorageService();
      await storage.initialize();

      // Initialize API client
      final apiClient = ClixAPIClient(config: config);

      // Initialize permission service
      final permissionService = PermissionService(storage: storage);

      // Initialize services
      final deviceService = DeviceService(
        apiClient: apiClient,
        storage: storage,
        permissionService: permissionService,
      );

      final tokenService = TokenService(storage: storage);

      final eventService = EventService(
        apiClient: apiClient,
        deviceService: deviceService,
      );

      final notificationService = NotificationService(
        eventService: eventService,
        deviceService: deviceService,
      );

      // Initialize platform service with config
      await PlatformService.initialize(
        projectId: config.projectId,
        apiKey: config.apiKey,
      );

      // Start listening to platform events
      await PlatformService.startListening();

      final instance = Clix._(
        apiClient: apiClient,
        deviceService: deviceService,
        eventService: eventService,
        tokenService: tokenService,
        notificationService: notificationService,
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
      instance._deviceService
          .setUserProperty(key, value)
          .catchError((e, stackTrace) {
        ClixLogger.error('Failed to set user property (sync)', e, stackTrace);
      });
    } else {
      ClixLogger.warning('Clix not initialized, cannot set user property');
    }
  }

  /// Set multiple user properties (async version - recommended)
  static Future<void> setUserProperties(
      Map<String, dynamic> userProperties) async {
    await _waitForInitialization();
    await _shared!._deviceService.setUserProperties(userProperties);
  }

  /// Set multiple user properties (sync version - fire and forget)
  static void setUserPropertiesSync(Map<String, dynamic> userProperties) {
    final instance = _getShared(timeout: const Duration(milliseconds: 100));
    if (instance != null) {
      instance._deviceService
          .setUserProperties(userProperties)
          .catchError((e, stackTrace) {
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
      instance._deviceService
          .removeUserProperty(key)
          .catchError((e, stackTrace) {
        ClixLogger.error(
            'Failed to remove user property (sync)', e, stackTrace);
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
      instance._deviceService
          .removeUserProperties(keys)
          .catchError((e, stackTrace) {
        ClixLogger.error(
            'Failed to remove user properties (sync)', e, stackTrace);
      });
    } else {
      ClixLogger.warning('Clix not initialized, cannot remove user properties');
    }
  }

  // MARK: - Device Information (Static API)

  /// Get device ID (async version - recommended)
  static Future<String?> getDeviceId() async {
    await _waitForInitialization();
    return _shared!._deviceService.getOrCreateDeviceId();
  }

  /// Get device ID (sync version with timeout protection)
  static String? getDeviceIdSync() {
    final instance = _getShared(timeout: const Duration(milliseconds: 100));
    if (instance != null) {
      return instance._deviceService.getDeviceId();
    }
    return null;
  }

  /// Get push token (async version - recommended)
  static Future<String?> getPushToken() async {
    await _waitForInitialization();
    return _shared!._tokenService.getCurrentToken();
  }

  /// Get push token (sync version with timeout protection)
  static String? getPushTokenSync() {
    final instance = _getShared(timeout: const Duration(milliseconds: 100));
    if (instance != null) {
      return instance._tokenService.getCurrentToken();
    }
    return null;
  }

  // MARK: - Logging (Static API)

  /// Set log level
  static void setLogLevel(ClixLogLevel level) {
    ClixLogger.setLogLevel(level);
    PlatformService.setLogLevel(level.index).catchError((e) {
      ClixLogger.error('Failed to set log level on platform', e);
      return false; // Return a value compatible with the Future<bool> return type
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

  // MARK: - Event Tracking (Static API)

  /// Track custom event
  static Future<void> trackEvent(
    String eventName, {
    Map<String, dynamic>? properties,
  }) async {
    await _waitForInitialization();
    await _shared!._eventService.trackEvent(eventName, properties: properties);
  }

  /// Track custom event (sync version - fire and forget)
  static void trackEventSync(
    String eventName, {
    Map<String, dynamic>? properties,
  }) {
    final instance = _getShared(timeout: const Duration(milliseconds: 100));
    if (instance != null) {
      instance._eventService
          .trackEvent(eventName, properties: properties)
          .catchError((e, stackTrace) {
        ClixLogger.error('Failed to track event (sync)', e, stackTrace);
      });
    } else {
      ClixLogger.warning('Clix not initialized, cannot track event');
    }
  }

  /// Track purchase event
  static Future<void> trackPurchase({
    required String productId,
    required double amount,
    required String currency,
    Map<String, dynamic>? properties,
  }) async {
    await _waitForInitialization();
    await _shared!._eventService.trackPurchase(
      productId: productId,
      amount: amount,
      currency: currency,
      properties: properties,
    );
  }

  /// Track screen view event
  static Future<void> trackScreenView(
    String screenName, {
    Map<String, dynamic>? properties,
  }) async {
    await _waitForInitialization();
    await _shared!._eventService
        .trackScreenView(screenName, properties: properties);
  }

  // MARK: - Push Notification Management

  /// Set push token
  static Future<void> setPushToken(String token) async {
    await _waitForInitialization();
    await _shared!._tokenService.setCurrentToken(token);
    await _shared!._deviceService.updatePushToken(token);
  }

  // MARK: - Push Notification Permission Management

  /// Request notification permissions (async version - recommended)
  /// Returns true if permission was granted, false otherwise
  static Future<bool> requestNotificationPermissions() async {
    await _waitForInitialization();
    return await _shared!._deviceService.requestNotificationPermissions();
  }

  /// Check if notification permissions are granted (async version - recommended)
  /// Returns true if permissions are granted, false otherwise
  static Future<bool> checkNotificationPermissions() async {
    await _waitForInitialization();
    return await _shared!._deviceService.checkNotificationPermissions();
  }

  /// Get current notification permission status (async version - recommended)
  /// Returns the current permission status enum
  static Future<NotificationPermissionStatus>
      getNotificationPermissionStatus() async {
    await _waitForInitialization();
    return await _shared!._deviceService.getNotificationPermissionStatus();
  }

  /// Open notification settings if permission is denied (async version - recommended)
  /// Returns true if settings were opened successfully, false otherwise
  static Future<bool> openNotificationSettings() async {
    await _waitForInitialization();
    return await _shared!._deviceService.openNotificationSettings();
  }

  /// Get detailed permission information for debugging (async version - recommended)
  /// Returns a map with detailed permission information
  static Future<Map<String, dynamic>> getPermissionInfo() async {
    await _waitForInitialization();
    return await _shared!._deviceService.getPermissionInfo();
  }

  /// Set notification preferences (async version - recommended)
  /// Configure notification settings with enabled state and optional categories
  static Future<void> setNotificationPreferences({
    required bool enabled,
    List<String>? categories,
  }) async {
    await _waitForInitialization();
    await _shared!._deviceService.setNotificationPreferences(
      enabled: enabled,
      categories: categories,
    );
  }

  /// Check if permission is permanently denied (async version - recommended)
  /// Returns true if permission was permanently denied by user
  static Future<bool> isPermissionPermanentlyDenied() async {
    await _waitForInitialization();
    return await _shared!._deviceService.isPermissionPermanentlyDenied();
  }

  /// Get current notification settings (async version - recommended)
  /// Returns notification settings object or null if not available
  static Future<NotificationSettings?> getNotificationSettings() async {
    await _waitForInitialization();
    return await _shared!._deviceService.getNotificationSettings();
  }

  /// Check if push permission is granted (sync version with timeout protection)
  /// Returns cached permission status from storage
  static bool isPushPermissionGranted() {
    final instance = _getShared(timeout: const Duration(milliseconds: 100));
    if (instance != null) {
      return instance._deviceService.isPushPermissionGranted();
    }
    return false;
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
      // Initialize device and register
      await _deviceService.registerDevice();

      // Get initial token
      final token = await PlatformService.getPushToken();
      if (token != null) {
        await _tokenService.setCurrentToken(token);
        await _deviceService.updatePushToken(token);
      }

      // Set up token refresh handler
      PlatformService.onTokenRefresh.listen((token) async {
        await _tokenService.setCurrentToken(token);
        await _deviceService.updatePushToken(token);
      });

      // Set up notification handlers
      PlatformService.onForegroundNotification.listen((payload) async {
        ClixLogger.info(
            'Received foreground notification: ${payload.messageId}');
        await _notificationService.handleNotificationReceived(payload);
        _notificationReceivedHandler?.call(payload);
      });

      PlatformService.onNotificationTapped.listen((payload) async {
        ClixLogger.info('Notification tapped: ${payload.messageId}');
        await _notificationService.handleNotificationTapped(payload);
        _notificationTappedHandler?.call(payload);
      });

      PlatformService.onBackgroundNotification.listen((payload) async {
        ClixLogger.info(
            'Received background notification: ${payload.messageId}');
        await _notificationService
            .handleNotificationReceivedBackground(payload);
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
    _shared?._apiClient.close();
    _shared?._notificationService.close();
    PlatformService.dispose();
    _shared = null;
  }
}
