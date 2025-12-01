# Clix Flutter SDK

Clix Flutter SDK is a powerful tool for managing push notifications and user events in your Flutter application. It provides a simple and intuitive interface for user engagement and analytics.

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  clix_flutter: ^0.0.2
```

Then run:

```bash
flutter pub get
```

## Requirements

- **Flutter 3.33.0 or later** (required for iOS debug mode on iOS 26+)
- Dart 2.17.0 or later
- iOS 14.0+ / Android API 23+
- Firebase Cloud Messaging

## Usage

### Initialization

Initialize the SDK with a ClixConfig object. The config is required and contains your project settings.

```dart
import 'package:clix_flutter/clix_flutter.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase first
  await Firebase.initializeApp();

  // Initialize Clix SDK
  await Clix.initialize(const ClixConfig(
    projectId: 'YOUR_PROJECT_ID',
    apiKey: 'YOUR_API_KEY',
    endpoint: 'https://api.clix.so',      // Optional: default is https://api.clix.so
    logLevel: ClixLogLevel.debug,          // Optional: set log level
  ));

  // Configure notifications (optional)
  await Clix.Notification.configure(
    autoRequestPermission: true,           // Request permission immediately
    autoHandleLandingURL: true,            // Auto-open landing URLs on tap
  );

  runApp(MyApp());
}
```

### User Management

```dart
// Set user ID
await Clix.setUserId('user123');

// Set user properties
await Clix.setUserProperty('name', 'John Doe');
await Clix.setUserProperties({
  'age': 25,
  'premium': true,
});

// Remove user properties
await Clix.removeUserProperty('name');
await Clix.removeUserProperties(['age', 'premium']);

// Remove user ID
await Clix.removeUserId();
```

### Event Tracking

```dart
// Track an event with properties
await Clix.trackEvent(
  'signup_completed',
  properties: {
    'method': 'email',
    'discount_applied': true,
    'trial_days': 14,
    'completed_at': DateTime.now(),
  },
);
```

### Device Information

```dart
// Get device ID
final deviceId = await Clix.getDeviceId();

// Get push token
final pushToken = await Clix.Notification.getToken();
```

### Logging

```dart
Clix.setLogLevel(ClixLogLevel.debug);
// Available log levels:
// - ClixLogLevel.none: No logs
// - ClixLogLevel.error: Error logs only
// - ClixLogLevel.warning: Warning logs
// - ClixLogLevel.info: Info logs
// - ClixLogLevel.debug: Debug logs
// - ClixLogLevel.verbose: All logs
```

### Push Notification Integration

The Clix Flutter SDK automatically handles push notification integration through Firebase Cloud Messaging.

#### 1. Firebase Setup

**iOS:**
1. Add your `GoogleService-Info.plist` to the iOS project in Xcode
2. Enable Push Notifications capability in your iOS project
3. Add Background Modes capability and check "Remote notifications"

**Android:**
1. Add your `google-services.json` to `android/app/`
2. Firebase configuration is handled automatically by FlutterFire

#### 2. Configure Notification Handlers

Register handlers for push notification events:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  await Clix.initialize(const ClixConfig(
    projectId: 'YOUR_PROJECT_ID',
    apiKey: 'YOUR_API_KEY',
  ));

  // Register notification handlers (all receive full RemoteMessage)
  Clix.Notification.onMessage((message) async {
    // Called when message received in foreground
    print('Foreground message: ${message.messageId}');
    return true; // Return true to display, false to suppress
  });

  Clix.Notification.onBackgroundMessage((message) async {
    // Called when message received in background
    print('Background message: ${message.messageId}');
  });

  Clix.Notification.onNotificationOpened((message) {
    // Called when user taps notification (app was in background)
    print('Notification tapped: ${message.messageId}');
    final clixData = message.data['clix'];
    // Handle custom routing based on notification data
  });

  Clix.Notification.onFcmTokenError((error) {
    print('FCM token error: $error');
  });

  runApp(MyApp());
}
```

**Important:** All `Clix.Notification` methods must be called **after** `Clix.initialize()`.

##### About Handler Parameters

All handlers receive the full `RemoteMessage` object for Firebase compatibility:

| Handler | Signature | Description |
|---------|-----------|-------------|
| `onMessage` | `Future<bool> Function(RemoteMessage)` | Foreground messages. Return `true` to display, `false` to suppress |
| `onBackgroundMessage` | `Future<void> Function(RemoteMessage)` | Background messages. Matches Firebase's `BackgroundMessageHandler` |
| `onNotificationOpened` | `void Function(RemoteMessage)` | **All notification taps** (FCM + local). Matches Firebase's `onNotificationOpened` |

Access Clix metadata via `message.data['clix']`.

#### 3. Migration from Existing Firebase Messaging Setup

If your app already uses `firebase_messaging` with custom handlers, you can migrate to Clix SDK while preserving your existing logic.

**Why migrate?** The Clix SDK internally registers Firebase Messaging handlers. If you register your own handlers separately, they may conflict or be overwritten. By passing your handlers to Clix, both SDK tracking and your custom logic work together.

##### Background Message Handler Migration

The `onBackgroundMessage` handler signature matches Firebase's `BackgroundMessageHandler` exactly, making migration straightforward:

**Before (Firebase direct):**
```dart
@pragma('vm:entry-point')
Future<void> myBackgroundHandler(RemoteMessage message) async {
  print('Background message: ${message.messageId}');
  await saveToLocalDB(message.data);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Direct Firebase registration
  FirebaseMessaging.onBackgroundMessage(myBackgroundHandler);

  runApp(MyApp());
}
```

**After (via Clix SDK):**
```dart
@pragma('vm:entry-point')
Future<void> myBackgroundHandler(RemoteMessage message) async {
  // Same handler code - no changes needed
  print('Background message: ${message.messageId}');
  await saveToLocalDB(message.data);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Pass handler to Clix instead of Firebase directly
  Clix.Notification.onBackgroundMessage(myBackgroundHandler);

  await Clix.initialize(const ClixConfig(
    projectId: 'YOUR_PROJECT_ID',
    apiKey: 'YOUR_API_KEY',
  ));

  runApp(MyApp());
}
```

##### Execution Order

When a background message arrives, the execution order is:

```
1. Firebase receives RemoteMessage
       ↓
2. Clix SDK internal handler runs (logging, setup)
       ↓
3. Your handler executes (await myBackgroundHandler(message))
       ↓
4. Clix SDK completes processing (event tracking, notification display)
```

This ensures your custom logic runs with full `RemoteMessage` access while Clix handles analytics and notification display automatically.

##### Foreground Message Handler Migration

The `onMessage` handler also receives full `RemoteMessage`:

**Before (Firebase direct):**
```dart
FirebaseMessaging.onMessage.listen((message) {
  print('Foreground message: ${message.messageId}');
  showLocalNotification(message);
});
```

**After (via Clix SDK):**
```dart
Clix.Notification.onMessage((message) async {
  print('Foreground message: ${message.messageId}');
  // Return true to let Clix display notification, false to suppress
  return true;
});
```

##### Message Opened Handler Migration

**Before (Firebase direct):**
```dart
FirebaseMessaging.onNotificationOpened.listen((message) {
  handleNotificationTap(message);
});
```

**After (via Clix SDK):**
```dart
Clix.Notification.onNotificationOpened((message) {
  handleNotificationTap(message);
});
```

#### 4. Token Management

```dart
// Get current FCM token
final token = await Clix.Notification.getToken();

// Delete FCM token
await Clix.Notification.deleteToken();
```

#### 5. Advanced Configuration

##### Permission Request Control

By default, the SDK does not automatically request notification permissions.
You can request permission at the right moment in your app's UX:

```dart
await Clix.initialize(const ClixConfig(
  projectId: 'YOUR_PROJECT_ID',
  apiKey: 'YOUR_API_KEY',
));

// Option 1: Request immediately via configure()
await Clix.Notification.configure(autoRequestPermission: true);

// Option 2: Request at a specific point (e.g., after onboarding)
final status = await Clix.Notification.requestPermission();
if (status == AuthorizationStatus.authorized) {
  print('Notifications enabled!');
}

// Check current permission status
final currentStatus = await Clix.Notification.getPermissionStatus();
```

##### Update Permission Status

If you've disabled automatic permission requests (default is `false`), you must manually notify Clix when users grant or deny push permissions.

After requesting push permissions in your app, call `Clix.Notification.setPermissionGranted()`:

```dart
final settings = await FirebaseMessaging.instance.requestPermission(
  alert: true,
  badge: true,
  sound: true,
);

final isGranted = settings.authorizationStatus == AuthorizationStatus.authorized ||
    settings.authorizationStatus == AuthorizationStatus.provisional;

// Notify Clix SDK about permission status
await Clix.Notification.setPermissionGranted(isGranted);

if (isGranted) {
  print('Push notifications enabled!');
}
```

This ensures Clix can accurately track permission status for your users and target campaigns appropriately.

##### Migrating from Existing flutter_local_notifications Setup

If your app already uses `flutter_local_notifications` with a custom callback, migrate to `onNotificationOpened`:

**Before (flutter_local_notifications direct):**
```dart
await flutterLocalNotificationsPlugin.initialize(
  initSettings,
  onDidReceiveNotificationResponse: (response) {
    if (response.payload != null) {
      final data = jsonDecode(response.payload!);
      handleMyNotificationTap(data);
    }
  },
);
```

**After (via Clix SDK):**
```dart
// Remove your flutter_local_notifications initialization code
// The SDK handles it internally

// Use onNotificationOpened for ALL notification taps (FCM + local)
Clix.Notification.onNotificationOpened((message) {
  handleMyNotificationTap(message.data);  // Your existing logic
});
```

**Why migrate?** The `flutter_local_notifications` plugin can only have one `onDidReceiveNotificationResponse` callback. The SDK handles initialization internally and calls your `onNotificationOpened` handler for all notification taps (both FCM and local notifications).

## Error Handling

All SDK operations can throw `ClixError`. Always handle potential errors:

```dart
try {
  await Clix.setUserId('user123');
} catch (error) {
  print('Failed to set user ID: $error');
}
```

## Thread Safety

The SDK is thread-safe and all operations can be called from any isolate. Async operations will automatically wait for SDK initialization to complete.

## Troubleshooting

### Push Notifications Not Working

If push notifications aren't working, verify:

1. ✅ Firebase is initialized before Clix SDK
2. ✅ `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) are added
3. ✅ Push Notifications capability is enabled (iOS)
4. ✅ Testing on a real device (push notifications don't work on iOS simulator)
5. ✅ Debug logs show FCM token registration messages
6. ✅ `Clix.Notification.setPermissionGranted()` is called after requesting permissions (when not using auto-request)

### FCM Token Errors

If you're experiencing FCM token registration failures, use the error handler:

```dart
Clix.Notification.onFcmTokenError((error) {
  print('FCM token error: $error');
  // Common causes:
  // - Missing or invalid google-services.json/GoogleService-Info.plist
  // - Network connectivity issues
  // - Firebase service errors
});
```

### iOS Debug Mode Crash on Physical Devices

If you experience crashes with the error `Unable to flip between RX and RW memory protection on pages` when running in debug mode on iOS physical devices:

**Cause:** iOS 26 introduced stricter memory protection policies that affect Flutter's JIT (Just-In-Time) compilation in debug mode.

**Solution:** Upgrade Flutter to version 3.33.0 or later:
```bash
flutter upgrade
flutter clean
cd ios && rm -rf Pods Podfile.lock && pod install --repo-update
```

**Workaround (if upgrade is not possible):**
- Use Profile or Release mode for physical device testing: `flutter run --profile`
- Use iOS Simulator for debug mode testing

For more details, see [Flutter Issue #163984](https://github.com/flutter/flutter/issues/163984).

### Getting Help

If you continue to experience issues:

1. Enable debug logging (`ClixLogLevel.debug`)
2. Check console for Clix log messages
3. Verify your device appears in the Clix console Users page
4. Check if `push_token` field is populated for your device
5. Create an issue on [GitHub](https://github.com/clix-so/clix-flutter-sdk/issues) with logs and configuration details

## Sample App

A comprehensive sample app is provided in the `samples/basic_app` directory. The sample demonstrates:

- Basic Clix SDK integration
- Push notification handling with Firebase
- User property management
- Event tracking
- Device information display

To run the sample:

1. Navigate to `samples/basic_app`
2. Follow the Firebase setup instructions in `FIREBASE_SETUP.md`
3. Update `lib/clix_configuration.dart` with your project details
4. Run the app: `flutter run`

## License

This project is licensed under the MIT License with Custom Restrictions. See the [LICENSE](LICENSE) file for details.

## Changelog

See the full release history and changes in the [CHANGELOG.md](CHANGELOG.md) file.

## Contributing

We welcome contributions! Please read the [CONTRIBUTING.md](CONTRIBUTING.md) guide before submitting issues or pull requests.
