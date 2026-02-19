import 'dart:async';

import '../services/clix_api_client.dart';
import '../services/device_api_service.dart';
import '../services/device_service.dart';
import '../services/event_api_service.dart';
import '../services/event_service.dart';
import '../services/notification_service.dart';
import '../services/session_service.dart';
import '../services/storage_service.dart';
import '../services/token_service.dart';
import '../utils/clix_error.dart';
import '../utils/logging/clix_log_level.dart';
import '../utils/logging/clix_logger.dart';
import 'clix_config.dart';
import 'clix_notification.dart';

class Clix {
  /// Notification management interface for handling push notifications,
  /// permissions, and related functionality.
  ///
  /// Use this to configure notification behavior, register handlers, and
  /// manage FCM tokens.
  // ignore: non_constant_identifier_names
  static final ClixNotification Notification = ClixNotification();

  static Clix? _shared;
  static bool _isInitializing = false;
  static Completer<void> _initCompleter = Completer<void>();

  // Services - nullable until initialization
  StorageService? _storageService;
  EventService? _eventService;
  DeviceService? _deviceService;
  SessionService? _sessionService;
  NotificationService? _notificationService;

  Clix._();

  /// Initialize Clix SDK
  static Future<void> initialize(ClixConfig config) async {
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

  /// Set configuration
  Future<void> _setConfig(ClixConfig config) async {
    // Initialize storage service
    _storageService = StorageService();
    await _storageService!.initialize(config.projectId);

    // Store configuration
    await _storageService!.set<String>('project_id', config.projectId);
    await _storageService!.set<String>('api_key', config.apiKey);

    // Store full config for background handler
    await _storageService!
        .set<Map<String, dynamic>>('clix_config', config.toJson());

    // Initialize API client
    final apiClient = ClixAPIClient(config: config);

    // Initialize API services
    final deviceAPIService = DeviceAPIService(apiClient: apiClient);
    final eventAPIService = EventAPIService(apiClient: apiClient);

    // Initialize token service
    final tokenService = TokenService(storageService: _storageService!);

    // Initialize device service
    _deviceService = DeviceService(
      storageService: _storageService!,
      tokenService: tokenService,
      deviceAPIService: deviceAPIService,
    );

    // Initialize event service
    _eventService = EventService(
      eventAPIService: eventAPIService,
      deviceService: _deviceService!,
    );

    // Initialize session service
    _sessionService = SessionService(
      storageService: _storageService!,
      eventService: _eventService!,
      sessionTimeoutMs: config.sessionTimeoutMs,
    );

    // Initialize notification service
    _notificationService = NotificationService();
    await _notificationService!.initialize(
      eventService: _eventService!,
      storageService: _storageService!,
      deviceService: _deviceService!,
      tokenService: tokenService,
      sessionService: _sessionService,
    );

    // Start session (after notification service so initial notification can set pendingMessageId)
    await _sessionService!.start();
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

  /// Set user ID
  static Future<void> setUserId(String userId) async {
    await _waitForInitialization();
    try {
      await _shared!._deviceService!.setProjectUserId(userId);
    } catch (e) {
      throw ClixError.unknownErrorWithReason('Failed to set user ID: $e');
    }
  }

  /// Remove user ID
  @Deprecated('Use reset() instead')
  static Future<void> removeUserId() async {
    await _waitForInitialization();
    try {
      await _shared!._deviceService!.removeProjectUserId();
    } catch (e) {
      throw ClixError.unknownErrorWithReason('Failed to remove user ID: $e');
    }
  }

  /// Resets all local SDK state including device ID.
  ///
  /// After calling this method, you must call [initialize] again before using the SDK.
  /// Use this when a user logs out and you want to start fresh with a new device identity.
  static Future<void> reset() async {
    await _waitForInitialization();
    try {
      await _shared!._storageService?.remove('clix_device_id');
      await _shared!._storageService?.remove('clix_session_last_activity');
      _shared = null;
      _isInitializing = false;
      _initCompleter = Completer<void>();
    } catch (e) {
      throw ClixError.unknownErrorWithReason('Failed to reset: $e');
    }
  }

  /// Set user property
  static Future<void> setUserProperty(String key, dynamic value) async {
    await _waitForInitialization();
    try {
      await _shared!._deviceService!.updateUserProperties({key: value});
    } catch (e) {
      throw ClixError.unknownErrorWithReason('Failed to set user property: $e');
    }
  }

  /// Set user properties
  static Future<void> setUserProperties(
      Map<String, dynamic> userProperties) async {
    await _waitForInitialization();
    try {
      await _shared!._deviceService!.updateUserProperties(userProperties);
    } catch (e) {
      throw ClixError.unknownErrorWithReason(
          'Failed to set user properties: $e');
    }
  }

  /// Remove user property
  static Future<void> removeUserProperty(String key) async {
    await _waitForInitialization();
    try {
      await _shared!._deviceService!.removeUserProperties([key]);
    } catch (e) {
      throw ClixError.unknownErrorWithReason(
          'Failed to remove user property: $e');
    }
  }

  /// Remove user properties
  static Future<void> removeUserProperties(List<String> keys) async {
    await _waitForInitialization();
    try {
      await _shared!._deviceService!.removeUserProperties(keys);
    } catch (e) {
      throw ClixError.unknownErrorWithReason(
          'Failed to remove user properties: $e');
    }
  }

  /// Get device ID
  static Future<String?> getDeviceId() async {
    await _waitForInitialization();
    final deviceId = await _shared!._deviceService!.getCurrentDeviceId();
    return deviceId;
  }

  static void setLogLevel(ClixLogLevel level) {
    ClixLogger.setLogLevel(level);
  }

  /// Check if SDK is initialized
  static bool get isInitialized => _shared != null;

  // Internal access for ClixNotification
  static Future<void> waitForInitialization() => _waitForInitialization();
  static NotificationService? get notificationServiceInstance =>
      _shared?._notificationService;
  static DeviceService? get deviceServiceInstance => _shared?._deviceService;

  /// Track event
  static Future<void> trackEvent(
    String name, {
    Map<String, dynamic>? properties,
    String? messageId,
  }) async {
    await _waitForInitialization();
    try {
      await _shared!._eventService!.trackEvent(
        name,
        properties: properties,
        messageId: messageId,
      );
    } catch (e) {
      throw ClixError.unknownErrorWithReason('Failed to track event: $e');
    }
  }
}
