import 'dart:convert';

import 'package:clix_flutter/clix_flutter.dart';
import 'package:flutter/services.dart';

class ClixConfiguration {
  static const ClixLogLevel logLevel = ClixLogLevel.debug;

  static ClixConfig? _config;

  static ClixConfig get config {
    if (_config == null) {
      throw StateError(
        'ClixConfiguration not initialized. Call initialize() first.',
      );
    }
    return _config!;
  }

  static Future<void> initialize({
    String path = 'assets/clix_config.json',
  }) async {
    if (_config != null) return; // Already initialized

    final jsonString = await rootBundle.loadString(path);
    final jsonMap = json.decode(jsonString) as Map<String, dynamic>;

    _config = ClixConfig(
      projectId: jsonMap['projectId'] as String,
      apiKey: jsonMap['apiKey'] as String,
      endpoint: jsonMap['endpoint'] as String,
      logLevel: logLevel,
      extraHeaders: Map<String, String>.from(
        jsonMap['extraHeaders'] as Map? ?? {},
      ),
    );
  }
}
