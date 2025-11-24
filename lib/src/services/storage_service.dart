import 'dart:convert';
import 'dart:io';
import 'package:mmkv/mmkv.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../utils/logging/clix_logger.dart';

class StorageService {
  late final MMKV _mmkv;
  bool _initialized = false;

  Future<void> initialize(String projectId) async {
    if (_initialized) return;

    try {
      String? groupDir;
      if (Platform.isIOS) {
        final packageInfo = await PackageInfo.fromPlatform();
        groupDir = 'group.clix.${packageInfo.packageName}';
      }

      await MMKV.initialize(groupDir: groupDir, logLevel: MMKVLogLevel.Info);
      _mmkv = MMKV('clix.$projectId');
      _initialized = true;
    } catch (e) {
      ClixLogger.error('Failed to initialize storage service', e);
      rethrow;
    }
  }

  void _ensureInitialized() {
    if (!_initialized) {
      throw StateError('StorageService must be initialized before use');
    }
  }

  Future<void> set<T>(String key, T? value) async {
    _ensureInitialized();
    if (value == null) {
      _mmkv.removeValue(key);
      return;
    }
    _mmkv.encodeString(key, jsonEncode(value));
  }

  Future<T?> get<T>(String key) async {
    try {
      _ensureInitialized();
      final data = _mmkv.decodeString(key);
      if (data == null) return null;
      return jsonDecode(data) as T?;
    } catch (e) {
      ClixLogger.error('Failed to get value for key: $key', e);
      return null;
    }
  }

  Future<void> remove(String key) async {
    _ensureInitialized();
    _mmkv.removeValue(key);
  }
}
