// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clix_user_property.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ClixUserProperty _$ClixUserPropertyFromJson(Map json) => ClixUserProperty(
      name: json['name'] as String,
      value: json['value_string'],
      type: $enumDecode(_$PropertyTypeEnumMap, json['type']),
    );

Map<String, dynamic> _$ClixUserPropertyToJson(ClixUserProperty instance) =>
    <String, dynamic>{
      'name': instance.name,
      'value_string': instance.value,
      'type': _$PropertyTypeEnumMap[instance.type]!,
    };

const _$PropertyTypeEnumMap = {
  PropertyType.string: 'USER_PROPERTY_TYPE_STRING',
  PropertyType.number: 'USER_PROPERTY_TYPE_NUMBER',
  PropertyType.boolean: 'USER_PROPERTY_TYPE_BOOLEAN',
};
