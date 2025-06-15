import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/clix_push_notification_payload.dart';
import '../utils/logger.dart';

/// Flutter equivalent of iOS ClixAppDelegate
/// Provides helper methods for integrating Clix SDK with Flutter apps
class ClixAppDelegate {
  static bool _isFirebaseInitialized = false;
  static FirebaseMessaging? _messaging;

  /// Initialize Firebase and set up basic message handling
  /// Call this during app initialization, typically in main()
  static Future<void> initialize() async {
    if (_isFirebaseInitialized) return;

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }

      _messaging = FirebaseMessaging.instance;
      _isFirebaseInitialized = true;

      ClixLogger.debug('ClixAppDelegate: Firebase initialized');
    } catch (e, stackTrace) {
      ClixLogger.error('ClixAppDelegate: Failed to initialize Firebase', e, stackTrace);
      rethrow;
    }
  }

  /// Request notification permissions
  /// Returns the authorization status
  static Future<AuthorizationStatus> requestNotificationPermissions({
    bool alert = true,
    bool badge = true,
    bool sound = true,
    bool announcement = false,
    bool carPlay = false,
    bool criticalAlert = false,
    bool provisional = false,
  }) async {
    if (!_isFirebaseInitialized) {
      throw StateError('ClixAppDelegate not initialized. Call initialize() first.');
    }

    try {
      final settings = await _messaging!.requestPermission(
        alert: alert,
        announcement: announcement,
        badge: badge,
        carPlay: carPlay,
        criticalAlert: criticalAlert,
        provisional: provisional,
        sound: sound,
      );

      ClixLogger.info('Notification permission status: ${settings.authorizationStatus}');
      return settings.authorizationStatus;
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to request notification permissions', e, stackTrace);
      rethrow;
    }
  }

  /// Get the current FCM token
  static Future<String?> getToken() async {
    if (!_isFirebaseInitialized) {
      throw StateError('ClixAppDelegate not initialized. Call initialize() first.');
    }

    try {
      return await _messaging!.getToken();
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to get FCM token', e, stackTrace);
      return null;
    }
  }

  /// Set up foreground message handler
  /// Call this to handle messages when app is in foreground
  static void setForegroundMessageHandler(
    void Function(ClixPushNotificationPayload payload) handler,
  ) {
    if (!_isFirebaseInitialized) {
      throw StateError('ClixAppDelegate not initialized. Call initialize() first.');
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      ClixLogger.info('Received foreground message: ${message.messageId}');
      final payload = ClixPushNotificationPayload.fromRemoteMessage(message);
      handler(payload);
    });
  }

  /// Set up background message handler (when app is opened from notification)
  /// Call this to handle messages when user taps notification while app is in background
  static void setBackgroundMessageHandler(
    void Function(ClixPushNotificationPayload payload) handler,
  ) {
    if (!_isFirebaseInitialized) {
      throw StateError('ClixAppDelegate not initialized. Call initialize() first.');
    }

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      ClixLogger.info('Message opened app: ${message.messageId}');
      final payload = ClixPushNotificationPayload.fromRemoteMessage(message);
      handler(payload);
    });
  }

  /// Handle initial message (when app is launched from notification)
  /// Call this during app startup to check if app was opened from notification
  static Future<void> handleInitialMessage(
    void Function(ClixPushNotificationPayload payload) handler,
  ) async {
    if (!_isFirebaseInitialized) {
      throw StateError('ClixAppDelegate not initialized. Call initialize() first.');
    }

    try {
      final initialMessage = await _messaging!.getInitialMessage();
      if (initialMessage != null) {
        ClixLogger.info('App opened from notification: ${initialMessage.messageId}');
        final payload = ClixPushNotificationPayload.fromRemoteMessage(initialMessage);
        handler(payload);
      }
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to handle initial message', e, stackTrace);
    }
  }

  /// Listen to token refresh events
  /// Call this to be notified when FCM token changes
  static void setTokenRefreshHandler(
    void Function(String token) handler,
  ) {
    if (!_isFirebaseInitialized) {
      throw StateError('ClixAppDelegate not initialized. Call initialize() first.');
    }

    _messaging!.onTokenRefresh.listen((String token) {
      ClixLogger.debug('FCM token refreshed');
      handler(token);
    });
  }

  /// Check if Firebase is initialized
  static bool get isInitialized => _isFirebaseInitialized;
}
