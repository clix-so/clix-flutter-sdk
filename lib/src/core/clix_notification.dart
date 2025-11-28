import 'package:firebase_messaging/firebase_messaging.dart';

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
  Future<bool> Function(RemoteMessage)? _onMessage;
  Future<void> Function(RemoteMessage)? _onBackgroundMessage;
  void Function(RemoteMessage)? _onNotificationOpened;
  void Function(Exception)? _onFcmTokenError;

  // Configuration
  bool _autoHandleLandingURL = true;

  /// Configure notification behavior.
  Future<void> configure({
    bool autoRequestPermission = false,
    bool autoHandleLandingURL = true,
  }) async {
    _autoHandleLandingURL = autoHandleLandingURL;

    if (autoRequestPermission) {
      await requestPermission();
    }
  }

  /// Requests notification permission from the user.
  Future<AuthorizationStatus> requestPermission() async {
    try {
      await Clix.waitForInitialization();
      final status =
          await Clix.notificationServiceInstance?.requestNotificationPermission();
      return status ?? AuthorizationStatus.denied;
    } catch (e) {
      ClixLogger.error('Failed to request permission', e);
      return AuthorizationStatus.denied;
    }
  }

  /// Returns the current notification permission status.
  Future<AuthorizationStatus> getPermissionStatus() async {
    try {
      final settings =
          await FirebaseMessaging.instance.getNotificationSettings();
      return settings.authorizationStatus;
    } catch (e) {
      ClixLogger.error('Failed to get permission status', e);
      return AuthorizationStatus.denied;
    }
  }

  /// Whether landing URLs should be automatically opened on notification tap.
  bool get autoHandleLandingURL => _autoHandleLandingURL;

  /// Register a handler for foreground messages.
  /// Return true to display the notification or false to suppress it.
  void onMessage(Future<bool> Function(RemoteMessage) handler) {
    _onMessage = handler;
  }

  /// Register a handler for background messages.
  void onBackgroundMessage(Future<void> Function(RemoteMessage) handler) {
    _onBackgroundMessage = handler;
  }

  /// Register a handler for when a notification is opened/tapped.
  void onNotificationOpened(void Function(RemoteMessage) handler) {
    _onNotificationOpened = handler;
  }

  /// Register a handler for FCM token errors.
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

  /// Deletes the current FCM token.
  Future<void> deleteToken() async {
    try {
      await Clix.waitForInitialization();
      await Clix.notificationServiceInstance?.deleteToken();
    } catch (e) {
      ClixLogger.error('Failed to delete token', e);
      rethrow;
    }
  }

  // Internal handlers for SDK use
  Future<bool> handleIncomingMessage(RemoteMessage message) async {
    try {
      if (_onMessage != null) {
        return await _onMessage!(message);
      }
      return true; // Default: display notification
    } catch (e) {
      ClixLogger.error('Message handler failed', e);
      return true;
    }
  }

  Future<void> handleBackgroundMessage(RemoteMessage message) async {
    try {
      await _onBackgroundMessage?.call(message);
    } catch (e) {
      ClixLogger.error('Background message handler failed', e);
    }
  }

  void handleNotificationOpened(RemoteMessage message) {
    try {
      _onNotificationOpened?.call(message);
    } catch (e) {
      ClixLogger.error('Notification opened handler failed', e);
    }
  }

  void handleFcmTokenError(Exception error) {
    ClixLogger.error('FCM token error', error);
    _onFcmTokenError?.call(error);
  }
}
