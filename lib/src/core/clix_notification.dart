import '../utils/logging/clix_logger.dart';
import 'clix.dart';

/// Notification management interface for the Clix SDK.
///
/// Provides a central hub for configuring notification behavior, registering
/// handlers, and managing push notifications.
///
/// Access this class through [Clix.Notification] only.
class ClixNotification {
  // Callback handlers
  Future<bool> Function(Map<String, dynamic>)? _onMessage;
  void Function(Map<String, dynamic>)? _onBackgroundMessage;
  void Function(Map<String, dynamic>)? _onNotificationOpened;
  void Function(Exception)? _onFcmTokenError;

  /// Register a handler for foreground messages.
  ///
  /// The handler receives notification data and should return true to display
  /// the notification or false to suppress it.
  void onMessage(Future<bool> Function(Map<String, dynamic>) handler) {
    _onMessage = handler;
  }

  /// Register a handler for background messages.
  ///
  /// This handler is invoked when a notification is received while the app
  /// is in the background.
  void onBackgroundMessage(void Function(Map<String, dynamic>) handler) {
    _onBackgroundMessage = handler;
  }

  /// Register a handler for when a notification is opened/tapped.
  ///
  /// This handler is called when the user taps on a notification.
  void onNotificationOpened(void Function(Map<String, dynamic>) handler) {
    _onNotificationOpened = handler;
  }

  /// Register a handler for FCM token errors.
  ///
  /// This handler is invoked when there is an error fetching or refreshing
  /// the FCM token.
  void onFcmTokenError(void Function(Exception) handler) {
    _onFcmTokenError = handler;
  }

  /// Returns the current FCM token for this device.
  Future<String?> getToken() async {
    try {
      await Clix.waitForInitialization();
      return await Clix.notificationServiceInstance?.getCurrentToken();
    } catch (e) {
      ClixLogger.error('Failed to get token', e);
      return null;
    }
  }

  /// Deletes the current FCM token and notifies the server.
  Future<void> deleteToken() async {
    try {
      await Clix.waitForInitialization();
      await Clix.notificationServiceInstance?.deleteToken();
      ClixLogger.debug('FCM token deleted successfully');
    } catch (e) {
      ClixLogger.error('Failed to delete token', e);
      rethrow;
    }
  }

  // Internal handlers for SDK use
  Future<bool> handleIncomingMessage(
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

  void handleBackgroundMessage(Map<String, dynamic> notificationData) {
    try {
      _onBackgroundMessage?.call(notificationData);
    } catch (e) {
      ClixLogger.error('Background message handler failed', e);
    }
  }

  void handleNotificationOpened(Map<String, dynamic> notificationData) {
    try {
      _onNotificationOpened?.call(notificationData);
    } catch (e) {
      ClixLogger.error('Notification opened handler failed', e);
    }
  }

  void handleFcmTokenError(Exception error) {
    ClixLogger.error('FCM token error', error);
    _onFcmTokenError?.call(error);
  }
}
