# AGENTS.md

This file provides guidance to Coding Agents when working with code in this repository.

## Overview

Clix Flutter SDK is a Flutter plugin for managing push notifications and user engagement. It provides cross-platform support (iOS/Android) with Firebase integration for push notifications, user property tracking, and event analytics.

**Key Architecture**: Plugin-based architecture with platform-specific native implementations (iOS Swift, Android Kotlin) bridged via Pigeon, Firebase Messaging integration, and automatic code generation for models.

## Development Commands

### Package Management
```bash
make get              # Install dependencies
flutter pub get       # Alternative dependency install
make upgrade          # Upgrade dependencies
```

### Code Generation
```bash
make generate         # Generate code (JSON serialization, Pigeon bindings)
dart run build_runner build --delete-conflicting-outputs
```

**Important**: Run code generation after modifying:
- Model classes with `@JsonSerializable()` annotations
- Pigeon definitions in `pigeons/` directory
- Any changes to native-Dart bridge interfaces

### Building
```bash
make build           # Full build: get deps, generate code, analyze
make clean           # Clean all build artifacts and caches
```

### Testing
```bash
make test            # Run all tests with coverage
flutter test         # Run tests without coverage
flutter test test/path/to/specific_test.dart  # Run single test file
```

### Code Quality
```bash
make lint            # Run static analysis with strict settings
make lint-fix        # Auto-fix lint issues and format code
make format          # Format code only
dart analyze --fatal-infos --fatal-warnings  # Strict analysis
```

### Sample App
```bash
# iOS
make run-ios         # Run sample app on iOS simulator
make build-ios       # Build iOS version (no codesign)

# Android
make run-android     # Run sample app on Android emulator
make build-android   # Build APK

# Manual navigation
cd samples/basic_app && flutter run -d <device-id>
```

### Complete Workflow
```bash
make all            # format → lint-fix → test → build
```

## Architecture

### Project Structure

```
lib/
├── clix_flutter.dart           # Main export file (public API)
├── src/
    ├── core/                   # SDK initialization and configuration
    │   ├── clix.dart          # Main SDK singleton
    │   ├── clix_config.dart   # Configuration model
    │   └── clix_version.dart  # Version tracking
    ├── models/                 # Data models (JSON serializable)
    │   ├── clix_device.dart
    │   ├── clix_push_notification_payload.dart
    │   └── clix_user_property.dart
    ├── services/              # Business logic layer
    │   ├── token_service.dart        # FCM token management
    │   ├── notification_service.dart # Notification handling
    │   ├── event_service.dart        # Event tracking
    │   ├── device_service.dart       # Device info
    │   └── api_client/               # HTTP client
    ├── platform/              # Native bridge (Pigeon generated)
    └── utils/                 # Utilities, logging, errors
```

### Key Components

**Clix Singleton (`lib/src/core/clix.dart`)**
- Main SDK entry point
- Thread-safe initialization
- Manages lifecycle and dependency injection

**Services Layer**
- `TokenService`: FCM token lifecycle, registration with backend
- `NotificationService`: Push notification reception, foreground/background handling
- `EventService`: Analytics event tracking
- `DeviceService`: Device information collection and registration
- API Client: HTTP communication with Clix backend

**Platform Bridge**
- Uses Pigeon for type-safe Flutter ↔ Native communication
- Definitions in `pigeons/` generate code for both sides
- Native implementations: `ios/Classes/` (Swift), `android/src/` (Kotlin)

**Code Generation**
- JSON serialization via `json_serializable` (models use `@JsonSerializable()`)
- Field naming: snake_case in JSON, camelCase in Dart (configured in `build.yaml`)
- Generated files: `*.g.dart` (committed to repo for distribution)

### iOS Integration

The SDK provides two iOS integration patterns:

1. **ClixAppDelegate** (Recommended): Inherit from this base class for automatic notification handling
2. **Manual Setup**: Call `ClixAppDelegate.setupNotifications()` and implement delegate methods

**Rich Notifications**: Create Notification Service Extension inheriting from `ClixNotificationServiceExtension` for image support and enhanced content.

See `iOS_INTEGRATION.md` for complete iOS setup guide.

### Firebase Integration

**Required**: Firebase Core and Firebase Messaging must be initialized by the host app before Clix SDK initialization.

```dart
await Firebase.initializeApp();
await Clix.initialize(const ClixConfig(...));
```

The SDK relies on Firebase Messaging for cross-platform push notification delivery.

## Development Guidelines

### Code Generation Workflow

When modifying models or platform interfaces:

1. Make changes to source files
2. Run `make generate` or `dart run build_runner build --delete-conflicting-outputs`
3. Commit generated `*.g.dart` files (required for pub.dev distribution)

### API Changes

Public API is exported via `lib/clix_flutter.dart`. Only add exports for classes/functions intended for external use.

### Native Code Changes

**iOS** (`ios/Classes/`):
- Written in Swift
- Implements platform methods defined in Pigeon
- Handle notification delegates, Firebase integration

**Android** (`android/src/`):
- Written in Kotlin
- Plugin class: `ClixPlugin`
- Handle Firebase Messaging, notification channels

After changing Pigeon definitions (`pigeons/`):
```bash
flutter pub run pigeon --input pigeons/messages.dart
```

### Testing Sample App

The `samples/basic_app` demonstrates full SDK integration:
- Update `lib/clix_info.dart` with test credentials
- Configure Firebase (`google-services.json`, `GoogleService-Info.plist`)
- See `samples/basic_app/FIREBASE_SETUP.md` for details

### Version Updates

1. Update `version` in `pubspec.yaml`
2. Update `CHANGELOG.md`
3. Update version constant in `lib/src/core/clix_version.dart`

## Common Patterns

### Async Initialization
All SDK methods wait for initialization automatically. No need for manual ready checks.

### Error Handling
SDK operations throw `ClixError`. Always wrap in try-catch:
```dart
try {
  await Clix.setUserId('user123');
} catch (error) {
  // Handle ClixError
}
```

### Thread Safety
SDK is thread-safe and can be called from any isolate.

### Logging
Use `ClixLogLevel` enum for configurable logging. Debug builds should use `.debug` or `.verbose`.

## Publishing

Before publishing to pub.dev:
1. Run `make all` to ensure code quality
2. Verify `pubspec.yaml` version is updated
3. Ensure all generated code is committed
4. Update `CHANGELOG.md`
5. Test with sample app on both platforms

## Requirements

- Flutter: >=3.0.0
- Dart: >=2.17.0 <4.0.0
- iOS: 14.0+
- Android: API 23+ (Android 6.0)
