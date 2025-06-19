# Clix Flutter SDK

Clix Flutter SDK is a powerful tool for managing push notifications and user events in your Flutter application. It provides a simple and intuitive interface for user engagement and analytics.

## Installation

Add this to your package's `pubspec.yaml` file:
```yaml
dependencies:
  clix_flutter: ^0.0.1
```

Then run:

```bash
flutter pub get
```

## Requirements

- Flutter 3.0.0 or later
- Dart 2.17.0 or later
- iOS 14.0+ / Android API 21+

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
    logLevel: ClixLogLevel.debug, // Optional: set log level
    extraHeaders: {}, // Optional: extra headers for API requests
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
  'subscription_plan': 'pro',
});

// Remove user properties
await Clix.removeUserProperty('name');
await Clix.removeUserProperties(['age', 'premium']);

// Remove user ID
await Clix.removeUserId();
```

### Device Information

```dart
// Get device ID
final deviceId = await Clix.getDeviceId();

// Get push token
final pushToken = await Clix.getPushToken();
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

#### Setup Firebase

1. **Add Firebase to your Flutter project**
   - Follow the [Firebase setup guide](https://firebase.google.com/docs/flutter/setup)
   - Add `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)

2. **Enable Push Notifications**
   - For iOS: Enable Push Notifications capability in Xcode
   - For Android: No additional setup required

3. **Add Firebase dependencies**

```yaml
dependencies:
  firebase_core: ^3.6.0
  firebase_messaging: ^15.1.3
```

#### Handling Notifications

The SDK automatically handles notification registration and token management. Notifications are processed internally for analytics and tracking.

```dart
// Notification handling is automatic - no additional code required
// The SDK will track notification delivery and engagement automatically
```

## Firebase Setup

### iOS Setup

1. Add your `GoogleService-Info.plist` to the iOS project in Xcode
2. Enable Push Notifications capability in your iOS project
3. Add Background Modes capability and check "Remote notifications"

### Android Setup

1. Add your `google-services.json` to `android/app/`
2. Add the Google Services plugin to your `android/build.gradle`:

```gradle
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.3.15'
    }
}
```

3. Apply the plugin in `android/app/build.gradle`:

```gradle
apply plugin: 'com.google.gms.google-services'
```

## Configuration Options

### ClixConfig

- `projectId` (required): Your Clix project ID
- `apiKey` (required): Your Clix API key  
- `endpoint`: API endpoint (default: 'https://api.clix.so')
- `logLevel`: Logging level (default: ClixLogLevel.error)
- `extraHeaders`: Additional HTTP headers for API requests

### ClixLogLevel

- `verbose`: All logs including detailed debugging
- `debug`: Debug information and above
- `info`: General information and above
- `warning`: Warning messages and above
- `error`: Error messages only
- `none`: No logging

## Sample App

A comprehensive sample app is provided in the `samples/basic_app` directory. The sample demonstrates:

- Basic Clix SDK integration
- Push notification handling with Firebase
- User property management
- Device information display

To run the sample:

1. Navigate to `samples/basic_app`
2. Follow the Firebase setup instructions in `FIREBASE_SETUP.md`
3. Update `lib/clix_info.dart` with your project details
4. Run the app: `flutter run`

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

## Advanced Features

### Manual Event Tracking

While the SDK automatically tracks notification events, you can also track custom events:

```dart
// Custom event tracking methods would be implemented here
// Currently handled automatically by the SDK
```

### Custom Properties

User properties support various data types:

```dart
await Clix.setUserProperties({
  'name': 'John Doe',           // String
  'age': 25,                    // Number
  'premium': true,              // Boolean
  'tags': ['flutter', 'mobile'], // Array
  'metadata': {                 // Object
    'source': 'mobile_app',
    'version': '1.0.0',
  },
});
```

## Platform-Specific Considerations

### iOS

- Requires iOS 14.0 or later
- Push notifications require user permission
- Background processing is automatically handled

### Android

- Requires Android API level 21 or later
- Notification channels are automatically managed
- Background processing follows Android guidelines

## Performance

- Lightweight initialization
- Efficient background processing
- Minimal memory footprint
- Optimized network requests

## Privacy

The SDK respects user privacy:
- Only collects necessary device information
- User data is handled according to your privacy policy
- Push tokens are managed securely
- No personal data is collected without consent

## License

This project is licensed under the MIT License with Custom Restrictions. See the [LICENSE](LICENSE) file for details.

## Changelog

See the full release history and changes in the [CHANGELOG.md](CHANGELOG.md) file.

## Contributing

We welcome contributions! Please read the [CONTRIBUTING.md](CONTRIBUTING.md) guide before submitting issues or pull requests.

## Support

For support and questions:
- Check the sample app for implementation examples
- Review the API documentation
- Contact support through your Clix dashboard
