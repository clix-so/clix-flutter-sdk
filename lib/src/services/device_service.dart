// Removed unused clix_device import
import '../models/clix_user_property.dart';
import '../utils/logging/clix_logger.dart';
import '../utils/clix_error.dart';
import 'device_api_service.dart';
import 'storage_service.dart';

/// Device service for managing device registration and user properties
/// Simplified version that mirrors iOS SDK DeviceService
class DeviceService {
  final DeviceAPIService _deviceAPIService;
  final StorageService _storage;

  static const String _deviceIdKey = 'device_id';
  static const String _userIdKey = 'user_id';

  DeviceService({
    required DeviceAPIService deviceAPIService,
    required StorageService storage,
  })  : _deviceAPIService = deviceAPIService,
        _storage = storage;

  /// Get current device ID
  String? getDeviceId() {
    try {
      return _storage.getString(_deviceIdKey);
    } catch (e) {
      ClixLogger.error('Failed to get device ID', e);
      return null;
    }
  }

  /// Set user ID - mirrors iOS setUserId method
  Future<void> setUserId(String userId) async {
    try {
      await _storage.setString(_userIdKey, userId);
      ClixLogger.info('User ID set: $userId');
    } catch (e) {
      ClixLogger.error('Failed to set user ID', e);
      throw ClixError.unknownErrorWithReason('Failed to set user ID: $e');
    }
  }

  /// Remove user ID - mirrors iOS removeUserId method
  Future<void> removeUserId() async {
    try {
      await _storage.remove(_userIdKey);
      ClixLogger.info('User ID removed');
    } catch (e) {
      ClixLogger.error('Failed to remove user ID', e);
      throw ClixError.unknownErrorWithReason('Failed to remove user ID: $e');
    }
  }

  /// Get current user ID
  String? getUserId() {
    try {
      return _storage.getString(_userIdKey);
    } catch (e) {
      ClixLogger.error('Failed to get user ID', e);
      return null;
    }
  }

  /// Set user property - mirrors iOS setUserProperty method
  Future<void> setUserProperty(String key, dynamic value) async {
    try {
      final userProperty = ClixUserProperty.of(name: key, value: value);
      final deviceId = getDeviceId();
      
      if (deviceId == null) {
        throw ClixError.unknownErrorWithReason('Device ID not available');
      }

      await _deviceAPIService.upsertUserProperties(
        deviceId: deviceId,
        properties: [userProperty],
      );

      // Store locally as well
      await _storage.setString('user_property_$key', value.toString());
      ClixLogger.info('User property set: $key');
    } catch (e) {
      ClixLogger.error('Failed to set user property', e);
      throw ClixError.unknownErrorWithReason('Failed to set user property: $e');
    }
  }

  /// Set multiple user properties - mirrors iOS setUserProperties method
  Future<void> setUserProperties(Map<String, dynamic> properties) async {
    try {
      final userProperties = properties.entries
          .map((entry) => ClixUserProperty.of(name: entry.key, value: entry.value))
          .toList();
      
      final deviceId = getDeviceId();
      if (deviceId == null) {
        throw ClixError.unknownErrorWithReason('Device ID not available');
      }

      await _deviceAPIService.upsertUserProperties(
        deviceId: deviceId,
        properties: userProperties,
      );

      // Store locally as well
      for (final entry in properties.entries) {
        await _storage.setString('user_property_${entry.key}', entry.value.toString());
      }

      ClixLogger.info('User properties set: ${properties.keys.join(', ')}');
    } catch (e) {
      ClixLogger.error('Failed to set user properties', e);
      throw ClixError.unknownErrorWithReason('Failed to set user properties: $e');
    }
  }

  /// Remove user property - mirrors iOS removeUserProperty method
  Future<void> removeUserProperty(String key) async {
    try {
      final deviceId = getDeviceId();
      if (deviceId == null) {
        throw ClixError.unknownErrorWithReason('Device ID not available');
      }

      await _deviceAPIService.removeUserProperties(
        deviceId: deviceId,
        propertyNames: [key],
      );

      // Remove locally as well
      await _storage.remove('user_property_$key');
      ClixLogger.info('User property removed: $key');
    } catch (e) {
      ClixLogger.error('Failed to remove user property', e);
      throw ClixError.unknownErrorWithReason('Failed to remove user property: $e');
    }
  }

  /// Remove multiple user properties - mirrors iOS removeUserProperties method
  Future<void> removeUserProperties(List<String> keys) async {
    try {
      final deviceId = getDeviceId();
      if (deviceId == null) {
        throw ClixError.unknownErrorWithReason('Device ID not available');
      }

      await _deviceAPIService.removeUserProperties(
        deviceId: deviceId,
        propertyNames: keys,
      );

      // Remove locally as well
      for (final key in keys) {
        await _storage.remove('user_property_$key');
      }

      ClixLogger.info('User properties removed: ${keys.join(', ')}');
    } catch (e) {
      ClixLogger.error('Failed to remove user properties', e);
      throw ClixError.unknownErrorWithReason('Failed to remove user properties: $e');
    }
  }

  /// Generate or store device ID
  Future<void> _ensureDeviceId() async {
    if (getDeviceId() == null) {
      // Generate a simple device ID
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final deviceId = 'flutter_device_$timestamp';
      await _storage.setString(_deviceIdKey, deviceId);
      ClixLogger.info('Generated device ID: $deviceId');
    }
  }

  /// Initialize device - creates device ID if needed
  Future<void> initialize() async {
    await _ensureDeviceId();
  }
}