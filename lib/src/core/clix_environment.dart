import 'dart:io';
import 'package:flutter/foundation.dart';
import 'clix_version.dart';

class ClixEnvironment {
  final String appIdentifier;
  final String appName;
  final String appVersion;
  final String? adId;

  ClixEnvironment({
    required this.appIdentifier,
    required this.appName,
    required this.appVersion,
    this.adId,
  });

  /// Create environment with current app information
  /// In a real app, this would be configured with actual app details
  factory ClixEnvironment.current() {
    return ClixEnvironment(
      appIdentifier: 'com.clix.flutter.sdk',
      appName: 'Clix Flutter SDK',
      appVersion: '1.0.0',
    );
  }

  String get platform {
    if (kIsWeb) return 'Web';
    if (Platform.isIOS) return 'iOS';
    if (Platform.isAndroid) return 'Android';
    return Platform.operatingSystem;
  }

  String get sdkType => 'Flutter';
  String get sdkVersion => ClixVersion.version;
}