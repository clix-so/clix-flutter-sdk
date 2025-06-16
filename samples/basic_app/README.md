# Clix Flutter SDK Sample

This sample app demonstrates how to use the Clix Flutter SDK in your application.

## Getting Started

⚠️ **Important**: This sample requires Firebase setup to run properly.

1. **Set up Firebase** (Required):
   - See [FIREBASE_SETUP.md](FIREBASE_SETUP.md) for detailed instructions
   - Replace the template Firebase configuration files with your actual project files

2. **Configure Clix credentials** by updating `lib/main.dart`:

```dart
await Clix.initialize(const ClixConfig(
  projectId: 'YOUR_PROJECT_ID',
  apiKey: 'YOUR_API_KEY',
  logLevel: ClixLogLevel.debug,
));
```

## Features Demonstrated

This example app shows how to:

- Initialize the Clix SDK
- Set user ID for tracking
- Set user properties for segmentation
- Handle push notifications (received and tapped)
- Track custom events
- Handle deep links from notifications

## Running the Sample

### Android
```bash
flutter run
```

### iOS
```bash
cd ios && pod install
flutter run
```

## Key Integration Points

### Initialization
The SDK must be initialized before the app runs:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Clix.initialize(const ClixConfig(
    projectId: 'YOUR_PROJECT_ID',
    apiKey: 'YOUR_API_KEY',
  ));
  
  runApp(const MyApp());
}
```

### User Identification
```dart
await Clix.setUserId('unique_user_id');
```

### User Properties
```dart
await Clix.setUserProperty('subscription_plan', 'premium');
```

### Event Tracking
```dart
await Clix.trackEvent('purchase_completed', properties: {
  'amount': 99.99,
  'currency': 'USD',
  'item_id': 'SKU123'
});
```

### Push Notification Handling
```dart
// Listen for received notifications
Clix.onNotificationReceived?.listen((payload) {
  print('Notification received: ${payload.messageId}');
});

// Listen for tapped notifications
Clix.onNotificationTapped?.listen((payload) {
  print('Notification tapped: ${payload.messageId}');
  if (payload.landingUrl != null) {
    // Handle deep link
  }
});
```

## Troubleshooting

1. **Push notifications not working on iOS**: 
   - Ensure you've added Push Notification capability in Xcode
   - Add the notification service extension

2. **Android build issues**:
   - Make sure `google-services.json` is in the `android/app` directory
   - Check that Firebase dependencies are properly configured

3. **User not being tracked**:
   - Verify that `setUserId` is called after SDK initialization
   - Check API key and project ID are correct

For more information, visit [https://clix.so/docs](https://clix.so/docs)