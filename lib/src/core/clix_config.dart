import 'package:json_annotation/json_annotation.dart';
import '../utils/logging/clix_log_level.dart';

part 'clix_config.g.dart';

@JsonSerializable()
class ClixConfig {
  final String projectId;
  final String apiKey;
  final String endpoint;
  final ClixLogLevel logLevel;
  final Map<String, String>? extraHeaders;
  final int sessionTimeoutMs;

  const ClixConfig({
    required this.projectId,
    required this.apiKey,
    this.endpoint = 'https://api.clix.so',
    this.logLevel = ClixLogLevel.error,
    this.extraHeaders,
    this.sessionTimeoutMs = 30000,
  });

  Map<String, dynamic> toJson() => _$ClixConfigToJson(this);

  factory ClixConfig.fromJson(Map<String, dynamic> json) =>
      _$ClixConfigFromJson(json);
}
