// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_service.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ClixEvent _$ClixEventFromJson(Map json) => ClixEvent(
      name: json['name'] as String,
      properties: (json['properties'] as Map?)?.map(
        (k, e) => MapEntry(k as String, e),
      ),
      messageId: json['message_id'] as String?,
      timestamp: json['timestamp'] == null
          ? null
          : DateTime.parse(json['timestamp'] as String),
    );

Map<String, dynamic> _$ClixEventToJson(ClixEvent instance) => <String, dynamic>{
      'name': instance.name,
      'properties': instance.properties,
      'message_id': instance.messageId,
      'timestamp': instance.timestamp.toIso8601String(),
    };
