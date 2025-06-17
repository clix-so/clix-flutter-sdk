import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/src/generated/messages.g.dart',
  dartOptions: DartOptions(),
  kotlinOut: 'android/src/main/kotlin/so/clix/Messages.g.kt',
  kotlinOptions: KotlinOptions(
    package: 'so.clix',
  ),
  swiftOut: 'ios/Classes/Messages.g.swift',
  swiftOptions: SwiftOptions(),
  dartPackageName: 'clix_flutter',
))

/// Data class for notification payload
class NotificationData {
  NotificationData({
    required this.title,
    required this.body,
    this.imageUrl,
    this.deepLink,
    this.data,
  });

  String title;
  String body;
  String? imageUrl;
  String? deepLink;
  Map<String?, String?>? data;
}

/// Data class for FCM token
class TokenData {
  TokenData({required this.token});
  String token;
}

/// Interface for host platform API calls
@HostApi()
abstract class ClixHostApi {
  /// Get the FCM token from the platform
  @async
  String getFcmToken();

  /// Get the APNS token from the platform (iOS only)
  @async
  String getApnsToken();

  /// Initialize Firebase messaging
  @async
  void initializeFirebase();

  /// Request notification permissions
  @async
  bool requestPermissions();
}

/// Interface for Flutter API calls from platform
@FlutterApi()
abstract class ClixFlutterApi {
  /// Called when a notification is received
  void onNotificationReceived(NotificationData notification);
  
  /// Called when a notification is opened
  void onNotificationOpened(NotificationData notification);

  /// Called when FCM token is refreshed
  void onTokenRefresh(String token);
}