import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:json_annotation/json_annotation.dart';
import '../utils/logger.dart';
import '../utils/clix_error.dart';
import 'storage_service.dart';

part 'permission_service.g.dart';

/// Permission status for notifications
enum NotificationPermissionStatus {
  /// Permission has not been requested yet
  notDetermined,

  /// Permission was denied by the user
  denied,

  /// Permission was granted by the user
  authorized,

  /// Provisional permission (iOS 12+)
  provisional,

  /// Permission was permanently denied (Android)
  permanentlyDenied,
}

/// Notification settings model
@JsonSerializable(fieldRename: FieldRename.snake)
class NotificationSettings {
  final bool enabled;
  final List<String>? categories;
  final DateTime lastUpdated;
  final NotificationPermissionStatus status;

  const NotificationSettings({
    required this.enabled,
    this.categories,
    required this.lastUpdated,
    required this.status,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() => _$NotificationSettingsToJson(this);

  /// Create from JSON
  factory NotificationSettings.fromJson(Map<String, dynamic> json) =>
      _$NotificationSettingsFromJson(json);

  NotificationSettings copyWith({
    bool? enabled,
    List<String>? categories,
    DateTime? lastUpdated,
    NotificationPermissionStatus? status,
  }) {
    return NotificationSettings(
      enabled: enabled ?? this.enabled,
      categories: categories ?? this.categories,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      status: status ?? this.status,
    );
  }
}

/// Service for managing notification permissions
class PermissionService {
  final StorageService _storage;

  static const String _settingsKey = 'clix_notification_settings';

  PermissionService({
    required StorageService storage,
  }) : _storage = storage;

  /// Request notification permissions
  Future<bool> requestNotificationPermission() async {
    if (kIsWeb) {
      ClixLogger.warning('Notification permissions not supported on web');
      return false;
    }

    try {
      ClixLogger.info('Requesting notification permissions');

      final status = await Permission.notification.request();
      final granted = status == PermissionStatus.granted ||
          status == PermissionStatus.provisional;

      final permissionStatus = _mapPermissionStatus(status);

      final settings = NotificationSettings(
        enabled: granted,
        categories: null,
        lastUpdated: DateTime.now(),
        status: permissionStatus,
      );

      await _saveSettings(settings);

      ClixLogger.info('Notification permission request result: $granted');
      return granted;
    } catch (e, stackTrace) {
      ClixLogger.error(
          'Failed to request notification permission', e, stackTrace);
      throw ClixError.now(
        code: 'PERMISSION_REQUEST_ERROR',
        message: 'Failed to request notification permission: $e',
        details: e,
      );
    }
  }

  /// Check current notification permission status
  Future<NotificationPermissionStatus> getNotificationPermissionStatus() async {
    if (kIsWeb) {
      return NotificationPermissionStatus.notDetermined;
    }

    try {
      final status = await Permission.notification.status;
      return _mapPermissionStatus(status);
    } catch (e, stackTrace) {
      ClixLogger.error(
          'Failed to get notification permission status', e, stackTrace);
      return NotificationPermissionStatus.notDetermined;
    }
  }

  /// Check if notification permission is granted
  Future<bool> isNotificationPermissionGranted() async {
    final status = await getNotificationPermissionStatus();
    return status == NotificationPermissionStatus.authorized ||
        status == NotificationPermissionStatus.provisional;
  }

  /// Set notification preferences
  Future<void> setNotificationPreferences({
    required bool enabled,
    List<String>? categories,
  }) async {
    try {
      NotificationPermissionStatus currentStatus;

      if (enabled) {
        // Request permission if enabling notifications
        final granted = await requestNotificationPermission();
        currentStatus = granted
            ? NotificationPermissionStatus.authorized
            : NotificationPermissionStatus.denied;
      } else {
        // Just get current status if disabling
        currentStatus = await getNotificationPermissionStatus();
      }

      final settings = NotificationSettings(
        enabled: enabled,
        categories: categories,
        lastUpdated: DateTime.now(),
        status: currentStatus,
      );

      await _saveSettings(settings);
      ClixLogger.info('Notification preferences updated: enabled=$enabled');
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to set notification preferences', e, stackTrace);
      throw ClixError.now(
        code: 'SET_PREFERENCES_ERROR',
        message: 'Failed to set notification preferences: $e',
        details: e,
      );
    }
  }

  /// Get current notification settings
  Future<NotificationSettings?> getNotificationSettings() async {
    try {
      final settingsJson = _storage.getJson(_settingsKey);
      if (settingsJson == null) return null;

      return NotificationSettings.fromJson(settingsJson);
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to get notification settings', e, stackTrace);
      return null;
    }
  }

  /// Check if notification permissions are available on the current platform
  bool get supportsNotificationPermissions {
    return !kIsWeb && (Platform.isIOS || Platform.isAndroid);
  }

  /// Open app settings for notification permissions (if denied)
  Future<bool> openNotificationSettings() async {
    if (!supportsNotificationPermissions) return false;

    try {
      ClixLogger.info('Opening notification settings');
      return await openAppSettings();
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to open notification settings', e, stackTrace);
      return false;
    }
  }

  /// Check if permission was permanently denied
  Future<bool> isPermissionPermanentlyDenied() async {
    if (!supportsNotificationPermissions) return false;

    final status = await getNotificationPermissionStatus();
    return status == NotificationPermissionStatus.permanentlyDenied;
  }

  /// Get detailed permission information for debugging
  Future<Map<String, dynamic>> getPermissionInfo() async {
    final status = await getNotificationPermissionStatus();
    final settings = await getNotificationSettings();

    return {
      'currentStatus': status.name,
      'isGranted': await isNotificationPermissionGranted(),
      'isPermanentlyDenied': await isPermissionPermanentlyDenied(),
      'supportsPermissions': supportsNotificationPermissions,
      'settings': settings?.toJson(),
      'platform': kIsWeb ? 'web' : Platform.operatingSystem,
    };
  }

  /// Initialize permission service - check and update current status
  /// On Android API 31+, automatically request permission if not determined
  Future<void> initialize() async {
    if (!supportsNotificationPermissions) return;

    try {
      final currentStatus = await getNotificationPermissionStatus();
      ClixLogger.info('Initial permission status: ${currentStatus.name}');

      // For Android API 31+, automatically request permission if not determined
      bool isGranted =
          currentStatus == NotificationPermissionStatus.authorized ||
              currentStatus == NotificationPermissionStatus.provisional;

      if (Platform.isAndroid &&
          currentStatus == NotificationPermissionStatus.notDetermined) {
        ClixLogger.info(
            'Android detected - requesting notification permission automatically');
        isGranted = await requestNotificationPermission();
        // Re-check status after request
        final newStatus = await getNotificationPermissionStatus();
        ClixLogger.info('Permission status after request: ${newStatus.name}');
        isGranted = newStatus == NotificationPermissionStatus.authorized ||
            newStatus == NotificationPermissionStatus.provisional;
      } else if (Platform.isAndroid &&
          currentStatus == NotificationPermissionStatus.denied) {
        ClixLogger.warning(
            'Notification permission was denied - user can re-enable via settings');
      }

      // Get existing settings or create new ones
      var settings = await getNotificationSettings();

      if (settings == null) {
        // Create initial settings
        settings = NotificationSettings(
          enabled: isGranted,
          categories: null,
          lastUpdated: DateTime.now(),
          status: isGranted
              ? NotificationPermissionStatus.authorized
              : currentStatus,
        );
      } else {
        // Update existing settings with current status
        settings = settings.copyWith(
          enabled: isGranted,
          status: isGranted
              ? NotificationPermissionStatus.authorized
              : currentStatus,
          lastUpdated: DateTime.now(),
        );
      }

      await _saveSettings(settings);
      ClixLogger.debug(
          'Permission service initialized - final status: ${settings.status.name}');
    } catch (e, stackTrace) {
      ClixLogger.error(
          'Failed to initialize permission service', e, stackTrace);
    }
  }

  // Private helper methods

  Future<void> _saveSettings(NotificationSettings settings) async {
    await _storage.setJson(_settingsKey, settings.toJson());
  }

  NotificationPermissionStatus _mapPermissionStatus(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return NotificationPermissionStatus.authorized;
      case PermissionStatus.denied:
        return NotificationPermissionStatus.denied;
      case PermissionStatus.permanentlyDenied:
        return NotificationPermissionStatus.permanentlyDenied;
      case PermissionStatus.restricted:
        return NotificationPermissionStatus.denied;
      case PermissionStatus.limited:
        return NotificationPermissionStatus.provisional;
      case PermissionStatus.provisional:
        return NotificationPermissionStatus.provisional;
    }
  }
}
