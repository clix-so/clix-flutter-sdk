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

- Flutter 3.0.0 or later
- Dart 2.17.0 or later
- iOS 14.0+ / Android API 21+
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
    endpoint: 'https://api.clix.so', // Optional: default is https://api.clix.so
    logLevel: ClixLogLevel.debug,     // Optional: set log level
  ));

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

  // Register notification handlers
  Clix.Notification.onMessage((notificationData) async {
    // Return true to display the notification, false to suppress it
    return true;
  });

  Clix.Notification.onBackgroundMessage((notificationData) {
    // Handle background notification
    print('Background notification received: $notificationData');
  });

  Clix.Notification.onNotificationOpened((notificationData) {
    // Custom routing (called when user taps notification)
    final clixData = notificationData['clix'] as Map<String, dynamic>?;
    final landingURL = clixData?['landing_url'] as String?;
    if (landingURL != null) {
      // Handle custom routing
    }
  });

  Clix.Notification.onFcmTokenError((error) {
    print('FCM token error: $error');
  });

  runApp(MyApp());
}
```

**Important:** All `Clix.Notification` methods must be called **after** `Clix.initialize()`.

##### About `notificationData`

- The `notificationData` map is the full FCM payload as delivered to the device
- Every Clix notification callback (`onMessage`, `onBackgroundMessage`, `onNotificationOpened`) passes this map through untouched
- `notificationData['clix']` holds the Clix metadata JSON, while all other keys represent app-specific data

#### 3. Token Management

```dart
// Get current FCM token
final token = await Clix.Notification.getToken();

// Delete FCM token
await Clix.Notification.deleteToken();
```

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
