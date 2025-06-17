import '../generated/messages.g.dart';
import '../models/clix_push_notification_payload.dart';

/// Platform service that uses Pigeon for type-safe communication
class PigeonPlatformService {
  static final PigeonPlatformService _instance = PigeonPlatformService._internal();
  factory PigeonPlatformService() => _instance;
  PigeonPlatformService._internal();

  final ClixHostApi _hostApi = ClixHostApi();
  late final ClixFlutterApi _flutterApi;

  /// Initialize the Flutter API for receiving callbacks from platform
  void initialize({
    required Function(ClixPushNotificationPayload) onNotificationReceived,
    required Function(ClixPushNotificationPayload) onNotificationOpened,
    required Function(String) onTokenRefresh,
  }) {
    _flutterApi = _ClixFlutterApiImpl(
      onNotificationReceived: onNotificationReceived,
      onNotificationOpened: onNotificationOpened,
      onTokenRefresh: onTokenRefresh,
    );
    ClixFlutterApi.setUp(_flutterApi);
  }

  /// Get FCM token from platform
  Future<String> getFcmToken() async {
    return await _hostApi.getFcmToken();
  }

  /// Get APNS token from platform (iOS only)
  Future<String> getApnsToken() async {
    return await _hostApi.getApnsToken();
  }

  /// Initialize Firebase on platform
  Future<void> initializeFirebase() async {
    return await _hostApi.initializeFirebase();
  }

  /// Request notification permissions
  Future<bool> requestPermissions() async {
    return await _hostApi.requestPermissions();
  }
}

/// Implementation of FlutterApi to handle platform callbacks
class _ClixFlutterApiImpl implements ClixFlutterApi {
  final Function(ClixPushNotificationPayload) _onNotificationReceived;
  final Function(ClixPushNotificationPayload) _onNotificationOpened;
  final Function(String) _onTokenRefresh;

  _ClixFlutterApiImpl({
    required Function(ClixPushNotificationPayload) onNotificationReceived,
    required Function(ClixPushNotificationPayload) onNotificationOpened,
    required Function(String) onTokenRefresh,
  }) : _onNotificationReceived = onNotificationReceived,
       _onNotificationOpened = onNotificationOpened,
       _onTokenRefresh = onTokenRefresh;

  @override
  void onNotificationReceived(NotificationData notification) {
    final payload = ClixPushNotificationPayload(
      messageId: notification.data?['messageId'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      landingUrl: notification.deepLink,
      imageUrl: notification.imageUrl,
      customProperties: {
        'title': notification.title,
        'body': notification.body,
        ...?notification.data?.cast<String, dynamic>(),
      },
    );
    _onNotificationReceived(payload);
  }

  @override
  void onNotificationOpened(NotificationData notification) {
    final payload = ClixPushNotificationPayload(
      messageId: notification.data?['messageId'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      landingUrl: notification.deepLink,
      imageUrl: notification.imageUrl,
      customProperties: {
        'title': notification.title,
        'body': notification.body,
        ...?notification.data?.cast<String, dynamic>(),
      },
    );
    _onNotificationOpened(payload);
  }

  @override
  void onTokenRefresh(String token) {
    _onTokenRefresh(token);
  }
}