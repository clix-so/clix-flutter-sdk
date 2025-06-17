import '../utils/clix_log_level.dart';

class ClixConfig {
  final String projectId;
  final String apiKey;
  final String endpoint;
  final ClixLogLevel logLevel;
  final Map<String, String>? extraHeaders;

  const ClixConfig({
    required this.projectId,
    required this.apiKey,
    this.endpoint = 'https://api.clix.so',
    this.logLevel = ClixLogLevel.error,
    this.extraHeaders,
  });

  Map<String, dynamic> toJson() => {
        'projectId': projectId,
        'apiKey': apiKey,
        'endpoint': endpoint,
        'logLevel': logLevel.toString(),
        'extraHeaders': extraHeaders,
      };
}
