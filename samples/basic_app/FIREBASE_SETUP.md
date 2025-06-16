# Firebase Setup for Clix Flutter SDK Sample

This sample app requires Firebase configuration to run properly. Follow these steps to set up Firebase:

## 1. Create a Firebase Project

1. Go to the [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project" or "Add project"
3. Enter your project name (e.g., "clix-sample")
4. Follow the setup wizard

## 2. Add Android App

1. In your Firebase project, click "Add app" and select Android
2. Enter the package name: `so.clix.samples.basic`
3. Download the `google-services.json` file
4. Replace the existing `android/app/google-services.json` file with your downloaded file

## 3. Add iOS App

1. In your Firebase project, click "Add app" and select iOS
2. Enter the bundle ID: `so.clix.samples.basic` 
3. Download the `GoogleService-Info.plist` file
4. Replace the existing `ios/Runner/GoogleService-Info.plist` file with your downloaded file

## 4. Enable Firebase Cloud Messaging

1. In the Firebase Console, go to "Project Settings"
2. Navigate to the "Cloud Messaging" tab
3. Note down your "Server Key" (if needed for backend integration)

## 5. Configure Clix SDK

Update the `main.dart` file with your Clix project configuration:

```dart
await Clix.initialize(const ClixConfig(
  projectId: 'YOUR_CLIX_PROJECT_ID',
  apiKey: 'YOUR_CLIX_API_KEY',
  logLevel: ClixLogLevel.debug,
));
```

## 6. Test the App

After completing the setup:

1. Run the app: `flutter run`
2. The app should start without Firebase initialization errors
3. You can test push notifications using the Firebase Console's "Cloud Messaging" section

## Notes

- The current configuration files contain dummy data and will cause Firebase initialization errors
- Make sure your Firebase project has the exact package/bundle IDs as specified above
- For production apps, use your actual Clix project credentials

## Troubleshooting

If you see "Firebase has not been correctly initialized" error:
1. Verify that you've replaced both configuration files with your actual Firebase project files
2. Check that the package names match exactly
3. Clean and rebuild the project: `flutter clean && flutter pub get`