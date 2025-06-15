# Clix Flutter SDK

Flutter SDK for Clix service - a powerful customer engagement platform.

## Features

- Device and user management
- Event tracking
- Push notification handling via Firebase Cloud Messaging
- User property management
- Automatic device information collection
- Thread-safe initialization

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  clix: ^0.0.1
```

## Setup

### iOS Setup

1. Add Firebase configuration file (`GoogleService-Info.plist`) to your iOS project
2. Configure push notifications in your iOS project capabilities
3. Add the following to your `Info.plist`:

```xml
<key>FirebaseMessagingAutoInitEnabled</key>
<true/>
```

### Android Setup

1. Add Firebase configuration file (`google-services.json`) to your Android project
2. Add the following to your `android/build.gradle`:

```gradle
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.3.15'
    }
}
```

3. Add to your `android/app/build.gradle`:

```gradle
apply plugin: 'com.google.gms.google-services'
```

## Usage

### Initialize the SDK

```dart
import 'package:clix/clix.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Clix SDK (async version - recommended)
  await Clix.initialize(const ClixConfig(
    projectId: 'YOUR_PROJECT_ID',
    apiKey: 'YOUR_API_KEY',
    logLevel: ClixLogLevel.debug,
  ));
  
  runApp(MyApp());
}
```

### User Management

```dart
// Set user ID (async - recommended)
await Clix.setUserId('user123');

// Set user ID (sync - fire and forget)
Clix.setUserIdSync('user123');

// Remove user ID
await Clix.removeUserId();
```

### User Properties

```dart
// Set single property (async - recommended)
await Clix.setUserProperty('subscription_plan', 'premium');

// Set single property (sync - fire and forget)
Clix.setUserPropertySync('subscription_plan', 'premium');

// Set multiple properties
await Clix.setUserProperties({
  'subscription_plan': 'premium',
  'total_purchases': 5,
  'is_verified': true,
});

// Remove single property
await Clix.removeUserProperty('temporary_flag');

// Remove multiple properties
await Clix.removeUserProperties(['temp1', 'temp2']);
```

### Event Tracking

```dart
// Track event (async - recommended)
await Clix.trackEvent('button_clicked', properties: {
  'button_name': 'subscribe',
  'screen': 'home',
});

// Track event (sync - fire and forget)
Clix.trackEventSync('button_clicked', properties: {
  'button_name': 'subscribe',
  'screen': 'home',
});
```

### Device Information

```dart
// Get device ID (async - recommended)
final deviceId = await Clix.getDeviceId();

// Get device ID (sync with timeout protection)
final deviceId = Clix.getDeviceIdSync();

// Get push token
final pushToken = await Clix.getPushToken();
```

### Push Notifications

```dart
// Set notification handlers
Clix.setNotificationReceivedHandler((payload) {
  print('Notification received: ${payload.messageId}');
});

Clix.setNotificationTappedHandler((payload) {
  print('Notification tapped: ${payload.messageId}');
  if (payload.landingUrl != null) {
    // Handle deep link
  }
});

// Use streams (more Dart-idiomatic)
Clix.onNotificationReceived?.listen((payload) {
  print('Notification received: ${payload.messageId}');
});

Clix.onNotificationTapped?.listen((payload) {
  print('Notification tapped: ${payload.messageId}');
});
```

### Logging

```dart
// Set log level
Clix.setLogLevel(ClixLogLevel.debug);
```

## Configuration Options

### ClixConfig

- `projectId` (required): Your Clix project ID
- `apiKey` (required): Your Clix API key
- `endpoint`: API endpoint (default: 'https://api.clix.so')
- `logLevel`: Logging level (default: ClixLogLevel.error)
- `extraHeaders`: Additional HTTP headers

### ClixLogLevel

- `verbose`: All logs
- `debug`: Debug and above
- `info`: Info and above
- `warning`: Warning and above
- `error`: Error only
- `none`: No logs

## Development

### Build System

This project includes a comprehensive build system similar to the iOS SDK:

#### Using Makefile (Recommended)
```bash
# Show all available commands
make help

# Build the package
make build

# Run tests
make test

# Format and lint code
make format
make lint
make lint-fix

# Complete development workflow
make all

# Clean build artifacts
make clean
```

#### Using Shell Scripts
```bash
# Make script executable
chmod +x scripts/build.sh

# Run commands
./scripts/build.sh help
./scripts/build.sh build
./scripts/build.sh test
./scripts/build.sh all
```

#### Using npm-style Scripts
```bash
cd scripts/
npm run build
npm run test
npm run lint:fix
npm run all
```

### Available Commands

- **build** - Build the Flutter package
- **clean** - Clean build artifacts and caches  
- **format** - Format Dart code using `dart format`
- **lint** - Run code analysis using `dart analyze`
- **lint-fix** - Automatically fix linting issues
- **test** - Run tests with coverage reporting
- **analyze** - Run comprehensive code analysis
- **get** - Fetch package dependencies
- **upgrade** - Update package dependencies  
- **doctor** - Check Flutter/Dart installation
- **check-dependencies** - Check for dependency issues
- **all** - Complete development workflow (format + lint-fix + test + build)

### Continuous Integration

The project includes GitHub Actions workflows that use the Makefile for:
- Multi-platform testing (Ubuntu, macOS)
- Multiple Flutter versions
- Code analysis and formatting checks
- Coverage reporting
- Build artifact generation

## Example

See the [samples/basic_app](samples/basic_app) directory for a complete sample app.

## License

MIT License
