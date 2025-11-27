# Clix Flutter SDK Sample

This sample app demonstrates how to use the Clix Flutter SDK in your application.

## Getting Started

⚠️ **Important**: This sample requires Firebase setup to run properly.

1. **Set up Firebase** (Required):
   - See [FIREBASE_SETUP.md](FIREBASE_SETUP.md) for detailed instructions
   - Replace the template Firebase configuration files with your actual project files

2. **Configure Clix credentials** by creating the configuration file:
   - Copy `assets/clix_config.json.example` to `assets/clix_config.json`
   - Update the file with your actual credentials:

```json
{
  "projectId": "YOUR_PROJECT_ID",
  "apiKey": "YOUR_API_KEY",
  "endpoint": "https://api.clix.so",
  "extraHeaders": {}
}
```

   ⚠️ **Security Note**: Never commit `clix_config.json` with real credentials to version control. This file is gitignored.

   **Note**: Log level is set to `debug` by default in `ClixConfiguration.logLevel`. To change it, modify `lib/clix_configuration.dart`.

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
The SDK must be initialized before the app runs. Configuration is loaded once from `assets/clix_config.json` and cached for reuse:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize configuration (loads once and caches)
  await ClixConfiguration.initialize();

  // Get cached configuration
  final config = ClixConfiguration.config;

  // Initialize SDK with the cached configuration
  await Clix.initialize(config);

  runApp(const MyApp());
}
```

Configuration file format (`assets/clix_config.json`):
```json
{
  "projectId": "your-project-id",
  "apiKey": "your-api-key",
  "endpoint": "https://api.clix.so",
  "extraHeaders": {}
}
```

**Note**:
- `ClixConfiguration.initialize()` loads the JSON file once and caches it
- `ClixConfiguration.config` returns the cached configuration (throws if not initialized)
- Log level is set to `debug` by default in `ClixConfiguration.logLevel`
- Subsequent calls to `ClixConfiguration.config` reuse the cached instance

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