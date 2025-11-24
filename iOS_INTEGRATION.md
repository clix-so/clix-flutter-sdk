# iOS Integration Guide

This guide explains how to integrate the Clix Flutter SDK with iOS push notifications, including rich notifications and notification handlers.

## Prerequisites

- iOS 14.0+
- Firebase project configured
- `GoogleService-Info.plist` added to your iOS project
- Push notification capabilities enabled in Xcode

## Basic Setup

### 1. Enable Capabilities in Xcode

1. Open your iOS project in Xcode
2. Select your app target
3. Go to **Signing & Capabilities**
4. Add **Push Notifications** capability
5. Add **Background Modes** capability and enable **Remote notifications**

### 2. Configure Firebase

Ensure Firebase is configured in your Flutter app before initializing Clix:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:clix_flutter/clix_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase first
  await Firebase.initializeApp();

  // Initialize Clix SDK
  await Clix.initialize(const ClixConfig(
    projectId: 'YOUR_PROJECT_ID',
    apiKey: 'YOUR_API_KEY',
  ));

  runApp(MyApp());
}
```

## Push Notification Handlers

Register notification handlers to customize notification behavior:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  await Clix.initialize(const ClixConfig(
    projectId: 'YOUR_PROJECT_ID',
    apiKey: 'YOUR_API_KEY',
  ));

  // Foreground message handler
  Clix.Notification.onMessage((notificationData) async {
    // Return true to display the notification, false to suppress it
    return true;
  });

  // Background message handler
  Clix.Notification.onBackgroundMessage((notificationData) {
    print('Background notification: $notificationData');
  });

  // Notification tap handler
  Clix.Notification.onNotificationOpened((notificationData) {
    final clixData = notificationData['clix'] as Map<String, dynamic>?;
    final landingURL = clixData?['landing_url'] as String?;
    if (landingURL != null) {
      // Handle custom routing
    }
  });

  // Token error handler
  Clix.Notification.onFcmTokenError((error) {
    print('FCM token error: $error');
  });

  runApp(MyApp());
}
```

### About `notificationData`

- The `notificationData` map contains the full FCM/APNs payload
- `notificationData['clix']` holds Clix metadata (message_id, landing_url, etc.)
- All other keys represent custom data from your backend

## Rich Notifications with Notification Service Extension

To support images and rich content in notifications:

### 1. Create Notification Service Extension

1. In Xcode, go to **File → New → Target**
2. Select **Notification Service Extension**
3. Name it (e.g., "NotificationServiceExtension")
4. Choose Swift as the language

### 2. Configure App Group (Required for MMKV)

The SDK uses MMKV for storage with automatic app group support:

1. In Xcode, select your **main app target**
2. Go to **Signing & Capabilities**
3. Add **App Groups** capability
4. Add a new app group: `group.clix.YOUR_BUNDLE_ID`

5. Repeat for your **Notification Service Extension target**:
   - Add **App Groups** capability
   - Enable the **same** app group: `group.clix.YOUR_BUNDLE_ID`

**Note:** The SDK automatically uses `group.clix.{bundleId}` format. You must create this app group in both targets.

### 3. Update Extension Code

Replace `NotificationService.swift` in your extension:

```swift
import UserNotifications
import clix_flutter

class NotificationService: ClixNotificationServiceExtension {
  override func didReceive(
    _ request: UNNotificationRequest,
    withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
  ) {
    // Register with your project ID
    register(projectId: "YOUR_PROJECT_ID")

    // ClixNotificationServiceExtension handles image downloading and tracking
    super.didReceive(request, withContentHandler: contentHandler)
  }
}
```

### 4. Add clix_flutter to Extension

In your `ios/Podfile`, ensure the extension target has access to the plugin:

```ruby
target 'NotificationServiceExtension' do
  use_frameworks!
  use_modular_headers!

  # Add clix_flutter pod
  pod 'clix_flutter', :path => '.symlinks/plugins/clix_flutter/ios'
end
```

Then run:
```bash
cd ios && pod install
```

## Token Management

```dart
// Get current FCM token
final token = await Clix.Notification.getToken();

// Delete FCM token
await Clix.Notification.deleteToken();
```

## Troubleshooting

### Notifications Not Showing

If notifications aren't appearing:

1. ✅ Push Notifications capability is enabled in Xcode
2. ✅ Background Modes > Remote notifications is enabled
3. ✅ `GoogleService-Info.plist` is added to the project
4. ✅ Testing on a real device (not simulator)
5. ✅ APNs certificates are configured in Firebase Console

### Rich Notifications Not Working

If images aren't appearing:

1. ✅ Notification Service Extension is created
2. ✅ App Groups capability is added to **both** main app and extension
3. ✅ Same app group ID is enabled in both targets: `group.clix.{bundleId}`
4. ✅ `clix_flutter` pod is added to extension target
5. ✅ Extension calls `register(projectId:)` with correct project ID

### App Group Issues

If the extension can't access shared data:

1. Verify app group format: `group.clix.{YOUR_BUNDLE_ID}`
2. Check that both targets have the capability enabled
3. Ensure you're using the exact same group identifier
4. Check Xcode logs for MMKV initialization messages

### FCM Token Errors

Enable error handler to diagnose token issues:

```dart
Clix.Notification.onFcmTokenError((error) {
  print('FCM token error: $error');
});
```

Common causes:
- Missing or invalid `GoogleService-Info.plist`
- APNs certificates not configured in Firebase Console
- Network connectivity issues

### Getting Help

If you continue to experience issues:

1. Enable debug logging: `logLevel: ClixLogLevel.debug`
2. Check Xcode console for error messages
3. Verify device appears in Clix console with push token
4. Create an issue on [GitHub](https://github.com/clix-so/clix-flutter-sdk/issues)

## Sample Implementation

See `samples/basic_app/ios/Runner/AppDelegate.swift` for a complete working example.

## Migration Notes

### From Previous Versions

If you're upgrading from an earlier version:

1. Update to latest `clix_flutter` version
2. Replace old notification handling code with new `Clix.Notification` API
3. Update Notification Service Extension if using rich notifications
4. Add App Groups capability for MMKV storage (automatic setup)

## Features

- ✅ Foreground notification display
- ✅ Background notification handling
- ✅ Notification tap handling with deep linking
- ✅ Rich notifications with images
- ✅ Automatic token management
- ✅ Event tracking (delivered, opened)
- ✅ App group support for extensions (automatic)
- ✅ Thread-safe operations

This integration provides full feature parity with the native iOS SDK while maintaining Flutter's cross-platform benefits.
