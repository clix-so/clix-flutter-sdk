import 'dart:convert';
import 'package:mmkv/mmkv.dart';
import '../utils/logging/clix_logger.dart';

class StorageService {
  late final MMKV _mmkv;
  bool _initialized = false;

  Future<void> initialize(String projectId) async {
    if (_initialized) return;

    try {
      ClixLogger.debug('Initializing storage service');
      final rootDir = await MMKV.initialize();
      ClixLogger.debug('MMKV root directory: $rootDir');
      _mmkv = MMKV('clix.$projectId');
      _initialized = true;
      ClixLogger.debug('Successfully configured storage service with ID: clix.$projectId');
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
    try {
      _ensureInitialized();

      if (value == null) {
        _mmkv.removeValue(key);
        return;
      }

      final encoded = jsonEncode(value);
      _mmkv.encodeString(key, encoded);
    } catch (e) {
      ClixLogger.error('Failed to set value for key: $key', e);
      rethrow;
    }
  }

  Future<T?> get<T>(String key) async {
    try {
      _ensureInitialized();
      final data = _mmkv.decodeString(key);
      if (data == null) return null;

      final decoded = jsonDecode(data);
      return decoded as T?;
    } catch (e) {
      ClixLogger.error('Failed to get value for key: $key', e);
      return null;
    }
  }

  Future<void> remove(String key) async {
    try {
      _ensureInitialized();
      _mmkv.removeValue(key);
    } catch (e) {
      ClixLogger.error('Failed to remove key: $key', e);
      rethrow;
    }
  }
}
