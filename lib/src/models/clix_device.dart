import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:json_annotation/json_annotation.dart';
import '../core/clix_version.dart';

part 'clix_device.g.dart';

/// Device information model matching iOS SDK structure
@JsonSerializable(fieldRename: FieldRename.snake)
class ClixDevice {
  final String id;
  final String platform;
  final String model;
  final String manufacturer;
  final String osName;
  final String osVersion;
  final String localeRegion;
  final String localeLanguage;
  final String timezone;
  final String appName;
  final String appVersion;
  final String sdkType;
  final String sdkVersion;
  final String? adId;
  final bool isPushPermissionGranted;
  final String? pushToken;
  final String? pushTokenType;

  const ClixDevice({
    required this.id,
    required this.platform,
    required this.model,
    required this.manufacturer,
    required this.osName,
    required this.osVersion,
    required this.localeRegion,
    required this.localeLanguage,
    required this.timezone,
    required this.appName,
    required this.appVersion,
    required this.sdkType,
    required this.sdkVersion,
    this.adId,
    required this.isPushPermissionGranted,
    this.pushToken,
    this.pushTokenType,
  });

  /// Create device info from platform information
  static Future<ClixDevice> create({
    required String deviceId,
    String? pushToken,
    bool isPushPermissionGranted = false,
  }) async {
    final deviceInfo = DeviceInfoPlugin();
    final packageInfo = await PackageInfo.fromPlatform();
    final platformName = _getPlatformName();

    // Get device-specific information
    String model = 'Unknown';
    String manufacturer = 'Unknown';
    String osVersion = 'Unknown';

    if (!kIsWeb) {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        model = androidInfo.model;
        manufacturer = androidInfo.manufacturer;
        osVersion = androidInfo.version.release;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        model = iosInfo.model;
        manufacturer = 'Apple';
        osVersion = iosInfo.systemVersion;
      }
    }

    // Get locale information
    final locale = _getCurrentLocale();
    final timezone = DateTime.now().timeZoneName;

    return ClixDevice(
      id: deviceId,
      platform: platformName,
      model: model,
      manufacturer: manufacturer,
      osName: _getOSName(),
      osVersion: osVersion,
      localeRegion: locale['region'] ?? 'US',
      localeLanguage: locale['language'] ?? 'en',
      timezone: timezone,
      appName: packageInfo.appName,
      appVersion: packageInfo.version,
      sdkType: 'flutter',
      sdkVersion: ClixVersion.version,
      adId: null, // Privacy-focused: not collecting advertising ID
      isPushPermissionGranted: isPushPermissionGranted,
      pushToken: pushToken,
      pushTokenType: pushToken != null ? _getPushTokenType() : null,
    );
  }

  /// Convert to JSON for API requests
  Map<String, dynamic> toJson() => _$ClixDeviceToJson(this);

  /// Create from JSON
  factory ClixDevice.fromJson(Map<String, dynamic> json) =>
      _$ClixDeviceFromJson(json);

  /// Create copy with updated fields
  ClixDevice copyWith({
    String? id,
    String? platform,
    String? model,
    String? manufacturer,
    String? osName,
    String? osVersion,
    String? localeRegion,
    String? localeLanguage,
    String? timezone,
    String? appName,
    String? appVersion,
    String? sdkType,
    String? sdkVersion,
    String? adId,
    bool? isPushPermissionGranted,
    String? pushToken,
    String? pushTokenType,
  }) {
    return ClixDevice(
      id: id ?? this.id,
      platform: platform ?? this.platform,
      model: model ?? this.model,
      manufacturer: manufacturer ?? this.manufacturer,
      osName: osName ?? this.osName,
      osVersion: osVersion ?? this.osVersion,
      localeRegion: localeRegion ?? this.localeRegion,
      localeLanguage: localeLanguage ?? this.localeLanguage,
      timezone: timezone ?? this.timezone,
      appName: appName ?? this.appName,
      appVersion: appVersion ?? this.appVersion,
      sdkType: sdkType ?? this.sdkType,
      sdkVersion: sdkVersion ?? this.sdkVersion,
      adId: adId ?? this.adId,
      isPushPermissionGranted:
          isPushPermissionGranted ?? this.isPushPermissionGranted,
      pushToken: pushToken ?? this.pushToken,
      pushTokenType: pushTokenType ?? this.pushTokenType,
    );
  }

  @override
  String toString() {
    return 'ClixDevice(id: $id, platform: $platform, model: $model, osVersion: $osVersion)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ClixDevice && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  // Helper methods
  static String _getPlatformName() {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isWindows) return 'windows';
    if (Platform.isLinux) return 'linux';
    return 'unknown';
  }

  static String _getOSName() {
    if (kIsWeb) return 'Web';
    if (Platform.isAndroid) return 'Android';
    if (Platform.isIOS) return 'iOS';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isWindows) return 'Windows';
    if (Platform.isLinux) return 'Linux';
    return 'Unknown';
  }

  static Map<String, String> _getCurrentLocale() {
    // This is a simplified implementation
    // In a real app, you might want to use the intl package
    return {
      'language': 'en',
      'region': 'US',
    };
  }

  static String _getPushTokenType() {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'fcm';
    if (Platform.isIOS) return 'apns';
    return 'unknown';
  }
}
