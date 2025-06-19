import 'package:package_info_plus/package_info_plus.dart';

class ClixVersion {
  static String? _cachedVersion;

  static Future<String> get version async {
    if (_cachedVersion != null) {
      return _cachedVersion!;
    }

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      _cachedVersion = packageInfo.version;
      return _cachedVersion!;
    } catch (e) {
      return '0.0.0';
    }
  }
}
