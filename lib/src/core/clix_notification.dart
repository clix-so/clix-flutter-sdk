import '../utils/logging/clix_logger.dart';
import 'clix.dart';

/// Notification management interface for the Clix SDK.
///
/// Provides a central hub for configuring notification behavior, registering
/// handlers, and managing push notifications.
class ClixNotification {
  ClixNotification._();

  // Callback handlers
  static Future<bool> Function(Map<String, dynamic>)? _onMessage;
  static void Function(Map<String, dynamic>)? _onBackgroundMessage;
  static void Function(Map<String, dynamic>)? _onNotificationOpened;
  static void Function(Exception)? _onFcmTokenError;

  /// Register a handler for foreground messages.
  ///
  /// The handler receives notification data and should return true to display
  /// the notification or false to suppress it.
  static void onMessage(Future<bool> Function(Map<String, dynamic>) handler) {
    _onMessage = handler;
  }

  /// Register a handler for background messages.
  ///
  /// This handler is invoked when a notification is received while the app
  /// is in the background.
  static void onBackgroundMessage(
      void Function(Map<String, dynamic>) handler) {
    _onBackgroundMessage = handler;
  }

  /// Register a handler for when a notification is opened/tapped.
  ///
  /// This handler is called when the user taps on a notification.
  static void onNotificationOpened(
      void Function(Map<String, dynamic>) handler) {
    _onNotificationOpened = handler;
  }

  /// Register a handler for FCM token errors.
  ///
  /// This handler is invoked when there is an error fetching or refreshing
  /// the FCM token.
  static void onFcmTokenError(void Function(Exception) handler) {
    _onFcmTokenError = handler;
  }

  /// Returns the current FCM token for this device.
  static Future<String?> getToken() async {
    return Clix.getPushToken();
  }

  /// Deletes the current FCM token and notifies the server.
  static Future<void> deleteToken() async {
    return Clix.deletePushToken();
  }

  // Internal handlers for SDK use
  static Future<bool> handleIncomingMessage(
      Map<String, dynamic> notificationData) async {
    try {
      if (_onMessage != null) {
        return await _onMessage!(notificationData);
      }
      return true; // Default: display notification
    } catch (e) {
      ClixLogger.error('Message handler failed', e);
      return true;
    }
  }

  static void handleBackgroundMessage(Map<String, dynamic> notificationData) {
    try {
      _onBackgroundMessage?.call(notificationData);
    } catch (e) {
      ClixLogger.error('Background message handler failed', e);
    }
  }

  static void handleNotificationOpened(Map<String, dynamic> notificationData) {
    try {
      _onNotificationOpened?.call(notificationData);
    } catch (e) {
      ClixLogger.error('Notification opened handler failed', e);
    }
  }

  static void handleFcmTokenError(Exception error) {
    ClixLogger.error('FCM token error', error);
    _onFcmTokenError?.call(error);
  }
}
