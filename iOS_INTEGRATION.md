# iOS Integration Guide

This guide explains how to integrate the Clix Flutter SDK with iOS push notifications, including rich notifications and deep linking.

## Prerequisites

- iOS 10.0+
- Firebase project configured
- `GoogleService-Info.plist` added to your iOS project
- Push notification capabilities enabled in Xcode

## Basic Setup

### 1. Configure Firebase

Ensure Firebase is configured in your `AppDelegate.swift`:

```swift
import Firebase

// In application:didFinishLaunchingWithOptions
FirebaseApp.configure()
```

### 2. Update AppDelegate

**Option A: Inherit from ClixAppDelegate (Recommended)**

```swift
import Flutter
import UIKit
import Firebase
import clix_flutter

@main
@objc class AppDelegate: ClixAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Configure Firebase before calling super
    FirebaseApp.configure()
    
    // Register generated plugins
    GeneratedPluginRegistrant.register(with: self)
    
    // ClixAppDelegate handles all notification setup
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

**Option B: Manual Integration**

```swift
import Flutter
import UIKit
import Firebase
import UserNotifications
import clix_flutter

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()
    
    // Setup Clix notifications
    ClixAppDelegate.setupNotifications(application: application, launchOptions: launchOptions)
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // You'll need to implement notification delegate methods manually
  // See ClixAppDelegate.swift for reference implementations
}
```

## Rich Notifications (Recommended)

To support rich notifications with images and enhanced content:

### 1. Create Notification Service Extension

1. In Xcode, go to **File → New → Target**
2. Select **Notification Service Extension**
3. Name it (e.g., "ClixNotificationExtension")
4. Replace the generated `NotificationService.swift` with:

```swift
import UserNotifications
import clix_flutter

class NotificationService: ClixNotificationServiceExtension {
    override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) {
        // ClixNotificationServiceExtension handles all rich notification processing
        super.didReceive(request, withContentHandler: contentHandler)
    }
}
```

### 2. Configure Extension Target

1. Add `clix_flutter` as a dependency to your extension target
2. Ensure the extension's deployment target is iOS 10.0+
3. Add Firebase dependencies if needed for analytics

### 3. Update Info.plist

The extension's `Info.plist` should include:

```xml
<key>NSExtension</key>
<dict>
    <key>NSExtensionPointIdentifier</key>
    <string>com.apple.usernotifications.service</string>
    <key>NSExtensionPrincipalClass</key>
    <string>$(PRODUCT_MODULE_NAME).NotificationService</string>
</dict>
```

## Capabilities and Permissions

### 1. Enable Push Notifications

In Xcode project settings:
1. Go to **Signing & Capabilities**
2. Add **Push Notifications** capability
3. Add **Background Modes** capability
4. Enable **Remote notifications** in Background Modes

### 2. Request Permissions

The SDK automatically requests permissions, but you can also manually request them:

```dart
// In your Flutter app
bool granted = await Clix.requestNotificationPermissions();
if (granted) {
  print('Notification permissions granted');
} else {
  print('Notification permissions denied');
}
```

## Features Supported

### ✅ Implemented Features

- **Foreground Notifications**: Display notifications when app is active
- **Background Notifications**: Handle notifications when app is backgrounded
- **Notification Taps**: Handle user taps with deep linking
- **Rich Media**: Images and enhanced content in notifications
- **Badge Management**: Set and clear app icon badge numbers
- **Landing URLs**: Automatic opening of URLs from notification taps
- **Permission Management**: Request and check notification permissions
- **Firebase Integration**: Full FCM token management

### 🔄 Event Handling

The iOS implementation automatically forwards these events to Flutter:

- `onNotificationReceived`: When notification arrives in foreground
- `onNotificationTapped`: When user taps a notification
- `onTokenRefresh`: When FCM token changes

### 📱 Deep Linking

Notifications with `landing_url` in the Clix payload will automatically:
1. Open the URL when notification is tapped
2. Handle app state transitions properly
3. Queue URLs if app is not ready

## Troubleshooting

### Common Issues

1. **Notifications not showing**: Check Firebase configuration and APNS certificates
2. **Rich images not loading**: Ensure Notification Service Extension is properly configured
3. **Deep links not working**: Verify URL schemes are registered in Info.plist
4. **Extension crashes**: Check that clix_flutter is added as dependency to extension target

### Debug Logging

Enable debug logging to see detailed notification handling:

```swift
// In AppDelegate
override func application(...) -> Bool {
    // Enable debug logging before other setup
    NSLog("Debug logging enabled")
    // ... rest of setup
}
```

### Firebase Console

Verify in Firebase Console:
1. iOS app is properly configured
2. APNS certificates are uploaded
3. FCM tokens are being generated

## Migration from Native Implementation

If you're migrating from a native iOS implementation:

1. Remove custom `UNUserNotificationCenterDelegate` implementations
2. Remove manual Firebase Messaging setup
3. Replace with `ClixAppDelegate` inheritance
4. Update Notification Service Extension to use `ClixNotificationServiceExtension`

The new implementation provides the same functionality with significantly less code.

## Sample Code

See `/samples/basic_app/ios/` for a complete working example including:
- `AppDelegate.swift` - Main app delegate setup
- `ClixNotificationExtension/` - Notification service extension
- Project configuration examples

This implementation provides feature parity with Android while using modern iOS APIs and maintaining compatibility with Flutter's Firebase plugins.