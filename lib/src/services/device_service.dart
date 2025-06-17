import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import '../utils/uuid_generator.dart';
import '../models/clix_device.dart';
import '../models/clix_user_property.dart';
import '../utils/logger.dart';
import '../utils/clix_error.dart';
import 'clix_api_client.dart';
import 'storage_service.dart';
import 'permission_service.dart';
import 'platform_service.dart';

/// Device service for managing device registration and user properties
class DeviceService {
  final ClixAPIClient _apiClient;
  final StorageService _storage;
  final PermissionService _permissionService;

  static const String _deviceIdKey = 'device_id';
  static const String _userIdKey = 'user_id';
  static const String _projectUserIdKey = 'project_user_id';
  static const String _pushTokenKey = 'push_token';
  static const String _pushPermissionKey = 'push_permission_granted';

  DeviceService({
    required ClixAPIClient apiClient,
    required StorageService storage,
    required PermissionService permissionService,
  })  : _apiClient = apiClient,
        _storage = storage,
        _permissionService = permissionService;

  /// Generate or retrieve device ID
  Future<String> getOrCreateDeviceId() async {
    try {
      // Check if device ID already exists
      String? deviceId = _storage.getString(_deviceIdKey);

      if (deviceId != null && deviceId.isNotEmpty) {
        ClixLogger.debug('Using existing device ID: $deviceId');
        return deviceId;
      }

      // Generate new device ID
      deviceId = await _generateDeviceId();
      await _storage.setString(_deviceIdKey, deviceId);

      ClixLogger.info('Generated new device ID: $deviceId');
      return deviceId;
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to get or create device ID', e, stackTrace);
      throw ClixError.now(
        code: 'DEVICE_ID_ERROR',
        message: 'Failed to generate device ID',
        details: e,
      );
    }
  }

  /// Register device with Clix API
  Future<void> registerDevice({
    String? pushToken,
    bool? isPushPermissionGranted,
  }) async {
    try {
      final deviceId = await getOrCreateDeviceId();

      // Initialize permission service (will auto-request on Android API 31+)
      await _permissionService.initialize();

      // Wait a bit for permission dialog to complete on Android
      await Future.delayed(const Duration(milliseconds: 500));

      // Check current permission status if not provided
      final actualPermissionStatus =
          await _permissionService.getNotificationPermissionStatus();
      final permissionGranted = isPushPermissionGranted ??
          await _permissionService.isNotificationPermissionGranted();

      ClixLogger.info(
          'Device registration - permission status: ${actualPermissionStatus.name}');
      ClixLogger.info(
          'Device registration - permission granted: $permissionGranted');
      ClixLogger.info(
          'Device registration - isPushPermissionGranted param: $isPushPermissionGranted');

      // Try to get push token if not provided
      String? finalPushToken = pushToken;
      if (finalPushToken == null) {
        try {
          ClixLogger.debug('Attempting to retrieve push token...');
          finalPushToken = await _getPushTokenWithRetry();
          ClixLogger.debug(
              'Push token retrieval result: ${finalPushToken != null ? 'success' : 'failed'}');
        } catch (e) {
          ClixLogger.warning(
              'Failed to get push token, proceeding without it: $e');
        }
      }

      // Create device info
      final device = await ClixDevice.create(
        deviceId: deviceId,
        pushToken: finalPushToken,
        isPushPermissionGranted: permissionGranted,
      );

      ClixLogger.debug('Created device - pushToken: ${device.pushToken}');
      ClixLogger.debug(
          'Created device - pushTokenType: ${device.pushTokenType}');
      ClixLogger.debug(
          'Created device - isPushPermissionGranted: ${device.isPushPermissionGranted}');

      // Store device info locally
      await _storage.setJson('device_info', device.toJson());

      // Register with API using iOS SDK format
      final body = {
        'devices': [device.toJson()]
      };

      final response = await _apiClient.post<Map<String, dynamic>>(
        '/devices',
        body: body,
      );

      if (response.isSuccess) {
        ClixLogger.info('Device registered successfully');

        // Store any additional info from response
        if (response.data.containsKey('projectUserId')) {
          await _storage.setString(
              _projectUserIdKey, response.data['projectUserId']);
        }
      } else {
        throw ClixError.now(
          code: 'DEVICE_REGISTRATION_FAILED',
          message: 'Failed to register device',
        );
      }
    } catch (e, stackTrace) {
      ClixLogger.error('Device registration failed', e, stackTrace);
      if (e is ClixError) rethrow;
      throw ClixError.now(
        code: 'DEVICE_REGISTRATION_ERROR',
        message: 'Device registration failed: $e',
        details: e,
      );
    }
  }

  /// Get push token with retry logic
  Future<String?> _getPushTokenWithRetry() async {
    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        ClixLogger.debug('Push token retrieval attempt $attempt/3');

        // Use PlatformService to get push token
        final token = await PlatformService.getPushToken();

        if (token != null && token.isNotEmpty) {
          ClixLogger.debug(
              'Push token retrieved successfully on attempt $attempt');
          return token;
        }

        ClixLogger.debug('Push token is null or empty on attempt $attempt');

        if (attempt < 3) {
          await Future.delayed(Duration(milliseconds: 500 * attempt));
        }
      } catch (e) {
        ClixLogger.warning(
            'Push token retrieval failed on attempt $attempt: $e');
        if (attempt < 3) {
          await Future.delayed(Duration(milliseconds: 500 * attempt));
        }
      }
    }

    ClixLogger.warning('Failed to retrieve push token after 3 attempts');
    return null;
  }

  /// Update device information using upsert pattern (same as iOS SDK)
  Future<void> updateDevice({
    String? pushToken,
    bool? isPushPermissionGranted,
  }) async {
    try {
      final deviceId = await getOrCreateDeviceId();

      // Get current device info
      final currentDeviceInfo = _storage.getJson('device_info');
      ClixDevice currentDevice;

      if (currentDeviceInfo != null) {
        currentDevice = ClixDevice.fromJson(currentDeviceInfo);
      } else {
        // Create new device info if none exists
        currentDevice = await ClixDevice.create(
          deviceId: deviceId,
          pushToken: pushToken,
          isPushPermissionGranted: isPushPermissionGranted ?? false,
        );
      }

      // Update device with new information
      final updatedDevice = currentDevice.copyWith(
        pushToken: pushToken,
        isPushPermissionGranted: isPushPermissionGranted,
      );

      // Store updated device info
      await _storage.setJson('device_info', updatedDevice.toJson());

      // Use same upsert endpoint as iOS SDK (POST /devices, not PUT)
      final body = {
        'devices': [updatedDevice.toJson()]
      };

      final response = await _apiClient.post<Map<String, dynamic>>(
        '/devices',
        body: body,
      );

      if (response.isSuccess) {
        ClixLogger.info('Device updated successfully');
      } else {
        ClixLogger.warning('Failed to update device via API');
      }
    } catch (e, stackTrace) {
      ClixLogger.error('Device update failed', e, stackTrace);
      throw ClixError.now(
        code: 'DEVICE_UPDATE_ERROR',
        message: 'Device update failed: $e',
        details: e,
      );
    }
  }

  /// Set user ID
  Future<void> setUserId(String userId) async {
    try {
      await _storage.setString(_userIdKey, userId);

      // Update user ID via API using iOS SDK endpoint
      final deviceId = await getOrCreateDeviceId();
      await _apiClient.post<Map<String, dynamic>>(
        '/devices/$deviceId/user/project-user-id',
        body: {'projectUserId': userId},
      );

      ClixLogger.info('User ID set: $userId');
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to set user ID', e, stackTrace);
      throw ClixError.now(
        code: 'SET_USER_ID_ERROR',
        message: 'Failed to set user ID: $e',
        details: e,
      );
    }
  }

  /// Remove user ID
  Future<void> removeUserId() async {
    try {
      await _storage.remove(_userIdKey);
      await _storage.remove(_projectUserIdKey);

      // Remove user ID via API using iOS SDK endpoint
      final deviceId = await getOrCreateDeviceId();
      await _apiClient.delete<Map<String, dynamic>>(
        '/devices/$deviceId/user/project-user-id',
      );

      ClixLogger.info('User ID removed');
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to remove user ID', e, stackTrace);
      throw ClixError.now(
        code: 'REMOVE_USER_ID_ERROR',
        message: 'Failed to remove user ID: $e',
        details: e,
      );
    }
  }

  /// Set user property
  Future<void> setUserProperty(String key, dynamic value) async {
    try {
      final property = ClixUserProperty.fromValue(key, value);

      // Store locally
      await _storage.setJson('user_property_$key', property.toJson());

      // Update via API using iOS SDK endpoint
      final deviceId = await getOrCreateDeviceId();
      await _apiClient.post<Map<String, dynamic>>(
        '/devices/$deviceId/user/properties',
        body: {
          'properties': [property.toJson()],
        },
      );

      ClixLogger.debug('User property set: $key = $value');
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to set user property', e, stackTrace);
      throw ClixError.now(
        code: 'SET_USER_PROPERTY_ERROR',
        message: 'Failed to set user property: $e',
        details: e,
      );
    }
  }

  /// Set multiple user properties
  Future<void> setUserProperties(Map<String, dynamic> properties) async {
    try {
      final propertyList = properties.entries
          .map((e) => ClixUserProperty.fromValue(e.key, e.value))
          .toList();

      // Store locally
      for (final property in propertyList) {
        await _storage.setJson(
            'user_property_${property.name}', property.toJson());
      }

      // Update via API using iOS SDK endpoint
      final deviceId = await getOrCreateDeviceId();
      await _apiClient.post<Map<String, dynamic>>(
        '/devices/$deviceId/user/properties',
        body: {
          'properties': propertyList.map((p) => p.toJson()).toList(),
        },
      );

      ClixLogger.debug(
          'User properties set: ${properties.keys.length} properties');
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to set user properties', e, stackTrace);
      throw ClixError.now(
        code: 'SET_USER_PROPERTIES_ERROR',
        message: 'Failed to set user properties: $e',
        details: e,
      );
    }
  }

  /// Remove user property
  Future<void> removeUserProperty(String key) async {
    try {
      // Remove locally
      await _storage.remove('user_property_$key');

      // Remove via API using iOS SDK endpoint
      final deviceId = await getOrCreateDeviceId();
      await _apiClient.delete<Map<String, dynamic>>(
        '/devices/$deviceId/user/properties',
        queryParameters: {
          'names': [key],
        },
      );

      ClixLogger.debug('User property removed: $key');
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to remove user property', e, stackTrace);
      throw ClixError.now(
        code: 'REMOVE_USER_PROPERTY_ERROR',
        message: 'Failed to remove user property: $e',
        details: e,
      );
    }
  }

  /// Remove multiple user properties
  Future<void> removeUserProperties(List<String> keys) async {
    try {
      // Remove locally
      for (final key in keys) {
        await _storage.remove('user_property_$key');
      }

      // Remove via API using iOS SDK endpoint
      final deviceId = await getOrCreateDeviceId();
      await _apiClient.delete<Map<String, dynamic>>(
        '/devices/$deviceId/user/properties',
        queryParameters: {
          'names': keys,
        },
      );

      ClixLogger.debug('User properties removed: ${keys.length} properties');
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to remove user properties', e, stackTrace);
      throw ClixError.now(
        code: 'REMOVE_USER_PROPERTIES_ERROR',
        message: 'Failed to remove user properties: $e',
        details: e,
      );
    }
  }

  /// Update push token
  Future<void> updatePushToken(String token) async {
    try {
      await _storage.setString(_pushTokenKey, token);
      await updateDevice(pushToken: token);
      ClixLogger.info('Push token updated');
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to update push token', e, stackTrace);
      throw ClixError.now(
        code: 'UPDATE_PUSH_TOKEN_ERROR',
        message: 'Failed to update push token: $e',
        details: e,
      );
    }
  }

  /// Update push permission status
  Future<void> updatePushPermission(bool granted) async {
    try {
      await _storage.setBool(_pushPermissionKey, granted);
      await updateDevice(isPushPermissionGranted: granted);
      ClixLogger.info('Push permission updated: $granted');
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to update push permission', e, stackTrace);
      throw ClixError.now(
        code: 'UPDATE_PUSH_PERMISSION_ERROR',
        message: 'Failed to update push permission: $e',
        details: e,
      );
    }
  }

  /// Get current device ID
  String? getDeviceId() {
    return _storage.getString(_deviceIdKey);
  }

  /// Get current user ID
  String? getUserId() {
    return _storage.getString(_userIdKey);
  }

  /// Get current push token
  String? getPushToken() {
    return _storage.getString(_pushTokenKey);
  }

  /// Check if push permission is granted
  bool isPushPermissionGranted() {
    return _storage.getBool(_pushPermissionKey) ?? false;
  }

  // Push permission management methods

  /// Request notification permissions
  Future<bool> requestNotificationPermissions() async {
    try {
      final granted = await _permissionService.requestNotificationPermission();
      await updatePushPermission(granted);
      return granted;
    } catch (e, stackTrace) {
      ClixLogger.error(
          'Failed to request notification permissions', e, stackTrace);
      return false;
    }
  }

  /// Get current notification permission status
  Future<NotificationPermissionStatus> getNotificationPermissionStatus() async {
    return await _permissionService.getNotificationPermissionStatus();
  }

  /// Check if notification permissions are granted
  Future<bool> checkNotificationPermissions() async {
    return await _permissionService.isNotificationPermissionGranted();
  }

  /// Open notification settings if permission is denied
  Future<bool> openNotificationSettings() async {
    return await _permissionService.openNotificationSettings();
  }

  /// Get detailed permission information
  Future<Map<String, dynamic>> getPermissionInfo() async {
    return await _permissionService.getPermissionInfo();
  }

  /// Set notification preferences
  Future<void> setNotificationPreferences({
    required bool enabled,
    List<String>? categories,
  }) async {
    try {
      await _permissionService.setNotificationPreferences(
        enabled: enabled,
        categories: categories,
      );

      // Update device with new permission status
      final granted =
          await _permissionService.isNotificationPermissionGranted();
      await updatePushPermission(granted);
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to set notification preferences', e, stackTrace);
      throw ClixError.now(
        code: 'SET_NOTIFICATION_PREFERENCES_ERROR',
        message: 'Failed to set notification preferences: $e',
        details: e,
      );
    }
  }

  /// Check if permission is permanently denied
  Future<bool> isPermissionPermanentlyDenied() async {
    return await _permissionService.isPermissionPermanentlyDenied();
  }

  /// Get notification settings
  Future<NotificationSettings?> getNotificationSettings() async {
    return await _permissionService.getNotificationSettings();
  }

  // Private helper methods

  /// Generate device ID using device_info_plus library
  Future<String> _generateDeviceId() async {
    try {
      if (kIsWeb) {
        // For web, use a UUID since we can't get device-specific info
        return 'web_${UuidGenerator.generateV4()}';
      }

      final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      
      if (Platform.isAndroid) {
        final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        
        // Use Android ID as primary identifier
        // If not available, fallback to a combination of device identifiers
        final androidId = androidInfo.id;
        if (androidId.isNotEmpty && androidId != 'unknown') {
          return 'android_$androidId';
        }
        
        // Fallback: create deterministic ID from device characteristics
        final deviceSignature = '${androidInfo.manufacturer}_${androidInfo.model}_${androidInfo.device}'.replaceAll(' ', '_').toLowerCase();
        return 'android_${deviceSignature}_${UuidGenerator.generateV4()}';
        
      } else if (Platform.isIOS) {
        final IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        
        // Use identifierForVendor as primary identifier
        final vendorId = iosInfo.identifierForVendor;
        if (vendorId != null && vendorId.isNotEmpty) {
          return 'ios_$vendorId';
        }
        
        // Fallback: create deterministic ID from device characteristics  
        final deviceSignature = '${iosInfo.model}_${iosInfo.systemVersion}'.replaceAll(' ', '_').toLowerCase();
        return 'ios_${deviceSignature}_${UuidGenerator.generateV4()}';
        
      } else {
        // Other platforms (Linux, macOS, Windows)
        return '${Platform.operatingSystem}_${UuidGenerator.generateV4()}';
      }
    } catch (e) {
      ClixLogger.warning('Failed to generate device-specific ID, using UUID fallback: $e');
      
      // Final fallback to UUID
      return 'fallback_${UuidGenerator.generateV4()}';
    }
  }
}
