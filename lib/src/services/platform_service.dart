import 'dart:async';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../utils/uuid_generator.dart';
import '../models/clix_push_notification_payload.dart';
import '../utils/logger.dart';
import 'storage_service.dart';
import 'fcm_service.dart';

class PlatformService {
  static const MethodChannel _methodChannel = MethodChannel('clix_flutter');
  static const EventChannel _eventChannel = EventChannel('clix_flutter/events');

  static Stream<Map<String, dynamic>>? _eventStream;
  static StreamSubscription<Map<String, dynamic>>? _eventSubscription;

  // Event controllers for different types of platform events
  static final StreamController<String> _tokenController =
      StreamController<String>.broadcast();
  static final StreamController<ClixPushNotificationPayload>
      _foregroundNotificationController =
      StreamController<ClixPushNotificationPayload>.broadcast();
  static final StreamController<ClixPushNotificationPayload>
      _backgroundNotificationController =
      StreamController<ClixPushNotificationPayload>.broadcast();
  static final StreamController<ClixPushNotificationPayload>
      _notificationTappedController =
      StreamController<ClixPushNotificationPayload>.broadcast();

  /// Start listening to platform events
  static Future<void> startListening() async {
    if (kIsWeb) {
      ClixLogger.warning('Platform service not supported on web');
      return;
    }

    try {
      // Initialize FCM service first
      await FCMService.initialize();

      // Forward FCM streams to platform service streams
      _forwardFCMStreams();

      // Keep legacy event channel for non-FCM events (if needed)
      _eventStream =
          _eventChannel.receiveBroadcastStream().cast<Map<String, dynamic>>();
      _eventSubscription = _eventStream!
          .listen(_handlePlatformEvent, onError: _handlePlatformError);

      ClixLogger.debug('Platform service listening started');
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to start platform listening', e, stackTrace);
    }
  }

  /// Forward FCM service streams to platform service streams
  static void _forwardFCMStreams() {
    // Forward token updates
    FCMService.onTokenRefresh.listen((token) {
      _tokenController.add(token);
    });

    // Forward notification events
    FCMService.onForegroundNotification.listen((payload) {
      _foregroundNotificationController.add(payload);
    });

    FCMService.onBackgroundNotification.listen((payload) {
      _backgroundNotificationController.add(payload);
    });

    FCMService.onNotificationTapped.listen((payload) {
      _notificationTappedController.add(payload);
    });
  }

  /// Dispose platform service
  static void dispose() {
    _eventSubscription?.cancel();
    FCMService.dispose();
    _tokenController.close();
    _foregroundNotificationController.close();
    _backgroundNotificationController.close();
    _notificationTappedController.close();
  }

  // MARK: - Event Streams

  /// Stream of FCM token updates
  static Stream<String> get onTokenRefresh => _tokenController.stream;

  /// Stream of notifications received in foreground
  static Stream<ClixPushNotificationPayload> get onForegroundNotification =>
      _foregroundNotificationController.stream;

  /// Stream of notifications received in background
  static Stream<ClixPushNotificationPayload> get onBackgroundNotification =>
      _backgroundNotificationController.stream;

  /// Stream of notification taps
  static Stream<ClixPushNotificationPayload> get onNotificationTapped =>
      _notificationTappedController.stream;

  // MARK: - Platform Methods

  /// Initialize the platform service
  static Future<bool> initialize({
    required String projectId,
    required String apiKey,
  }) async {
    if (kIsWeb) return false;

    try {
      // Store configuration in Dart-side storage
      await StorageService.setProjectId(projectId);
      await StorageService.setApiKey(apiKey);

      // Platform initialization is now handled in Dart
      // Native side only provides device-specific functionality
      ClixLogger.debug('Platform initialized with projectId: $projectId');
      return true;
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to initialize platform service', e, stackTrace);
      return false;
    }
  }

  /// Set user ID
  static Future<bool> setUserId(String userId) async {
    if (kIsWeb) return false;

    try {
      // Store user ID in Dart-side storage
      await StorageService.setUserId(userId);
      ClixLogger.debug('User ID set: $userId');
      return true;
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to set user ID', e, stackTrace);
      return false;
    }
  }

  /// Remove user ID
  static Future<bool> removeUserId() async {
    if (kIsWeb) return false;

    try {
      // Remove user ID from Dart-side storage
      await StorageService.removeUserId();
      ClixLogger.debug('User ID removed');
      return true;
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to remove user ID', e, stackTrace);
      return false;
    }
  }

  /// Set user property
  static Future<bool> setUserProperty(String key, dynamic value) async {
    if (kIsWeb) return false;

    try {
      // Store user property in Dart-side storage
      await StorageService.setUserProperty(key, value);
      ClixLogger.debug('User property set: $key = $value');
      return true;
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to set user property', e, stackTrace);
      return false;
    }
  }

  /// Set user properties
  static Future<bool> setUserProperties(Map<String, dynamic> properties) async {
    if (kIsWeb) return false;

    try {
      // Store user properties in Dart-side storage
      await StorageService.setUserProperties(properties);
      ClixLogger.debug(
          'User properties set: ${properties.keys.length} properties');
      return true;
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to set user properties', e, stackTrace);
      return false;
    }
  }

  /// Remove user property
  static Future<bool> removeUserProperty(String key) async {
    if (kIsWeb) return false;

    try {
      // Remove user property from Dart-side storage
      await StorageService.removeUserProperty(key);
      ClixLogger.debug('User property removed: $key');
      return true;
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to remove user property', e, stackTrace);
      return false;
    }
  }

  /// Remove user properties
  static Future<bool> removeUserProperties(List<String> keys) async {
    if (kIsWeb) return false;

    try {
      // Remove user properties from Dart-side storage
      await StorageService.removeUserProperties(keys);
      ClixLogger.debug('User properties removed: ${keys.length} properties');
      return true;
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to remove user properties', e, stackTrace);
      return false;
    }
  }

  /// Get device ID using device_info_plus (replaces native implementation)
  static Future<String?> getDeviceId() async {
    try {
      if (kIsWeb) {
        // For web, generate a consistent ID or use stored one
        final storedId = await StorageService.getWebDeviceId();
        if (storedId != null) return storedId;
        
        final webDeviceId = 'web_${UuidGenerator.generateV4()}';
        await StorageService.setWebDeviceId(webDeviceId);
        return webDeviceId;
      }

      final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      
      if (Platform.isAndroid) {
        final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        final androidId = androidInfo.id;
        
        if (androidId.isNotEmpty && androidId != 'unknown') {
          ClixLogger.debug('Device ID retrieved (Android): $androidId');
          return androidId;
        }
        
        // Fallback for Android
        final fallbackId = '${androidInfo.manufacturer}_${androidInfo.model}_${androidInfo.device}'.replaceAll(' ', '_').toLowerCase();
        ClixLogger.debug('Device ID retrieved (Android fallback): $fallbackId');
        return fallbackId;
        
      } else if (Platform.isIOS) {
        final IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        final vendorId = iosInfo.identifierForVendor;
        
        if (vendorId != null && vendorId.isNotEmpty) {
          ClixLogger.debug('Device ID retrieved (iOS): $vendorId');
          return vendorId;
        }
        
        // Fallback for iOS
        final fallbackId = 'ios_${UuidGenerator.generateV4()}';
        ClixLogger.debug('Device ID retrieved (iOS fallback): $fallbackId');
        return fallbackId;
        
      } else {
        // Other platforms
        final platformId = '${Platform.operatingSystem}_${UuidGenerator.generateV4()}';
        ClixLogger.debug('Device ID retrieved (${Platform.operatingSystem}): $platformId');
        return platformId;
      }
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to get device ID', e, stackTrace);
      
      // Final fallback
      final fallbackId = 'fallback_${UuidGenerator.generateV4()}';
      ClixLogger.warning('Using fallback device ID: $fallbackId');
      return fallbackId;
    }
  }

  /// Get push token
  static Future<String?> getPushToken() async {
    if (kIsWeb) return null;

    try {
      // Use FCM service instead of native call
      final String? token = await FCMService.getToken();
      ClixLogger.debug('Push token retrieved: ${token?.substring(0, 20)}...');
      return token;
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to get push token', e, stackTrace);
      return null;
    }
  }

  /// Set log level
  static Future<bool> setLogLevel(int level) async {
    if (kIsWeb) return false;

    try {
      // Store log level in Dart-side storage
      await StorageService.setLogLevel(level);
      ClixLogger.debug('Log level set: $level');
      return true;
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to set log level', e, stackTrace);
      return false;
    }
  }

  /// Request notification permissions
  static Future<bool> requestNotificationPermissions() async {
    if (kIsWeb) return false;

    try {
      final bool result =
          await _methodChannel.invokeMethod('requestNotificationPermissions');
      ClixLogger.debug('Notification permissions result: $result');
      return result;
    } catch (e, stackTrace) {
      ClixLogger.error(
          'Failed to request notification permissions', e, stackTrace);
      return false;
    }
  }

  /// Get current notification settings
  static Future<Map<String, dynamic>?> getNotificationSettings() async {
    if (kIsWeb) return null;

    try {
      final result = await _methodChannel
          .invokeMethod<Map<Object?, Object?>>('getNotificationSettings');

      if (result == null) {
        ClixLogger.warning('Notification settings returned null');
        return null;
      }

      final Map<String, dynamic> typedResult =
          Map<String, dynamic>.from(result);
      ClixLogger.debug('Notification settings: $typedResult');
      return typedResult;
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to get notification settings', e, stackTrace);
      return null;
    }
  }

  /// Get FCM token
  static Future<String?> getFCMToken() async {
    if (kIsWeb) return null;

    try {
      // Use FCM service instead of native call
      final String? token = await FCMService.getToken();
      ClixLogger.debug('FCM token retrieved: ${token?.substring(0, 20)}...');
      return token;
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to get FCM token', e, stackTrace);
      return null;
    }
  }

  /// Subscribe to FCM topic
  static Future<bool> subscribeToTopic(String topic) async {
    if (kIsWeb) return false;

    try {
      // Use FCM service instead of native call
      return await FCMService.subscribeToTopic(topic);
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to subscribe to topic: $topic', e, stackTrace);
      return false;
    }
  }

  /// Unsubscribe from FCM topic
  static Future<bool> unsubscribeFromTopic(String topic) async {
    if (kIsWeb) return false;

    try {
      // Use FCM service instead of native call
      return await FCMService.unsubscribeFromTopic(topic);
    } catch (e, stackTrace) {
      ClixLogger.error(
          'Failed to unsubscribe from topic: $topic', e, stackTrace);
      return false;
    }
  }

  /// Set notification badge count (iOS only)
  static Future<bool> setNotificationBadge(int count) async {
    if (kIsWeb || !Platform.isIOS) return false;

    try {
      // Use FCM service instead of native call
      return await FCMService.setNotificationBadge(count);
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to set notification badge', e, stackTrace);
      return false;
    }
  }

  /// Clear notification badge (iOS only)
  static Future<bool> clearNotificationBadge() async {
    if (kIsWeb || !Platform.isIOS) return false;

    try {
      final bool result = await _methodChannel.invokeMethod('clearNotificationBadge');
      ClixLogger.debug('Notification badge cleared');
      return result;
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to clear notification badge', e, stackTrace);
      return false;
    }
  }

  /// Open notification settings (Android only)
  static Future<bool> openNotificationSettings() async {
    if (kIsWeb || !Platform.isAndroid) return false;

    try {
      await _methodChannel.invokeMethod('openNotificationSettings');
      ClixLogger.debug('Opened notification settings');
      return true;
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to open notification settings', e, stackTrace);
      return false;
    }
  }

  /// Handle notification tap - now handled entirely in Flutter via FCM service
  /// This method is deprecated and kept for backward compatibility only
  @Deprecated('Notification tap handling is now done in Flutter via FCM service')
  static Future<void> handleNotificationTap(Map<String, dynamic> data) async {
    if (kIsWeb) return;

    // Notification tap handling is now done entirely in Flutter via FCM service
    // This method is kept for backward compatibility but does nothing
    ClixLogger.debug('Notification tap handled via FCM service (deprecated method called)');
  }

  // MARK: - Private Methods

  static void _handlePlatformEvent(Map<String, dynamic> event) {
    try {
      final String type = event['type'] as String;
      final Map<String, dynamic> data = event['data'] as Map<String, dynamic>;

      ClixLogger.verbose('Platform event received: $type');

      switch (type) {
        case 'tokenRefresh':
          final String token = data['token'] as String;
          _tokenController.add(token);
          break;

        case 'foregroundNotification':
          final payload = ClixPushNotificationPayload.fromMap(data);
          _foregroundNotificationController.add(payload);
          break;

        case 'backgroundNotification':
          final payload = ClixPushNotificationPayload.fromMap(data);
          _backgroundNotificationController.add(payload);
          break;

        case 'notificationTapped':
          final payload = ClixPushNotificationPayload.fromMap(data);
          _notificationTappedController.add(payload);
          break;

        default:
          ClixLogger.warning('Unknown platform event type: $type');
      }
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to handle platform event', e, stackTrace);
    }
  }

  static void _handlePlatformError(Object error) {
    ClixLogger.error('Platform event stream error', error);
  }

  // MARK: - Platform Detection Helpers

  /// Check if the current platform supports push notifications
  static bool get supportsPushNotifications {
    return !kIsWeb && (Platform.isIOS || Platform.isAndroid);
  }

  /// Check if the current platform supports badge counts
  static bool get supportsBadgeCount {
    return !kIsWeb && Platform.isIOS;
  }

  /// Check if the current platform supports notification settings
  static bool get supportsNotificationSettings {
    return !kIsWeb;
  }

  /// Get platform-specific information
  static Map<String, dynamic> get platformInfo {
    return {
      'isWeb': kIsWeb,
      'isIOS': !kIsWeb && Platform.isIOS,
      'isAndroid': !kIsWeb && Platform.isAndroid,
      'supportsPushNotifications': supportsPushNotifications,
      'supportsBadgeCount': supportsBadgeCount,
      'supportsNotificationSettings': supportsNotificationSettings,
    };
  }
}
