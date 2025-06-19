import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../core/clix_config.dart';
import '../services/clix_api_client.dart';
import '../services/device_api_service.dart';
import '../services/event_api_service.dart';
import '../utils/logging/clix_logger.dart';
import 'event_service.dart';
import 'storage_service.dart';
import 'device_service.dart';
import 'token_service.dart';

class NotificationService {
  static const String _defaultNotificationIcon = '@mipmap/ic_launcher';

  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

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
        ClixLogger.warn(
            'Push notification permission denied. User needs to enable it manually in Settings.');
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
    const androidSettings =
        AndroidInitializationSettings(_defaultNotificationIcon);
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

    if (Platform.isAndroid) {
      const androidChannel = AndroidNotificationChannel(
        'clix_channel',
        'Clix Notifications',
        description: 'Notifications from Clix',
        importance: Importance.high,
        playSound: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
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

    ClixLogger.info(
        'Notification permission status: ${settings.authorizationStatus}');

    await _storageService?.set<String>(
        'notification_permission_status', settings.authorizationStatus.name);

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
      ClixLogger.debug(
          'Message notification: title="${message.notification?.title}", body="${message.notification?.body}"');

      final clixPayload = parseClixPayload(message.data);
      if (clixPayload != null) {
        ClixLogger.debug('Parsed Clix payload: $clixPayload');
        await handlePushReceived(message.data);

        await _trackPushNotificationReceived(clixPayload);

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
        ClixLogger.info(
            'App launched from notification: ${initialMessage.messageId}');
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
              ClixLogger.error(
                  'Failed to launch URL with platform default mode', e);
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
      _currentToken = await _getOrFetchToken();
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
        await _registerTokenWithServer(token);
      }
    } catch (e) {
      ClixLogger.error('Failed to update token', e);
    }
  }

  Future<void> _onTokenRefresh(String token) async {
    try {
      ClixLogger.info('FCM token refreshed');
      _currentToken = token;
      await _saveAndRegisterToken(token);
    } catch (e) {
      ClixLogger.error('Failed to handle token refresh', e);
    }
  }

  Future<void> handlePushReceived(Map<String, dynamic> userInfo) async {
    try {
      onPushReceived?.call(userInfo);
    } catch (e) {
      ClixLogger.error('Failed to handle push received', e);
    }
  }

  Future<void> handlePushTapped(Map<String, dynamic> userInfo) async {
    try {
      final clixPayload = parseClixPayload(userInfo);
      if (clixPayload != null) {
        await _trackPushEvent('PUSH_NOTIFICATION_TAPPED', clixPayload);
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

      final clixKeys = [
        'message_id',
        'campaign_id',
        'user_id',
        'device_id',
        'tracking_id'
      ];
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

  Future<void> _showClixNotification(
      RemoteMessage message, Map<String, dynamic> clixPayload) async {
    try {
      if (message.notification != null) {
        ClixLogger.debug('FCM notification exists, letting system handle it');
        return;
      }

      final notificationContent = _extractNotificationContent(clixPayload);
      ClixLogger.debug(
          'Showing Clix notification: ${notificationContent.title} - ${notificationContent.body}');

      final imagePath = notificationContent.imageUrl != null
          ? await _downloadImage(notificationContent.imageUrl!)
          : null;

      final notificationDetails = _createNotificationDetails(imagePath);

      await _localNotifications.show(
        message.hashCode,
        notificationContent.title,
        notificationContent.body,
        notificationDetails,
        payload: jsonEncode(message.data),
      );

      ClixLogger.info('Clix notification displayed successfully');
    } catch (e) {
      ClixLogger.error('Failed to show Clix notification', e);
    }
  }

  Future<bool> requestNotificationPermission() async {
    try {
      ClixLogger.info('Requesting notification permission');

      final settings = await _requestPermissions();
      final granted =
          settings.authorizationStatus == AuthorizationStatus.authorized;

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

      await _storageService?.set<Map<String, dynamic>>(
          'clix_notification_settings', settings);
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

  Future<void> reset() async {
    try {
      await _storageService?.remove('clix_notification_settings');
      await _storageService?.remove('clix_last_notification');

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

  NotificationDetails _createNotificationDetails(String? imagePath) {
    final androidDetails = AndroidNotificationDetails(
      'clix_channel',
      'Clix Notifications',
      channelDescription: 'Notifications from Clix',
      importance: Importance.high,
      priority: Priority.high,
      icon: _defaultNotificationIcon,
      largeIcon: imagePath != null
          ? FilePathAndroidBitmap(imagePath)
          : const DrawableResourceAndroidBitmap(_defaultNotificationIcon),
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

    return NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
  }

  static _NotificationContent _extractNotificationContent(
      Map<String, dynamic> payload) {
    return _NotificationContent(
      title: payload['title'] as String? ?? 'New Message',
      body: payload['body'] as String? ?? '',
      imageUrl: payload['image_url'] as String?,
    );
  }

  static Map<String, dynamic> _extractTrackingProperties(
      Map<String, dynamic>? clixPayload) {
    if (clixPayload == null) return {};

    final properties = <String, dynamic>{};

    const fieldMapping = {
      'message_id': 'messageId',
      'campaign_id': 'campaignId',
      'tracking_id': 'trackingId',
    };

    for (final entry in fieldMapping.entries) {
      final value = clixPayload[entry.key] as String?;
      if (value != null) {
        properties[entry.value] = value;
      }
    }

    return properties;
  }

  Future<void> _trackPushEvent(
      String eventType, Map<String, dynamic> clixPayload) async {
    final properties = _extractTrackingProperties(clixPayload);
    final messageId = clixPayload['message_id'] as String?;

    await _eventService?.trackEvent(
      eventType,
      properties: properties,
      messageId: messageId,
    );

    ClixLogger.info('$eventType tracked: $messageId');
  }

  Future<void> _trackPushNotificationReceived(
      Map<String, dynamic> clixPayload) async {
    final messageId = clixPayload['message_id'] as String?;
    if (messageId == null) {
      ClixLogger.warn(
          'No message_id found in payload, skipping event tracking');
      return;
    }

    if (_eventService != null) {
      await _trackPushEvent('PUSH_NOTIFICATION_RECEIVED', clixPayload);
    } else {
      await _trackPushEventInBackground(clixPayload, messageId);
    }
  }

  Future<void> _trackPushEventInBackground(
      Map<String, dynamic> clixPayload, String messageId) async {
    try {
      final storageService = StorageService();

      final configData =
          await storageService.get<Map<String, dynamic>>('clix_config');
      if (configData == null) {
        ClixLogger.error('No Clix config found in storage');
        return;
      }

      final deviceId = await storageService.get<String>('clix_device_id');
      if (deviceId == null) {
        ClixLogger.warn(
            'No device ID found in storage, generating new device ID');
        const uuid = Uuid();
        final newDeviceId = uuid.v4();
        await storageService.set<String>('clix_device_id', newDeviceId);
      }

      final config = ClixConfig.fromJson(configData);
      final properties = _extractTrackingProperties(clixPayload);

      final deviceAPIService = DeviceAPIService(
        apiClient: ClixAPIClient(config: config),
      );

      final deviceService = DeviceService(
        storageService: storageService,
        tokenService: TokenService(storageService: storageService),
        deviceAPIService: deviceAPIService,
      );

      final eventAPIService = EventAPIService(
        apiClient: ClixAPIClient(config: config),
      );

      final eventService = EventService(
        eventAPIService: eventAPIService,
        deviceService: deviceService,
      );

      await eventService.trackEvent(
        'PUSH_NOTIFICATION_RECEIVED',
        properties: properties,
        messageId: messageId,
      );

      ClixLogger.info(
          'PUSH_NOTIFICATION_RECEIVED event tracked via EventService');
    } catch (e) {
      ClixLogger.error('Error tracking event via EventService', e);
    }
  }

  static Future<String?> _downloadNotificationImage(String imageUrl) async {
    try {
      ClixLogger.info('Downloading notification image: $imageUrl');

      if (imageUrl.isEmpty) {
        ClixLogger.warn('Image URL is empty, skipping download');
        return null;
      }

      final uri = Uri.tryParse(imageUrl);
      if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
        ClixLogger.error('Invalid image URL: $imageUrl');
        return null;
      }

      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final fileName =
            'notification_image_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final file = File('${Directory.systemTemp.path}/$fileName');
        await file.writeAsBytes(response.bodyBytes);
        ClixLogger.info('Image downloaded: ${file.path}');
        return file.path;
      }
    } catch (e) {
      ClixLogger.error('Failed to download image', e);
    }
    return null;
  }

  Future<String?> _downloadImage(String imageUrl) =>
      _downloadNotificationImage(imageUrl);

  Future<String?> _getOrFetchToken() async {
    if (_tokenService != null) {
      final savedToken = await _tokenService!.getCurrentToken();
      if (savedToken != null) return savedToken;
    }

    final token = await _firebaseMessaging.getToken();
    if (token != null) {
      ClixLogger.info('Got FCM token: ${token.substring(0, 20)}...');
      await _tokenService?.saveToken(token);
    }
    return token;
  }

  Future<void> _saveAndRegisterToken(String token) async {
    if (_tokenService != null) {
      await _tokenService!.saveToken(token);
      ClixLogger.info('New FCM token saved via TokenService');
    }
    await _registerTokenWithServer(token);
  }

  Future<void> _registerTokenWithServer(String token) async {
    if (_deviceService != null) {
      await _deviceService!.upsertToken(token, tokenType: 'FCM');
      ClixLogger.info('FCM token registered with server');
    }
  }
}

class _NotificationContent {
  final String title;
  final String body;
  final String? imageUrl;

  _NotificationContent({
    required this.title,
    required this.body,
    this.imageUrl,
  });
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    ClixLogger.info('Background message received: ${message.messageId}');
    ClixLogger.debug('Background message data: ${message.data}');
    ClixLogger.debug('Background notification: ${message.notification}');

    final storageService = StorageService();
    final clixPayload = _parseClixPayloadStatic(message.data);

    await _storeBackgroundNotificationData(
        storageService, message, clixPayload);

    if (clixPayload != null) {
      await _trackPushNotificationReceivedInBackground(clixPayload);

      if (message.notification == null) {
        await _showBackgroundNotification(message, clixPayload);
      }
    }
  } catch (e) {
    ClixLogger.error('Failed to handle background message', e);
  }
}

Future<void> _trackPushNotificationReceivedInBackground(
    Map<String, dynamic> clixPayload) async {
  final messageId = clixPayload['message_id'] as String?;
  if (messageId == null) {
    ClixLogger.warn('No message_id found in payload, skipping event tracking');
    return;
  }

  try {
    final storageService = StorageService();

    final configData =
        await storageService.get<Map<String, dynamic>>('clix_config');
    if (configData == null) {
      ClixLogger.error('No Clix config found in storage');
      return;
    }

    final deviceId = await storageService.get<String>('clix_device_id');
    if (deviceId == null) {
      ClixLogger.warn(
          'No device ID found in storage, generating new device ID');
      const uuid = Uuid();
      final newDeviceId = uuid.v4();
      await storageService.set<String>('clix_device_id', newDeviceId);
    }

    final config = ClixConfig.fromJson(configData);
    final properties =
        NotificationService._extractTrackingProperties(clixPayload);

    final deviceAPIService = DeviceAPIService(
      apiClient: ClixAPIClient(config: config),
    );

    final deviceService = DeviceService(
      storageService: storageService,
      tokenService: TokenService(storageService: storageService),
      deviceAPIService: deviceAPIService,
    );

    final eventAPIService = EventAPIService(
      apiClient: ClixAPIClient(config: config),
    );

    final eventService = EventService(
      eventAPIService: eventAPIService,
      deviceService: deviceService,
    );

    await eventService.trackEvent(
      'PUSH_NOTIFICATION_RECEIVED',
      properties: properties,
      messageId: messageId,
    );

    ClixLogger.info(
        'PUSH_NOTIFICATION_RECEIVED event tracked via EventService in background');
  } catch (e) {
    ClixLogger.error('Error tracking event via EventService in background', e);
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

    final clixKeys = [
      'message_id',
      'campaign_id',
      'user_id',
      'device_id',
      'tracking_id'
    ];
    if (clixKeys.any((key) => userInfo.containsKey(key))) {
      return userInfo;
    }

    return null;
  } catch (e) {
    return null;
  }
}

Future<void> _storeBackgroundNotificationData(
  StorageService storageService,
  RemoteMessage message,
  Map<String, dynamic>? clixPayload,
) async {
  final notificationData = {
    'messageId': message.messageId,
    'data': message.data,
    'timestamp': DateTime.now().millisecondsSinceEpoch,
    'clixMessageId': clixPayload?['message_id'] as String?,
    'campaignId': clixPayload?['campaign_id'] as String?,
    'trackingId': clixPayload?['tracking_id'] as String?,
  };

  await storageService.set<Map<String, dynamic>>(
      'last_background_notification', notificationData);
}

Future<void> _showBackgroundNotification(
  RemoteMessage message,
  Map<String, dynamic> clixPayload,
) async {
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  await _initializeBackgroundNotifications(flutterLocalNotificationsPlugin);

  final content = NotificationService._extractNotificationContent(clixPayload);
  final imagePath = content.imageUrl != null
      ? await NotificationService._downloadNotificationImage(content.imageUrl!)
      : null;

  final notificationDetails = _createBackgroundNotificationDetails(imagePath);

  await flutterLocalNotificationsPlugin.show(
    message.hashCode,
    content.title,
    content.body,
    notificationDetails,
    payload: jsonEncode(message.data),
  );

  ClixLogger.info('Background notification shown: ${content.title}');
}

Future<void> _initializeBackgroundNotifications(
    FlutterLocalNotificationsPlugin plugin) async {
  const androidSettings = AndroidInitializationSettings(
      NotificationService._defaultNotificationIcon);
  const initSettings = InitializationSettings(android: androidSettings);
  await plugin.initialize(initSettings);

  const androidChannel = AndroidNotificationChannel(
    'clix_channel',
    'Clix Notifications',
    description: 'Notifications from Clix',
    importance: Importance.high,
    playSound: true,
  );

  await plugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(androidChannel);
}

NotificationDetails _createBackgroundNotificationDetails(String? imagePath) {
  final androidDetails = AndroidNotificationDetails(
    'clix_channel',
    'Clix Notifications',
    channelDescription: 'Notifications from Clix',
    importance: Importance.high,
    priority: Priority.high,
    icon: NotificationService._defaultNotificationIcon,
    largeIcon: imagePath != null
        ? FilePathAndroidBitmap(imagePath)
        : const DrawableResourceAndroidBitmap(
            NotificationService._defaultNotificationIcon),
    styleInformation: imagePath != null
        ? BigPictureStyleInformation(
            FilePathAndroidBitmap(imagePath),
            largeIcon: FilePathAndroidBitmap(imagePath),
          )
        : null,
  );

  return NotificationDetails(android: androidDetails);
}
