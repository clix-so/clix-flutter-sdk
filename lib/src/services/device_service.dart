import 'dart:async';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'device_api_service.dart';
import 'storage_service.dart';
import '../core/clix_environment.dart';
import '../core/clix_version.dart';
import '../models/clix_device.dart';
import '../utils/logger.dart';

class DeviceService {
  static const String _deviceIdKey = 'device_id';
  static const String _userIdKey = 'user_id';
  static const String _deviceInfoKey = 'device_info';
  static const String _pushTokenKey = 'push_token';

  final DeviceAPIService _deviceAPIService;
  final StorageService _storage;
  final ClixEnvironment _environment;
  final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();

  String? _deviceId;
  String? _userId;
  String? _pushToken;
  ClixDevice? _cachedDeviceInfo;

  DeviceService({
    required DeviceAPIService deviceAPIService,
    required StorageService storage,
    required ClixEnvironment environment,
  })  : _deviceAPIService = deviceAPIService,
        _storage = storage,
        _environment = environment;

  String? get deviceId => _deviceId;
  String? get userId => _userId;
  String? get pushToken => _pushToken;
  ClixDevice? get deviceInfo => _cachedDeviceInfo;

  Future<void> initialize() async {
    try {
      _deviceId = _storage.getString(_deviceIdKey);
      if (_deviceId == null) {
        _deviceId = const Uuid().v4();
        await _storage.setString(_deviceIdKey, _deviceId!);
      }

      _userId = _storage.getString(_userIdKey);
      _pushToken = _storage.getString(_pushTokenKey);

      final storedDeviceInfo = _storage.getJson(_deviceInfoKey);
      if (storedDeviceInfo != null) {
        _cachedDeviceInfo = ClixDevice.fromJson(storedDeviceInfo);
      }

      await _updateDeviceInfo();
      ClixLogger.debug('DeviceService initialized with device ID: $_deviceId');
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to initialize DeviceService', e, stackTrace);
      rethrow;
    }
  }

  Future<void> _updateDeviceInfo() async {
    try {
      final deviceInfo = await _getDeviceInfo();
      _cachedDeviceInfo = deviceInfo;

      await _storage.setJson(_deviceInfoKey, deviceInfo.toJson());
      await _syncDevice();
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to update device info', e, stackTrace);
    }
  }

  Future<ClixDevice> _getDeviceInfo() async {
    String platform = _environment.platform;
    String model = 'Unknown';
    String manufacturer = 'Unknown';
    String osName = 'Unknown';
    String osVersion = 'Unknown';

    try {
      if (Platform.isIOS) {
        final iosInfo = await _deviceInfoPlugin.iosInfo;
        model = iosInfo.model;
        manufacturer = 'Apple';
        osName = iosInfo.systemName;
        osVersion = iosInfo.systemVersion;
      } else if (Platform.isAndroid) {
        final androidInfo = await _deviceInfoPlugin.androidInfo;
        model = androidInfo.model;
        manufacturer = androidInfo.manufacturer;
        osName = 'Android';
        osVersion = androidInfo.version.release;
      } else if (kIsWeb) {
        final webInfo = await _deviceInfoPlugin.webBrowserInfo;
        model = webInfo.browserName.name;
        manufacturer = webInfo.vendor ?? 'Unknown';
        osName = webInfo.platform ?? 'Web';
        osVersion = webInfo.userAgent ?? 'Unknown';
      }
    } catch (e) {
      ClixLogger.warning('Failed to get detailed device info', e);
    }

    final locale = Platform.localeName.split('_');
    final localeLanguage = locale.isNotEmpty ? locale[0] : 'en';
    final localeRegion = locale.length > 1 ? locale[1] : 'US';

    return ClixDevice(
      id: _deviceId!,
      platform: platform,
      model: model,
      manufacturer: manufacturer,
      osName: osName,
      osVersion: osVersion,
      localeRegion: localeRegion,
      localeLanguage: localeLanguage,
      timezone: DateTime.now().timeZoneName,
      appName: _environment.appName,
      appVersion: _environment.appVersion,
      sdkType: _environment.sdkType,
      sdkVersion: ClixVersion.version,
      adId: _environment.adId,
      isPushPermissionGranted: _pushToken != null,
      pushToken: _pushToken,
      pushTokenType: _pushToken != null ? 'FCM' : null,
    );
  }

  Future<void> _syncDevice() async {
    try {
      if (_cachedDeviceInfo == null || _deviceId == null) return;

      await _deviceAPIService.syncDevice(_cachedDeviceInfo!);
      ClixLogger.debug('Device synced successfully');
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to sync device', e, stackTrace);
    }
  }

  Future<void> updatePushToken(String token, String tokenType) async {
    try {
      if (_deviceId == null) return;

      _pushToken = token;
      await _storage.setString(_pushTokenKey, token);

      if (_cachedDeviceInfo != null) {
        _cachedDeviceInfo = _cachedDeviceInfo!.copyWith(
          pushToken: token,
          pushTokenType: tokenType,
          isPushPermissionGranted: true,
        );

        await _storage.setJson(_deviceInfoKey, _cachedDeviceInfo!.toJson());
      }

      await _deviceAPIService.updatePushToken(
        deviceId: _deviceId!,
        token: token,
        tokenType: tokenType,
      );
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to update push token', e, stackTrace);
    }
  }

  Future<void> setUserId(String userId) async {
    try {
      if (_deviceId == null) {
        throw StateError('Device not initialized');
      }

      _userId = userId;
      await _storage.setString(_userIdKey, userId);

      await _deviceAPIService.setUserId(
        deviceId: _deviceId!,
        userId: userId,
      );

      ClixLogger.info('User ID set: $userId');
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to set user ID', e, stackTrace);
      rethrow;
    }
  }

  Future<void> removeUserId() async {
    try {
      if (_deviceId == null) {
        throw StateError('Device not initialized');
      }

      _userId = null;
      await _storage.remove(_userIdKey);

      await _deviceAPIService.removeUserId(deviceId: _deviceId!);

      ClixLogger.info('User ID removed');
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to remove user ID', e, stackTrace);
      rethrow;
    }
  }

  Future<void> setUserProperty(String name, dynamic value) async {
    try {
      if (_deviceId == null) {
        throw StateError('Device not initialized');
      }

      await _deviceAPIService.setUserProperty(
        deviceId: _deviceId!,
        name: name,
        value: value,
      );

      ClixLogger.debug('User property set: $name = $value');
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to set user property', e, stackTrace);
      rethrow;
    }
  }

  Future<void> setUserProperties(Map<String, dynamic> properties) async {
    try {
      if (_deviceId == null) {
        throw StateError('Device not initialized');
      }

      await _deviceAPIService.setUserProperties(
        deviceId: _deviceId!,
        properties: properties,
      );

      ClixLogger.debug('User properties set: ${properties.keys.join(', ')}');
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to set user properties', e, stackTrace);
      rethrow;
    }
  }

  Future<void> removeUserProperty(String name) async {
    try {
      if (_deviceId == null) {
        throw StateError('Device not initialized');
      }

      await _deviceAPIService.removeUserProperty(
        deviceId: _deviceId!,
        name: name,
      );

      ClixLogger.debug('User property removed: $name');
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to remove user property', e, stackTrace);
      rethrow;
    }
  }

  Future<void> removeUserProperties(List<String> names) async {
    try {
      if (_deviceId == null) {
        throw StateError('Device not initialized');
      }

      await _deviceAPIService.removeUserProperties(
        deviceId: _deviceId!,
        names: names,
      );

      ClixLogger.debug('User properties removed: ${names.join(', ')}');
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to remove user properties', e, stackTrace);
      rethrow;
    }
  }
}
