import 'dart:io';
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/logging/clix_logger.dart';
import 'storage_service.dart';

/// Firebase service for handling FCM tokens and notifications
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  StorageService? _storageService;
  
  bool _isInitialized = false;
  String? _currentToken;

  /// Callback for handling push received events
  Function(Map<String, dynamic>)? onPushReceived;
  
  /// Callback for handling push tapped events
  Function(Map<String, dynamic>)? onPushTapped;

  /// Initialize Firebase service
  Future<void> initialize({
    required StorageService storageService,
    Function(Map<String, dynamic>)? onPushReceived,
    Function(Map<String, dynamic>)? onPushTapped,
  }) async {
    if (_isInitialized) return;

    _storageService = storageService;
    this.onPushReceived = onPushReceived;
    this.onPushTapped = onPushTapped;

    try {
      ClixLogger.info('Initializing Firebase service');

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Request permission
      await _requestPermissions();

      // Set up message handlers
      _setupMessageHandlers();

      // Get initial token
      await _getAndUpdateToken();

      // Listen for token changes
      _firebaseMessaging.onTokenRefresh.listen(_onTokenRefresh);

      _isInitialized = true;
      ClixLogger.info('Firebase service initialized successfully');
    } catch (e) {
      ClixLogger.error('Failed to initialize Firebase service', e);
      rethrow;
    }
  }

  /// Initialize local notifications plugin
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onLocalNotificationTapped,
    );
  }

  /// Request notification permissions
  Future<NotificationSettings> _requestPermissions() async {
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    ClixLogger.info('Notification permission status: ${settings.authorizationStatus}');
    return settings;
  }

  /// Set up message handlers for different states
  void _setupMessageHandlers() {
    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // Handle notification taps when app is in background/terminated
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);

    // Handle initial message when app is launched from terminated state
    _handleInitialMessage();
  }

  /// Handle messages when app is in foreground
  Future<void> _onForegroundMessage(RemoteMessage message) async {
    try {
      ClixLogger.info('Received foreground message: ${message.messageId}');

      // Parse Clix payload and notify callback
      final clixPayload = parseClixPayload(message.data);
      if (clixPayload != null) {
        onPushReceived?.call(message.data);
      }

      // Show local notification if needed
      await _showLocalNotification(message);
    } catch (e) {
      ClixLogger.error('Failed to handle foreground message', e);
    }
  }

  /// Handle notification tap when app is opened from background
  Future<void> _onMessageOpenedApp(RemoteMessage message) async {
    try {
      ClixLogger.info('App opened from notification: ${message.messageId}');
      await _handleNotificationTap(message.data);
    } catch (e) {
      ClixLogger.error('Failed to handle message opened app', e);
    }
  }

  /// Handle initial message when app is launched from terminated state
  Future<void> _handleInitialMessage() async {
    try {
      final initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        ClixLogger.info('App launched from notification: ${initialMessage.messageId}');
        await _handleNotificationTap(initialMessage.data);
      }
    } catch (e) {
      ClixLogger.error('Failed to handle initial message', e);
    }
  }

  /// Handle local notification tap
  void _onLocalNotificationTapped(NotificationResponse response) {
    try {
      final payload = response.payload;
      if (payload != null) {
        // Parse stored notification data and handle tap
        final Map<String, dynamic> data = jsonDecode(payload);
        _handleNotificationTap(data);
      }
    } catch (e) {
      ClixLogger.error('Failed to handle local notification tap', e);
    }
  }

  /// Handle notification tap (both from FCM and local notifications)
  Future<void> _handleNotificationTap(Map<String, dynamic> data) async {
    try {
      // Track notification tap
      final clixPayload = parseClixPayload(data);
      if (clixPayload != null) {
        onPushTapped?.call(data);
      }

      // Handle URL navigation
      await _handleUrlNavigation(data);
    } catch (e) {
      ClixLogger.error('Failed to handle notification tap', e);
    }
  }

  /// Handle URL navigation from notification
  Future<void> _handleUrlNavigation(Map<String, dynamic> data) async {
    try {
      String? url;

      // Check Clix payload first
      final clixPayload = parseClixPayload(data);
      if (clixPayload != null) {
        url = clixPayload['landing_url'] as String?;
      }

      // Fallback to common URL fields
      url ??= data['landing_url'] as String? ??
             data['url'] as String? ??
             data['link'] as String? ??
             data['click_action'] as String?;

      if (url != null && url.isNotEmpty) {
        ClixLogger.info('Opening URL from notification: $url');
        final uri = Uri.parse(url);
        
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          ClixLogger.info('URL opened successfully: $url');
        } else {
          ClixLogger.warn('Cannot launch URL: $url');
        }
      }
    } catch (e) {
      ClixLogger.error('Failed to handle URL navigation', e);
    }
  }

  /// Show local notification for foreground messages
  Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      final notification = message.notification;
      if (notification == null) return;

      // Download image if available
      String? imagePath;
      final imageUrl = extractImageURL(message.data);
      if (imageUrl != null) {
        imagePath = await _downloadAndCacheImage(imageUrl);
      }

      // Create notification with image
      final androidDetails = AndroidNotificationDetails(
        'clix_channel',
        'Clix Notifications',
        channelDescription: 'Notifications from Clix',
        importance: Importance.high,
        priority: Priority.high,
        largeIcon: imagePath != null ? FilePathAndroidBitmap(imagePath) : null,
        styleInformation: imagePath != null 
          ? BigPictureStyleInformation(
              FilePathAndroidBitmap(imagePath),
              largeIcon: FilePathAndroidBitmap(imagePath),
            )
          : null,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        message.hashCode,
        notification.title,
        notification.body,
        notificationDetails,
        payload: jsonEncode(message.data),
      );
    } catch (e) {
      ClixLogger.error('Failed to show local notification', e);
    }
  }

  /// Download and cache notification image
  Future<String?> _downloadAndCacheImage(String imageUrl) async {
    try {
      final imageData = await _downloadNotificationImage(imageUrl);
      if (imageData != null && imageData.isNotEmpty) {
        // Cache image to temporary directory
        final fileName = 'notification_image_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final file = File('${Directory.systemTemp.path}/$fileName');
        await file.writeAsBytes(imageData);
        return file.path;
      }
    } catch (e) {
      ClixLogger.error('Failed to download notification image', e);
    }
    return null;
  }

  /// Download notification image
  Future<List<int>?> _downloadNotificationImage(String imageUrl) async {
    try {
      ClixLogger.info('Downloading notification image: $imageUrl');
      
      final httpClient = HttpClient();
      final uri = Uri.parse(imageUrl);
      final request = await httpClient.getUrl(uri);
      final response = await request.close();
      
      if (response.statusCode == 200) {
        final bytes = <int>[];
        await for (final chunk in response) {
          bytes.addAll(chunk);
        }
        
        ClixLogger.info('Notification image downloaded successfully (${bytes.length} bytes)');
        httpClient.close();
        return bytes;
      } else {
        ClixLogger.warn('Failed to download image: HTTP ${response.statusCode}');
        httpClient.close();
        return null;
      }
    } catch (e) {
      ClixLogger.error('Failed to download notification image', e);
      return null;
    }
  }

  /// Parse Clix payload from notification data
  Map<String, dynamic>? parseClixPayload(Map<String, dynamic> userInfo) {
    try {
      // Check for direct Clix data
      if (userInfo.containsKey('clix')) {
        final clixData = userInfo['clix'];
        if (clixData is Map<String, dynamic>) {
          return clixData;
        }
        if (clixData is String) {
          return jsonDecode(clixData) as Map<String, dynamic>;
        }
      }

      // Check for Clix keys at root level
      final clixKeys = ['message_id', 'campaign_id', 'user_id', 'device_id', 'tracking_id'];
      if (clixKeys.any((key) => userInfo.containsKey(key))) {
        return userInfo;
      }

      return null;
    } catch (e) {
      ClixLogger.error('Failed to parse Clix payload', e);
      return null;
    }
  }

  /// Extract image URL from notification
  String? extractImageURL(Map<String, dynamic> userInfo) {
    try {
      // First check Clix payload
      final clixPayload = parseClixPayload(userInfo);
      if (clixPayload != null) {
        final imageUrl = clixPayload['image_url'] as String?;
        if (imageUrl != null && imageUrl.isNotEmpty) {
          return imageUrl;
        }
      }

      // Fallback to traditional sources
      return _extractImageURLFromTraditionalSources(userInfo);
    } catch (e) {
      ClixLogger.error('Failed to extract image URL', e);
      return null;
    }
  }

  /// Extract image URL from traditional FCM sources
  String? _extractImageURLFromTraditionalSources(Map<String, dynamic> userInfo) {
    try {
      // Check common FCM image fields
      final imageFields = ['image', 'picture', 'image_url', 'imageUrl'];
      for (final field in imageFields) {
        final value = userInfo[field] as String?;
        if (value != null && value.isNotEmpty) {
          return value;
        }
      }

      // Check FCM options
      final fcmOptions = userInfo['fcm_options'] as Map<String, dynamic>?;
      if (fcmOptions != null) {
        final image = fcmOptions['image'] as String?;
        if (image != null && image.isNotEmpty) {
          return image;
        }
      }

      return null;
    } catch (e) {
      ClixLogger.error('Failed to extract image URL from traditional sources', e);
      return null;
    }
  }

  /// Get current FCM token
  Future<String?> getCurrentToken() async {
    try {
      if (_currentToken != null) return _currentToken;
      
      _currentToken = await _firebaseMessaging.getToken();
      ClixLogger.info('Got FCM token: ${_currentToken?.substring(0, 20)}...');
      return _currentToken;
    } catch (e) {
      ClixLogger.error('Failed to get FCM token', e);
      return null;
    }
  }

  /// Get and update token
  Future<void> _getAndUpdateToken() async {
    try {
      final token = await getCurrentToken();
      if (token != null) {
        await _storageService?.setString('fcm_token', token);
        ClixLogger.info('FCM token updated in storage');
      }
    } catch (e) {
      ClixLogger.error('Failed to update token', e);
    }
  }

  /// Handle token refresh
  Future<void> _onTokenRefresh(String token) async {
    try {
      ClixLogger.info('FCM token refreshed');
      _currentToken = token;
      await _storageService?.setString('fcm_token', token);
      
      // Notify that token has been refreshed
      // The main SDK should listen for this and update device registration
    } catch (e) {
      ClixLogger.error('Failed to handle token refresh', e);
    }
  }

  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      ClixLogger.info('Subscribed to topic: $topic');
    } catch (e) {
      ClixLogger.error('Failed to subscribe to topic: $topic', e);
      rethrow;
    }
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      ClixLogger.info('Unsubscribed from topic: $topic');
    } catch (e) {
      ClixLogger.error('Failed to unsubscribe from topic: $topic', e);
      rethrow;
    }
  }

  /// Set badge count (iOS only)
  Future<void> setBadgeCount(int count) async {
    if (Platform.isIOS) {
      try {
        await _firebaseMessaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
        ClixLogger.info('Badge count set to: $count');
      } catch (e) {
        ClixLogger.error('Failed to set badge count', e);
      }
    }
  }

  /// Check if Firebase is initialized
  bool get isInitialized => _isInitialized;

  /// Get current token (cached)
  String? get currentToken => _currentToken;
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    ClixLogger.info('Background message received: ${message.messageId}');
    
    // Store background notification for later processing
    final storageService = StorageService();
    await storageService.initialize();
    
    final notificationData = {
      'messageId': message.messageId,
      'data': message.data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    
    await storageService.setJson('last_background_notification', notificationData);
  } catch (e) {
    ClixLogger.error('Failed to handle background message', e);
  }
}