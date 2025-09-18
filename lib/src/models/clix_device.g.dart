// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clix_device.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ClixDevice _$ClixDeviceFromJson(Map json) => ClixDevice(
      id: json['id'] as String,
      platform: json['platform'] as String,
      model: json['model'] as String,
      manufacturer: json['manufacturer'] as String,
      osName: json['os_name'] as String,
      osVersion: json['os_version'] as String,
      localeRegion: json['locale_region'] as String,
      localeLanguage: json['locale_language'] as String,
      timezone: json['timezone'] as String,
      appName: json['app_name'] as String,
      appVersion: json['app_version'] as String,
      sdkType: json['sdk_type'] as String,
      sdkVersion: json['sdk_version'] as String,
      adId: json['ad_id'] as String?,
      isPushPermissionGranted: json['is_push_permission_granted'] as bool,
      pushToken: json['push_token'] as String?,
      pushTokenType: json['push_token_type'] as String?,
    );

Map<String, dynamic> _$ClixDeviceToJson(ClixDevice instance) =>
    <String, dynamic>{
      'id': instance.id,
      'platform': instance.platform,
      'model': instance.model,
      'manufacturer': instance.manufacturer,
      'os_name': instance.osName,
      'os_version': instance.osVersion,
      'locale_region': instance.localeRegion,
      'locale_language': instance.localeLanguage,
      'timezone': instance.timezone,
      'app_name': instance.appName,
      'app_version': instance.appVersion,
      'sdk_type': instance.sdkType,
      'sdk_version': instance.sdkVersion,
      'ad_id': instance.adId,
      'is_push_permission_granted': instance.isPushPermissionGranted,
      'push_token': instance.pushToken,
      'push_token_type': instance.pushTokenType,
    };
