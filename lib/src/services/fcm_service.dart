import 'dart:async';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/clix_push_notification_payload.dart';
import '../utils/logger.dart';
import 'storage_service.dart';

class FCMService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();

  // Event controllers for different types of FCM events
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

  static StreamSubscription<String>? _tokenSubscription;
  static StreamSubscription<RemoteMessage>? _foregroundSubscription;

  /// Initialize FCM service
  static Future<bool> initialize() async {
    if (kIsWeb) {
      ClixLogger.warning('FCM service not fully supported on web');
      return false;
    }

    try {
      // Initialize local notifications
      await _initializeLocalNotifications();

      // Request notification permissions
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      ClixLogger.debug('Notification permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        
        // Get initial token
        String? token = await getToken();
        if (token != null) {
          await StorageService.setPushToken(token);
          _tokenController.add(token);
        }

        // Listen to token refresh
        _tokenSubscription = _firebaseMessaging.onTokenRefresh.listen((token) {
          ClixLogger.debug('FCM token refreshed');
          StorageService.setPushToken(token);
          _tokenController.add(token);
        });

        // Listen to foreground messages
        _foregroundSubscription = FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          ClixLogger.debug('Foreground message received: ${message.messageId}');
          _handleForegroundMessage(message);
        });

        // Set background message handler
        FirebaseMessaging.onBackgroundMessage(backgroundMessageHandler);

        // Handle notification taps when app is terminated or in background
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          ClixLogger.debug('Message opened app: ${message.messageId}');
          _handleNotificationTap(message);
        });

        // Check for messages that opened the app
        RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
        if (initialMessage != null) {
          ClixLogger.debug('App opened from terminated state: ${initialMessage.messageId}');
          _handleNotificationTap(initialMessage);
        }

        ClixLogger.debug('FCM service initialized successfully');
        return true;
      } else {
        ClixLogger.warning('Notification permissions not granted');
        return false;
      }
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to initialize FCM service', e, stackTrace);
      return false;
    }
  }

  /// Initialize local notifications plugin
  static Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
          onDidReceiveLocalNotification: _onDidReceiveLocalNotification,
        );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
    );
  }

  /// Background message handler (must be top-level function)
  @pragma('vm:entry-point')
  static Future<void> backgroundMessageHandler(RemoteMessage message) async {
    ClixLogger.debug('Background message received: ${message.messageId}');
    
    try {
      // Convert message to payload for tracking
      ClixPushNotificationPayload.fromFirebaseMessage(message);
      
      // Native services (ClixMessagingService on Android, UNNotificationServiceExtension on iOS)
      // will handle notification display to prevent duplicates
      // This handler is kept for potential future processing needs
      
      // Note: Stream controllers won't work in background isolate
      // Background events will be handled when app becomes active
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to handle background message', e, stackTrace);
    }
  }


  /// Handle foreground messages
  static void _handleForegroundMessage(RemoteMessage message) {
    try {
      final payload = ClixPushNotificationPayload.fromFirebaseMessage(message);
      _foregroundNotificationController.add(payload);
      
      // Show notification in foreground
      _showLocalNotification(message);
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to handle foreground message', e, stackTrace);
    }
  }

  /// Handle notification tap
  static void _handleNotificationTap(RemoteMessage message) {
    try {
      final payload = ClixPushNotificationPayload.fromFirebaseMessage(message);
      _notificationTappedController.add(payload);
      
      // Handle landing URL if present
      _handleLandingUrl(payload.landingUrl);
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to handle notification tap', e, stackTrace);
    }
  }

  /// Handle landing URL opening
  static Future<void> _handleLandingUrl(String? landingUrl) async {
    if (landingUrl == null || landingUrl.isEmpty) return;

    try {
      final uri = Uri.parse(landingUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        ClixLogger.debug('Successfully opened landing URL: $landingUrl');
      } else {
        ClixLogger.warning('Cannot launch URL: $landingUrl');
      }
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to launch landing URL: $landingUrl', e, stackTrace);
    }
  }

  /// Show local notification
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      final notification = message.notification;
      if (notification == null) return;

      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'clix_notifications',
        'Clix Notifications',
        channelDescription: 'Notifications from Clix service',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        message.hashCode,
        notification.title,
        notification.body,
        platformChannelSpecifics,
        payload: message.data.toString(),
      );
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to show local notification', e, stackTrace);
    }
  }

  /// Handle local notification tap
  static void _onDidReceiveNotificationResponse(NotificationResponse response) {
    ClixLogger.debug('Local notification tapped: ${response.payload}');
    
    try {
      if (response.payload != null && response.payload!.isNotEmpty) {
        // Parse the payload to extract landing URL and other data
        // For now, treat payload as a simple message ID or URL
        if (response.payload!.startsWith('http')) {
          _handleLandingUrl(response.payload);
        } else {
          // Create a minimal payload for tap event
          final tapPayload = ClixPushNotificationPayload(
            messageId: response.payload!,
          );
          _notificationTappedController.add(tapPayload);
        }
      }
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to handle local notification response', e, stackTrace);
    }
  }

  /// Handle iOS foreground notification (iOS specific)
  static void _onDidReceiveLocalNotification(
      int id, String? title, String? body, String? payload) {
    ClixLogger.debug('iOS local notification received: $title');
  }

  /// Get FCM token
  static Future<String?> getToken() async {
    if (kIsWeb) return null;

    try {
      String? token = await _firebaseMessaging.getToken();
      ClixLogger.debug('FCM token retrieved: ${token?.substring(0, 20)}...');
      return token;
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to get FCM token', e, stackTrace);
      return null;
    }
  }

  /// Subscribe to topic
  static Future<bool> subscribeToTopic(String topic) async {
    if (kIsWeb) return false;

    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      ClixLogger.debug('Subscribed to topic: $topic');
      return true;
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to subscribe to topic: $topic', e, stackTrace);
      return false;
    }
  }

  /// Unsubscribe from topic
  static Future<bool> unsubscribeFromTopic(String topic) async {
    if (kIsWeb) return false;

    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      ClixLogger.debug('Unsubscribed from topic: $topic');
      return true;
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to unsubscribe from topic: $topic', e, stackTrace);
      return false;
    }
  }

  /// Set notification badge (iOS only)
  static Future<bool> setNotificationBadge(int count) async {
    if (kIsWeb || !Platform.isIOS) return false;

    try {
      // Note: FirebaseMessaging doesn't have setNotificationBadge method
      // This would need to be implemented using flutter_local_notifications
      // or a platform-specific implementation
      ClixLogger.warning('Badge setting not implemented - requires platform-specific code');
      return false;
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to set notification badge', e, stackTrace);
      return false;
    }
  }

  /// Delete FCM token
  static Future<bool> deleteToken() async {
    if (kIsWeb) return false;

    try {
      await _firebaseMessaging.deleteToken();
      await StorageService.removePushToken();
      ClixLogger.debug('FCM token deleted');
      return true;
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to delete FCM token', e, stackTrace);
      return false;
    }
  }

  /// Get notification settings
  static Future<NotificationSettings> getNotificationSettings() async {
    return await _firebaseMessaging.getNotificationSettings();
  }

  /// Dispose FCM service
  static void dispose() {
    _tokenSubscription?.cancel();
    _foregroundSubscription?.cancel();
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
}