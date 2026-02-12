// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clix_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ClixConfig _$ClixConfigFromJson(Map json) => ClixConfig(
      projectId: json['project_id'] as String,
      apiKey: json['api_key'] as String,
      endpoint: json['endpoint'] as String? ?? 'https://api.clix.so',
      logLevel: $enumDecodeNullable(_$ClixLogLevelEnumMap, json['log_level']) ??
          ClixLogLevel.error,
      extraHeaders: (json['extra_headers'] as Map?)?.map(
        (k, e) => MapEntry(k as String, e as String),
      ),
      sessionTimeoutMs: (json['session_timeout_ms'] as num?)?.toInt() ?? 30000,
    );

Map<String, dynamic> _$ClixConfigToJson(ClixConfig instance) =>
    <String, dynamic>{
      'project_id': instance.projectId,
      'api_key': instance.apiKey,
      'endpoint': instance.endpoint,
      'log_level': _$ClixLogLevelEnumMap[instance.logLevel]!,
      'extra_headers': instance.extraHeaders,
      'session_timeout_ms': instance.sessionTimeoutMs,
    };

const _$ClixLogLevelEnumMap = {
  ClixLogLevel.none: 'none',
  ClixLogLevel.error: 'error',
  ClixLogLevel.warn: 'warn',
  ClixLogLevel.info: 'info',
  ClixLogLevel.debug: 'debug',
};
