// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'permission_service.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotificationSettings _$NotificationSettingsFromJson(Map json) =>
    NotificationSettings(
      enabled: json['enabled'] as bool,
      categories: (json['categories'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      lastUpdated: DateTime.parse(json['last_updated'] as String),
      status:
          $enumDecode(_$NotificationPermissionStatusEnumMap, json['status']),
    );

Map<String, dynamic> _$NotificationSettingsToJson(
        NotificationSettings instance) =>
    <String, dynamic>{
      'enabled': instance.enabled,
      'categories': instance.categories,
      'last_updated': instance.lastUpdated.toIso8601String(),
      'status': _$NotificationPermissionStatusEnumMap[instance.status]!,
    };

const _$NotificationPermissionStatusEnumMap = {
  NotificationPermissionStatus.notDetermined: 'notDetermined',
  NotificationPermissionStatus.denied: 'denied',
  NotificationPermissionStatus.authorized: 'authorized',
  NotificationPermissionStatus.provisional: 'provisional',
  NotificationPermissionStatus.permanentlyDenied: 'permanentlyDenied',
};
