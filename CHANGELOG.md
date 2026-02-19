# Changelog

All notable changes to this project will be documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-02-19

### Added

- `reset()` method to clear all local SDK state including device ID

### Deprecated

- `removeUserId()` — use `reset()` instead

## [0.0.5] - 2026-02-13

### Added

- Added `sourceType` field to event tracking for SDK-internal events (SESSION_START, PUSH_NOTIFICATION_RECEIVED, PUSH_NOTIFICATION_TAPPED)

## [0.0.4] - 2026-02-12

### Added

- Session tracking with automatic SESSION_START lifecycle events

## [0.0.3] - 2025-12-01

### Added

- **Push Notifications**
  - `Clix.Notification` API with callback handlers
  - `onMessage()`, `onBackgroundMessage()`, `onNotificationOpened()`, `onFcmTokenError()` handlers
  - Token management: `getToken()`, `deleteToken()`
  - Permission management: `requestPermission()`, `getPermissionStatus()`, `setPermissionGranted()`
  - `configure()` with `autoRequestPermission`, `autoHandleLandingURL` options

### Changed

- **Storage**
  - Migrated from SharedPreferences to MMKV for improved performance
  - Automatic iOS app group configuration (`group.clix.{bundleId}`)

- **Platform Requirements**
  - Flutter minimum version: 3.33.0
  - Android minimum SDK: API 23 (Android 6.0)

## [0.0.2] - 2025-09-18

### Changed
- Update the default `User-Agent` header sent by `ClixAPIClient` to match the conventions used by our other SDKs.

## [0.0.1] - 2025-06-01

### Added

- **Core SDK**
  - ClixConfig-based initialization with projectId, apiKey, endpoint configuration
  - Async/await and synchronous API support
  - Thread-safe operations with automatic initialization handling

- **User Management**
  - User identification: `setUserId()`, `removeUserId()`
  - User properties: `setUserProperty()`, `setUserProperties()`, `removeUserProperty()`

- **Push Notifications**
  - Firebase Cloud Messaging integration
  - ClixAppDelegate for automated push notification handling
  - ClixNotificationServiceExtension for rich notifications with images
  - Automatic device token management

- **Device & Logging**
  - Device information access: `getDeviceId()`, `getPushToken()`
  - Configurable logging system with 5 levels (none to debug)

- **Installation**
  - Swift Package Manager and CocoaPods support
  - iOS 14.0+ and Swift 5.5+ compatibility
  - Sample app with complete integration example
