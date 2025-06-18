// Removed unused imports
import 'package:json_annotation/json_annotation.dart';

part 'clix_device.g.dart';

/// ClixDevice model that mirrors the iOS SDK ClixDevice implementation
@JsonSerializable()
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

  /// Convert to JSON map
  Map<String, dynamic> toJson() => _$ClixDeviceToJson(this);

  /// Create from JSON map
  factory ClixDevice.fromJson(Map<String, dynamic> json) => _$ClixDeviceFromJson(json);

  /// Create a copy with updated fields
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
      isPushPermissionGranted: isPushPermissionGranted ?? this.isPushPermissionGranted,
      pushToken: pushToken ?? this.pushToken,
      pushTokenType: pushTokenType ?? this.pushTokenType,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ClixDevice && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ClixDevice(id: $id, platform: $platform, model: $model)';
  }
}