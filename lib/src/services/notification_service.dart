import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../utils/logging/clix_logger.dart';
import 'event_service.dart';
import 'storage_service.dart';
import 'device_service.dart';
import 'token_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  EventService? _eventService;
  StorageService? _storageService;
  DeviceService? _deviceService;
  TokenService? _tokenService;
  
  bool _isInitialized = false;
  String? _currentToken;

  Function(Map<String, dynamic>)? onPushReceived;
  Function(Map<String, dynamic>)? onPushTapped;

  Future<void> initialize({
    required EventService eventService,
    required StorageService storageService,
    DeviceService? deviceService,
    TokenService? tokenService,
    Function(Map<String, dynamic>)? onPushReceived,
    Function(Map<String, dynamic>)? onPushTapped,
  }) async {
    if (_isInitialized) return;

    _eventService = eventService;
    _storageService = storageService;
    _deviceService = deviceService;
    _tokenService = tokenService;
    this.onPushReceived = onPushReceived;
    this.onPushTapped = onPushTapped;

    try {
      ClixLogger.info('Initializing notification service');

      await _initializeLocalNotifications();
      final settings = await _requestPermissions();
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        ClixLogger.warn('Push notification permission denied. User needs to enable it manually in Settings.');
      }
      _setupMessageHandlers();
      
      if (settings.authorizationStatus != AuthorizationStatus.denied) {
        await _getAndUpdateToken();
        _firebaseMessaging.onTokenRefresh.listen(_onTokenRefresh);
      } else {
        ClixLogger.info('Skipping token setup due to denied permissions');
      }


      _isInitialized = true;
      ClixLogger.info('Notification service initialized successfully');
    } catch (e) {
      ClixLogger.error('Failed to initialize notification service', e);
      rethrow;
    }
  }

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

    // Android 알림 채널 생성
    if (Platform.isAndroid) {
      const androidChannel = AndroidNotificationChannel(
        'clix_channel',
        'Clix Notifications',
        description: 'Notifications from Clix',
        importance: Importance.high,
        playSound: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);
    }
  }

  void _onLocalNotificationTapped(NotificationResponse response) {
    try {
      final payload = response.payload;
      if (payload != null) {
        final Map<String, dynamic> data = jsonDecode(payload);
        _handleNotificationTap(data);
      }
    } catch (e) {
      ClixLogger.error('Failed to handle local notification tap', e);
    }
  }

  Future<NotificationSettings> _requestPermissions() async {
    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
    );

    ClixLogger.info('Notification permission status: ${settings.authorizationStatus}');
    
    await _storageService?.set<String>('notification_permission_status', settings.authorizationStatus.name);
    
    
    return settings;
  }

  void _setupMessageHandlers() {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);
    _handleInitialMessage();
    
  }

  Future<void> _onForegroundMessage(RemoteMessage message) async {
    try {
      ClixLogger.info('Received foreground message: ${message.messageId}');
      ClixLogger.debug('Message data: ${message.data}');
      ClixLogger.debug('Message notification: title="${message.notification?.title}", body="${message.notification?.body}"');

      // 앱이 foreground이므로 pending events 처리
      await _processPendingEvents();

      final clixPayload = parseClixPayload(message.data);
      if (clixPayload != null) {
        ClixLogger.debug('Parsed Clix payload: $clixPayload');
        await handlePushReceived(message.data);
        
        // Clix 페이로드에서 알림 표시
        await _showClixNotification(message, clixPayload);
      } else {
        ClixLogger.warn('No Clix payload found in message');
      }
    } catch (e) {
      ClixLogger.error('Failed to handle foreground message', e);
    }
  }

  Future<void> _onMessageOpenedApp(RemoteMessage message) async {
    try {
      ClixLogger.info('App opened from notification: ${message.messageId}');
      await _handleNotificationTap(message.data);
    } catch (e) {
      ClixLogger.error('Failed to handle message opened app', e);
    }
  }

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


  Future<void> _handleNotificationTap(Map<String, dynamic> data) async {
    try {
      final clixPayload = parseClixPayload(data);
      if (clixPayload != null) {
        await handlePushTapped(data);
      }

      await _handleUrlNavigation(data);
    } catch (e) {
      ClixLogger.error('Failed to handle notification tap', e);
    }
  }

  Future<void> _handleUrlNavigation(Map<String, dynamic> data) async {
    try {
      String? url;

      final clixPayload = parseClixPayload(data);
      if (clixPayload != null) {
        url = clixPayload['landing_url'] as String?;
      }

      url ??= data['landing_url'] as String? ??
             data['url'] as String? ??
             data['link'] as String? ??
             data['click_action'] as String?;

      if (url != null && url.isNotEmpty) {
        ClixLogger.info('Opening URL from notification: $url');
        
        try {
          final uri = Uri.parse(url);
          ClixLogger.debug('Parsed URI: $uri');
          
          final canLaunch = await canLaunchUrl(uri);
          ClixLogger.debug('Can launch URL: $canLaunch');
          
          if (canLaunch) {
            await launchUrl(
              uri, 
              mode: LaunchMode.externalApplication,
              webViewConfiguration: const WebViewConfiguration(
                enableJavaScript: true,
                enableDomStorage: true,
              ),
            );
            ClixLogger.info('URL opened successfully: $url');
          } else {
            ClixLogger.warn('Cannot launch URL: $url');
            try {
              await launchUrl(uri, mode: LaunchMode.platformDefault);
              ClixLogger.info('URL opened with platform default mode: $url');
            } catch (e) {
              ClixLogger.error('Failed to launch URL with platform default mode', e);
            }
          }
        } catch (e) {
          ClixLogger.error('Error parsing or launching URL: $url', e);
        }
      }
    } catch (e) {
      ClixLogger.error('Failed to handle URL navigation', e);
    }
  }



  Future<String?> getCurrentToken() async {
    try {
      if (_tokenService != null) {
        final savedToken = await _tokenService!.getCurrentToken();
        if (savedToken != null) {
          _currentToken = savedToken;
          return savedToken;
        }
      }
      
      
      _currentToken = await _firebaseMessaging.getToken();
      ClixLogger.info('Got FCM token: ${_currentToken?.substring(0, 20)}...');
      
      if (_currentToken != null && _tokenService != null) {
        await _tokenService!.saveToken(_currentToken!);
      }
      
      return _currentToken;
    } catch (e) {
      ClixLogger.error('Failed to get FCM token', e);
      return null;
    }
  }

  Future<void> _getAndUpdateToken() async {
    try {
      final token = await getCurrentToken();
      if (token != null) {
        ClixLogger.info('FCM token updated via TokenService');
        
        if (_deviceService != null) {
          await _deviceService!.upsertToken(token, tokenType: 'FCM');
          ClixLogger.info('Initial FCM token registered with server');
        }
      }
    } catch (e) {
      ClixLogger.error('Failed to update token', e);
    }
  }

  Future<void> _onTokenRefresh(String token) async {
    try {
      ClixLogger.info('FCM token refreshed');
      _currentToken = token;
      
      if (_tokenService != null) {
        await _tokenService!.saveToken(token);
        ClixLogger.info('New FCM token saved via TokenService');
      }
      
      if (_deviceService != null) {
        await _deviceService!.upsertToken(token, tokenType: 'FCM');
        ClixLogger.info('New FCM token registered with server');
      }
    } catch (e) {
      ClixLogger.error('Failed to handle token refresh', e);
    }
  }

  Future<void> handlePushReceived(Map<String, dynamic> userInfo) async {
    try {
      final clixPayload = parseClixPayload(userInfo);
      if (clixPayload != null) {
        final messageId = clixPayload['message_id'] as String?;
        final campaignId = clixPayload['campaign_id'] as String?;
        final trackingId = clixPayload['tracking_id'] as String?;
        
        final properties = <String, dynamic>{};
        if (messageId != null) properties['messageId'] = messageId;
        if (campaignId != null) properties['campaignId'] = campaignId;
        if (trackingId != null) properties['trackingId'] = trackingId;
        
        await _eventService?.trackEvent(
          'PUSH_NOTIFICATION_RECEIVED',
          properties: properties,
          messageId: messageId,
        );
        ClixLogger.info('Push notification received tracked: $messageId');
      }
      onPushReceived?.call(userInfo);
    } catch (e) {
      ClixLogger.error('Failed to handle push received', e);
    }
  }

  Future<void> handlePushTapped(Map<String, dynamic> userInfo) async {
    try {
      final clixPayload = parseClixPayload(userInfo);
      if (clixPayload != null) {
        final messageId = clixPayload['message_id'] as String?;
        final campaignId = clixPayload['campaign_id'] as String?;
        final trackingId = clixPayload['tracking_id'] as String?;
        
        final properties = <String, dynamic>{};
        if (messageId != null) properties['messageId'] = messageId;
        if (campaignId != null) properties['campaignId'] = campaignId;
        if (trackingId != null) properties['trackingId'] = trackingId;
        
        await _eventService?.trackEvent(
          'PUSH_NOTIFICATION_TAPPED',
          properties: properties,
          messageId: messageId,
        );
        ClixLogger.info('Push notification tapped tracked: $messageId');
      }
      onPushTapped?.call(userInfo);
    } catch (e) {
      ClixLogger.error('Failed to handle push tapped', e);
    }
  }

  Map<String, dynamic>? parseClixPayload(Map<String, dynamic> userInfo) {
    try {
      if (userInfo.containsKey('clix')) {
        final clixData = userInfo['clix'];
        if (clixData is Map<String, dynamic>) {
          return clixData;
        }
        if (clixData is String) {
          return jsonDecode(clixData) as Map<String, dynamic>;
        }
      }

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

  String? getMessageId(Map<String, dynamic> userInfo) {
    final clixPayload = parseClixPayload(userInfo);
    return clixPayload?['message_id'] as String?;
  }

  Future<void> _showClixNotification(RemoteMessage message, Map<String, dynamic> clixPayload) async {
    try {
      // FCM 기본 알림이 있으면 시스템이 처리하도록 함
      if (message.notification != null) {
        ClixLogger.debug('FCM notification exists, letting system handle it');
        return;
      }

      // Clix 페이로드에서 제목과 본문 추출
      final title = clixPayload['title'] as String? ?? 'New Message';
      final body = clixPayload['body'] as String? ?? '';
      final imageUrl = clixPayload['image_url'] as String?;

      ClixLogger.debug('Showing Clix notification: $title - $body');

      // 이미지 처리
      String? imagePath;
      if (imageUrl != null) {
        imagePath = await _downloadAndCacheImage(imageUrl);
      }

      // 플랫폼별 알림 설정
      final androidDetails = AndroidNotificationDetails(
        'clix_channel',
        'Clix Notifications',
        channelDescription: 'Notifications from Clix',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
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
        title,
        body,
        notificationDetails,
        payload: jsonEncode(message.data),
      );
      
      ClixLogger.info('Clix notification displayed successfully');
    } catch (e) {
      ClixLogger.error('Failed to show Clix notification', e);
    }
  }

  Future<String?> _downloadAndCacheImage(String imageUrl) async {
    try {
      ClixLogger.info('Downloading notification image: $imageUrl');
      
      final response = await http.get(Uri.parse(imageUrl));
      
      if (response.statusCode == 200) {
        final fileName = 'notification_image_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final file = File('${Directory.systemTemp.path}/$fileName');
        await file.writeAsBytes(response.bodyBytes);
        ClixLogger.info('Image downloaded and cached: ${file.path}');
        return file.path;
      }
    } catch (e) {
      ClixLogger.error('Failed to download notification image', e);
    }
    return null;
  }






  Future<bool> requestNotificationPermission() async {
    try {
      ClixLogger.info('Requesting notification permission');
      
      final settings = await _requestPermissions();
      final granted = settings.authorizationStatus == AuthorizationStatus.authorized;
      
      ClixLogger.info('Notification permission granted: $granted');
      return granted;
    } catch (e) {
      ClixLogger.error('Failed to request notification permission', e);
      return false;
    }
  }


  Future<void> setNotificationPreferences({
    required bool enabled,
    List<String>? categories,
  }) async {
    try {
      final settings = {
        'enabled': enabled,
        'categories': categories ?? [],
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      
      await _storageService?.set<Map<String, dynamic>>('clix_notification_settings', settings);
      ClixLogger.info('Notification preferences saved: enabled=$enabled');
    } catch (e) {
      ClixLogger.error('Failed to set notification preferences', e);
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      ClixLogger.info('Subscribed to topic: $topic');
    } catch (e) {
      ClixLogger.error('Failed to subscribe to topic: $topic', e);
      rethrow;
    }
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      ClixLogger.info('Unsubscribed from topic: $topic');
    } catch (e) {
      ClixLogger.error('Failed to unsubscribe from topic: $topic', e);
      rethrow;
    }
  }

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

  Future<void> _processPendingEvents() async {
    try {
      final pendingEvents = await _storageService?.get<List<dynamic>>('pending_push_events') ?? [];
      
      if (pendingEvents.isNotEmpty) {
        ClixLogger.info('Processing ${pendingEvents.length} pending push events');
        
        for (final eventData in pendingEvents) {
          if (eventData is Map<String, dynamic>) {
            final eventType = eventData['eventType'] as String?;
            final messageId = eventData['messageId'] as String?;
            final campaignId = eventData['campaignId'] as String?;
            final trackingId = eventData['trackingId'] as String?;
            
            if (eventType != null) {
              final properties = <String, dynamic>{};
              if (messageId != null) properties['messageId'] = messageId;
              if (campaignId != null) properties['campaignId'] = campaignId;
              if (trackingId != null) properties['trackingId'] = trackingId;
              
              await _eventService?.trackEvent(
                eventType,
                properties: properties,
                messageId: messageId,
              );
              
              ClixLogger.info('Processed pending event: $eventType for message: $messageId');
            }
          }
        }
        
        await _storageService?.remove('pending_push_events');
        ClixLogger.info('Cleared ${pendingEvents.length} processed pending events');
      }
    } catch (e) {
      ClixLogger.error('Failed to process pending events', e);
    }
  }

  Future<void> reset() async {
    try {
      await _storageService?.remove('clix_notification_settings');
      await _storageService?.remove('clix_last_notification');
      await _storageService?.remove('pending_push_events');
      
      if (_tokenService != null) {
        await _tokenService!.reset();
      }
      
      _currentToken = null;
      ClixLogger.info('Notification data reset completed');
    } catch (e) {
      ClixLogger.error('Failed to reset notification data', e);
    }
  }

  bool get isInitialized => _isInitialized;
  String? get currentToken => _currentToken;
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    ClixLogger.info('Background message received: ${message.messageId}');
    ClixLogger.debug('Background message data: ${message.data}');
    ClixLogger.debug('Background notification: ${message.notification}');
    
    final storageService = StorageService();
    
    final clixPayload = _parseClixPayloadStatic(message.data);
    final messageId = clixPayload?['message_id'] as String?;
    final campaignId = clixPayload?['campaign_id'] as String?;
    final trackingId = clixPayload?['tracking_id'] as String?;
    
    final notificationData = {
      'messageId': message.messageId,
      'data': message.data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'clixMessageId': messageId,
      'campaignId': campaignId,
      'trackingId': trackingId,
    };
    
    await storageService.set<Map<String, dynamic>>('last_background_notification', notificationData);
    
    if (clixPayload != null) {
      final pendingEvent = {
        'eventType': 'PUSH_NOTIFICATION_RECEIVED',
        'messageId': messageId,
        'campaignId': campaignId,
        'trackingId': trackingId,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      
      final existingEvents = await storageService.get<List<dynamic>>('pending_push_events') ?? [];
      existingEvents.add(pendingEvent);
      await storageService.set<List<dynamic>>('pending_push_events', existingEvents);
      
      ClixLogger.info('Background push event stored for later tracking: $messageId');
      
      // Clix 페이로드로 알림 표시 (data-only 메시지)
      if (message.notification == null && clixPayload != null) {
        final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
        
        // 백그라운드에서 알림 초기화
        const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
        const initSettings = InitializationSettings(android: androidSettings);
        await flutterLocalNotificationsPlugin.initialize(initSettings);
        
        // 알림 채널 생성
        const androidChannel = AndroidNotificationChannel(
          'clix_channel',
          'Clix Notifications',
          description: 'Notifications from Clix',
          importance: Importance.high,
          playSound: true,
        );
        
        await flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(androidChannel);
        
        // Clix 페이로드에서 알림 데이터 추출
        final title = clixPayload['title'] as String? ?? 'New Message';
        final body = clixPayload['body'] as String? ?? '';
        final imageUrl = clixPayload['image_url'] as String?;
        
        // 이미지 다운로드
        String? imagePath;
        if (imageUrl != null) {
          try {
            final response = await http.get(Uri.parse(imageUrl));
            if (response.statusCode == 200) {
              final fileName = 'notification_image_${DateTime.now().millisecondsSinceEpoch}.jpg';
              final file = File('${Directory.systemTemp.path}/$fileName');
              await file.writeAsBytes(response.bodyBytes);
              imagePath = file.path;
              ClixLogger.info('Background image downloaded: $imagePath');
            }
          } catch (e) {
            ClixLogger.error('Failed to download background image', e);
          }
        }
        
        // 알림 표시
        final androidDetails = AndroidNotificationDetails(
          'clix_channel',
          'Clix Notifications',
          channelDescription: 'Notifications from Clix',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          largeIcon: imagePath != null ? FilePathAndroidBitmap(imagePath) : null,
          styleInformation: imagePath != null 
            ? BigPictureStyleInformation(
                FilePathAndroidBitmap(imagePath),
                largeIcon: FilePathAndroidBitmap(imagePath),
              )
            : null,
        );
        
        final notificationDetails = NotificationDetails(android: androidDetails);
        
        await flutterLocalNotificationsPlugin.show(
          message.hashCode,
          title,
          body,
          notificationDetails,
          payload: jsonEncode(message.data),
        );
        
        ClixLogger.info('Background notification shown: $title');
      }
    }
  } catch (e) {
    ClixLogger.error('Failed to handle background message', e);
  }
}

Map<String, dynamic>? _parseClixPayloadStatic(Map<String, dynamic> userInfo) {
  try {
    if (userInfo.containsKey('clix')) {
      final clixData = userInfo['clix'];
      if (clixData is Map<String, dynamic>) {
        return clixData;
      }
      if (clixData is String) {
        return jsonDecode(clixData) as Map<String, dynamic>;
      }
    }

    final clixKeys = ['message_id', 'campaign_id', 'user_id', 'device_id', 'tracking_id'];
    if (clixKeys.any((key) => userInfo.containsKey(key))) {
      return userInfo;
    }

    return null;
  } catch (e) {
    return null;
  }
}

