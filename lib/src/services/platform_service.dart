import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/clix_push_notification_payload.dart';
import '../utils/logger.dart';

class PlatformService {
  static const MethodChannel _methodChannel = MethodChannel('clix_flutter');
  static const EventChannel _eventChannel = EventChannel('clix_flutter/events');

  static Stream<Map<String, dynamic>>? _eventStream;
  static StreamSubscription<Map<String, dynamic>>? _eventSubscription;

  // Event controllers for different types of platform events
  static final StreamController<String> _tokenController = StreamController<String>.broadcast();
  static final StreamController<ClixPushNotificationPayload> _foregroundNotificationController = 
      StreamController<ClixPushNotificationPayload>.broadcast();
  static final StreamController<ClixPushNotificationPayload> _backgroundNotificationController = 
      StreamController<ClixPushNotificationPayload>.broadcast();
  static final StreamController<ClixPushNotificationPayload> _notificationTappedController = 
      StreamController<ClixPushNotificationPayload>.broadcast();

  /// Start listening to platform events
  static Future<void> startListening() async {
    if (kIsWeb) {
      ClixLogger.warning('Platform service not supported on web');
      return;
    }

    try {
      _eventStream = _eventChannel.receiveBroadcastStream().cast<Map<String, dynamic>>();
      _eventSubscription = _eventStream!.listen(_handlePlatformEvent, onError: _handlePlatformError);

      ClixLogger.debug('Platform service listening started');
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to start platform listening', e, stackTrace);
    }
  }

  /// Dispose platform service
  static void dispose() {
    _eventSubscription?.cancel();
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
      final Map<String, dynamic> result = await _methodChannel.invokeMethod('initialize', {
        'projectId': projectId,
        'apiKey': apiKey,
      });
      ClixLogger.debug('Platform initialized: $result');
      return result['success'] ?? false;
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to initialize platform service', e, stackTrace);
      return false;
    }
  }

  /// Set user ID
  static Future<bool> setUserId(String userId) async {
    if (kIsWeb) return false;

    try {
      final bool result = await _methodChannel.invokeMethod('setUserId', {'userId': userId});
      ClixLogger.debug('Set user ID result: $result');
      return result;
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to set user ID', e, stackTrace);
      return false;
    }
  }

  /// Remove user ID
  static Future<bool> removeUserId() async {
    if (kIsWeb) return false;

    try {
      final bool result = await _methodChannel.invokeMethod('removeUserId');
      ClixLogger.debug('Remove user ID result: $result');
      return result;
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to remove user ID', e, stackTrace);
      return false;
    }
  }

  /// Set user property
  static Future<bool> setUserProperty(String key, dynamic value) async {
    if (kIsWeb) return false;

    try {
      final bool result = await _methodChannel.invokeMethod('setUserProperty', {
        'key': key,
        'value': value,
      });
      ClixLogger.debug('Set user property result: $result');
      return result;
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to set user property', e, stackTrace);
      return false;
    }
  }

  /// Set user properties
  static Future<bool> setUserProperties(Map<String, dynamic> properties) async {
    if (kIsWeb) return false;

    try {
      final bool result = await _methodChannel.invokeMethod('setUserProperties', {
        'properties': properties,
      });
      ClixLogger.debug('Set user properties result: $result');
      return result;
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to set user properties', e, stackTrace);
      return false;
    }
  }

  /// Remove user property
  static Future<bool> removeUserProperty(String key) async {
    if (kIsWeb) return false;

    try {
      final bool result = await _methodChannel.invokeMethod('removeUserProperty', {'key': key});
      ClixLogger.debug('Remove user property result: $result');
      return result;
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to remove user property', e, stackTrace);
      return false;
    }
  }

  /// Remove user properties
  static Future<bool> removeUserProperties(List<String> keys) async {
    if (kIsWeb) return false;

    try {
      final bool result = await _methodChannel.invokeMethod('removeUserProperties', {'keys': keys});
      ClixLogger.debug('Remove user properties result: $result');
      return result;
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to remove user properties', e, stackTrace);
      return false;
    }
  }

  /// Get device ID
  static Future<String?> getDeviceId() async {
    if (kIsWeb) return null;

    try {
      final String? deviceId = await _methodChannel.invokeMethod('getDeviceId');
      ClixLogger.debug('Device ID retrieved: $deviceId');
      return deviceId;
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to get device ID', e, stackTrace);
      return null;
    }
  }

  /// Get push token
  static Future<String?> getPushToken() async {
    if (kIsWeb) return null;

    try {
      final String? token = await _methodChannel.invokeMethod('getPushToken');
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
      final bool result = await _methodChannel.invokeMethod('setLogLevel', {'level': level});
      ClixLogger.debug('Set log level result: $result');
      return result;
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to set log level', e, stackTrace);
      return false;
    }
  }

  /// Request notification permissions
  static Future<bool> requestNotificationPermissions() async {
    if (kIsWeb) return false;

    try {
      final bool result = await _methodChannel.invokeMethod('requestPermissions');
      ClixLogger.debug('Notification permissions result: $result');
      return result;
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to request notification permissions', e, stackTrace);
      return false;
    }
  }

  /// Get current notification settings
  static Future<Map<String, dynamic>?> getNotificationSettings() async {
    if (kIsWeb) return null;

    try {
      final Map<String, dynamic> result = await _methodChannel.invokeMethod('getNotificationSettings');
      ClixLogger.debug('Notification settings: $result');
      return result;
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to get notification settings', e, stackTrace);
      return null;
    }
  }

  /// Get FCM token
  static Future<String?> getFCMToken() async {
    if (kIsWeb) return null;

    try {
      final String? token = await _methodChannel.invokeMethod('getFCMToken');
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
      await _methodChannel.invokeMethod('subscribeToTopic', {'topic': topic});
      ClixLogger.debug('Subscribed to topic: $topic');
      return true;
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to subscribe to topic: $topic', e, stackTrace);
      return false;
    }
  }

  /// Unsubscribe from FCM topic
  static Future<bool> unsubscribeFromTopic(String topic) async {
    if (kIsWeb) return false;

    try {
      await _methodChannel.invokeMethod('unsubscribeFromTopic', {'topic': topic});
      ClixLogger.debug('Unsubscribed from topic: $topic');
      return true;
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to unsubscribe from topic: $topic', e, stackTrace);
      return false;
    }
  }

  /// Set notification badge count (iOS only)
  static Future<bool> setNotificationBadge(int count) async {
    if (kIsWeb || !Platform.isIOS) return false;

    try {
      await _methodChannel.invokeMethod('setNotificationBadge', {'count': count});
      ClixLogger.debug('Notification badge set to: $count');
      return true;
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to set notification badge', e, stackTrace);
      return false;
    }
  }

  /// Clear notification badge (iOS only)
  static Future<bool> clearNotificationBadge() async {
    if (kIsWeb || !Platform.isIOS) return false;

    try {
      await _methodChannel.invokeMethod('clearNotificationBadge');
      ClixLogger.debug('Notification badge cleared');
      return true;
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

  /// Handle notification tap from platform
  static Future<void> handleNotificationTap(Map<String, dynamic> data) async {
    if (kIsWeb) return;

    try {
      await _methodChannel.invokeMethod('handleNotificationTap', data);
      ClixLogger.debug('Handled notification tap');
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to handle notification tap', e, stackTrace);
    }
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
