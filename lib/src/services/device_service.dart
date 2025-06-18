import 'dart:io';
import 'package:uuid/uuid.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../core/clix_version.dart';
import '../models/clix_device.dart';
import '../models/clix_user_property.dart';
import '../utils/logging/clix_logger.dart';
import '../utils/clix_error.dart';
import 'device_api_service.dart';
import 'storage_service.dart';
import 'token_service.dart';

class DeviceService {
  final StorageService _storageService;
  final TokenService _tokenService;
  final DeviceAPIService _deviceAPIService;

  static const String _deviceIdKey = 'clix_device_id';

  DeviceService({
    required StorageService storageService,
    required TokenService tokenService,
    required DeviceAPIService deviceAPIService,
  })  : _storageService = storageService,
        _tokenService = tokenService,
        _deviceAPIService = deviceAPIService;

  Future<String> getCurrentDeviceId() async {
    final existingId = await _storageService.get<String>(_deviceIdKey);
    if (existingId != null) {
      return existingId;
    }
    
    const uuid = Uuid();
    final newId = uuid.v4();
    await _storageService.set<String>(_deviceIdKey, newId);
    return newId;
  }

  Future<void> setProjectUserId(String projectUserId) async {
    try {
      final deviceId = await getCurrentDeviceId();
      await _deviceAPIService.setProjectUserId(
        deviceId: deviceId,
        projectUserId: projectUserId,
      );
      ClixLogger.info('Project user ID set: $projectUserId');
    } catch (e) {
      ClixLogger.error('Failed to set project user ID', e);
      throw ClixError.unknownErrorWithReason('Failed to set project user ID: $e');
    }
  }

  Future<void> removeProjectUserId() async {
    try {
      final deviceId = await getCurrentDeviceId();
      await _deviceAPIService.removeProjectUserId(deviceId: deviceId);
      ClixLogger.info('Project user ID removed');
    } catch (e) {
      ClixLogger.error('Failed to remove project user ID', e);
      throw ClixError.unknownErrorWithReason('Failed to remove project user ID: $e');
    }
  }

  Future<void> updateUserProperties(Map<String, dynamic> properties) async {
    try {
      final userProperties = properties.entries
          .map((entry) => ClixUserProperty.of(name: entry.key, value: entry.value))
          .toList();
      
      final deviceId = await getCurrentDeviceId();
      await _deviceAPIService.upsertUserProperties(
        deviceId: deviceId,
        properties: userProperties,
      );

      ClixLogger.info('User properties updated: ${properties.keys.join(', ')}');
    } catch (e) {
      ClixLogger.error('Failed to update user properties', e);
      throw ClixError.unknownErrorWithReason('Failed to update user properties: $e');
    }
  }

  Future<void> removeUserProperties(List<String> names) async {
    try {
      final deviceId = await getCurrentDeviceId();
      await _deviceAPIService.removeUserProperties(
        deviceId: deviceId,
        propertyNames: names,
      );

      ClixLogger.info('User properties removed: ${names.join(', ')}');
    } catch (e) {
      ClixLogger.error('Failed to remove user properties', e);
      throw ClixError.unknownErrorWithReason('Failed to remove user properties: $e');
    }
  }

  Future<void> upsertToken(String token, {String tokenType = 'FCM'}) async {
    try {
      await _tokenService.saveToken(token);
      
      final deviceId = await getCurrentDeviceId();
      final device = await createDevice(deviceId: deviceId, token: token);
      
      await _deviceAPIService.registerDevice(device: device);
      
      ClixLogger.info('Token upserted: $tokenType');
    } catch (e) {
      ClixLogger.error('Failed to upsert token', e);
      throw ClixError.unknownErrorWithReason('Failed to upsert token: $e');
    }
  }

  static Future<ClixDevice> createDevice({required String deviceId, String? token}) async {
    final deviceInfo = DeviceInfoPlugin();
    final packageInfo = await PackageInfo.fromPlatform();
    
    String platform;
    String model;
    String manufacturer;
    String osName;
    String osVersion;
    
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      platform = 'Android';
      model = androidInfo.model;
      manufacturer = androidInfo.manufacturer;
      osName = 'Android';
      osVersion = androidInfo.version.release;
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      platform = 'iOS';
      model = iosInfo.model;
      manufacturer = 'Apple';
      osName = iosInfo.systemName;
      osVersion = iosInfo.systemVersion;
    } else {
      platform = Platform.operatingSystem;
      model = 'Unknown';
      manufacturer = 'Unknown';
      osName = Platform.operatingSystem;
      osVersion = Platform.operatingSystemVersion;
    }
    
    final locale = Platform.localeName.split('_');
    final localeLanguage = locale.isNotEmpty ? locale[0] : 'en';
    final localeRegion = locale.length > 1 ? locale[1] : 'US';
    
    final timezone = DateTime.now().timeZoneName;
    
    bool isPushPermissionGranted = false;
    try {
      final settings = await FirebaseMessaging.instance.getNotificationSettings();
      isPushPermissionGranted = settings.authorizationStatus == AuthorizationStatus.authorized ||
                               settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      ClixLogger.error('Failed to get push permission status', e);
    }
    
    return ClixDevice(
      id: deviceId,
      platform: platform,
      model: model,
      manufacturer: manufacturer,
      osName: osName,
      osVersion: osVersion,
      localeRegion: localeRegion,
      localeLanguage: localeLanguage,
      timezone: timezone,
      appName: packageInfo.appName,
      appVersion: packageInfo.version,
      sdkType: 'flutter',
      sdkVersion: await ClixVersion.version,
      adId: null,
      isPushPermissionGranted: isPushPermissionGranted,
      pushToken: token,
      pushTokenType: token != null ? 'FCM' : null,
    );
  }
}