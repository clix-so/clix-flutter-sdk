import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/logger.dart';

class StorageService {
  static const String _prefix = 'clix_';

  SharedPreferences? _prefs;
  bool get isInitialized => _prefs != null;

  Future<void> initialize() async {
    if (_prefs != null) return; // Already initialized

    try {
      _prefs = await SharedPreferences.getInstance();
      ClixLogger.debug('StorageService initialized');
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to initialize StorageService', e, stackTrace);
      rethrow;
    }
  }

  void _ensureInitialized() {
    if (_prefs == null) {
      throw StateError(
          'StorageService not initialized. Call initialize() first.');
    }
  }

  Future<void> setString(String key, String value) async {
    _ensureInitialized();
    try {
      await _prefs!.setString(_prefix + key, value);
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to set string for key: $key', e, stackTrace);
      rethrow;
    }
  }

  String? getString(String key) {
    _ensureInitialized();
    try {
      return _prefs!.getString(_prefix + key);
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to get string for key: $key', e, stackTrace);
      return null;
    }
  }

  Future<void> setBool(String key, bool value) async {
    _ensureInitialized();
    try {
      await _prefs!.setBool(_prefix + key, value);
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to set bool for key: $key', e, stackTrace);
      rethrow;
    }
  }

  bool? getBool(String key) {
    _ensureInitialized();
    try {
      return _prefs!.getBool(_prefix + key);
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to get bool for key: $key', e, stackTrace);
      return null;
    }
  }

  Future<void> setInt(String key, int value) async {
    _ensureInitialized();
    try {
      await _prefs!.setInt(_prefix + key, value);
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to set int for key: $key', e, stackTrace);
      rethrow;
    }
  }

  int? getInt(String key) {
    _ensureInitialized();
    try {
      return _prefs!.getInt(_prefix + key);
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to get int for key: $key', e, stackTrace);
      return null;
    }
  }

  Future<void> setJson(String key, Map<String, dynamic> value) async {
    try {
      final jsonString = jsonEncode(value);
      await setString(key, jsonString);
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to set JSON for key: $key', e, stackTrace);
      rethrow;
    }
  }

  Map<String, dynamic>? getJson(String key) {
    try {
      final jsonString = getString(key);
      if (jsonString == null) return null;
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to get JSON for key: $key', e, stackTrace);
      return null;
    }
  }

  Future<void> remove(String key) async {
    _ensureInitialized();
    try {
      await _prefs!.remove(_prefix + key);
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to remove key: $key', e, stackTrace);
      rethrow;
    }
  }

  Future<void> clear() async {
    _ensureInitialized();
    try {
      final keys = _prefs!.getKeys().where((key) => key.startsWith(_prefix));
      for (final key in keys) {
        await _prefs!.remove(key);
      }
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to clear storage', e, stackTrace);
      rethrow;
    }
  }

  // MARK: - Static methods for SDK configuration

  static SharedPreferences? _staticPrefs;

  static Future<void> _ensureStaticInit() async {
    _staticPrefs ??= await SharedPreferences.getInstance();
  }

  // Project configuration
  static Future<void> setProjectId(String projectId) async {
    await _ensureStaticInit();
    await _staticPrefs!.setString('${_prefix}project_id', projectId);
  }

  static Future<String?> getProjectId() async {
    await _ensureStaticInit();
    return _staticPrefs!.getString('${_prefix}project_id');
  }

  static Future<void> setApiKey(String apiKey) async {
    await _ensureStaticInit();
    await _staticPrefs!.setString('${_prefix}api_key', apiKey);
  }

  static Future<String?> getApiKey() async {
    await _ensureStaticInit();
    return _staticPrefs!.getString('${_prefix}api_key');
  }

  // User configuration
  static Future<void> setUserId(String userId) async {
    await _ensureStaticInit();
    await _staticPrefs!.setString('${_prefix}user_id', userId);
  }

  static Future<String?> getUserId() async {
    await _ensureStaticInit();
    return _staticPrefs!.getString('${_prefix}user_id');
  }

  static Future<void> removeUserId() async {
    await _ensureStaticInit();
    await _staticPrefs!.remove('${_prefix}user_id');
  }

  // User properties
  static Future<void> setUserProperty(String key, dynamic value) async {
    await _ensureStaticInit();
    final propKey = '${_prefix}user_property_$key';

    if (value == null) {
      await _staticPrefs!.remove(propKey);
    } else if (value is String) {
      await _staticPrefs!.setString(propKey, value);
    } else if (value is bool) {
      await _staticPrefs!.setBool(propKey, value);
    } else if (value is int) {
      await _staticPrefs!.setInt(propKey, value);
    } else if (value is double) {
      await _staticPrefs!.setDouble(propKey, value);
    } else if (value is List<String>) {
      await _staticPrefs!.setStringList(propKey, value);
    } else {
      // For complex types, store as JSON
      await _staticPrefs!.setString(propKey, jsonEncode(value));
    }
  }

  static Future<dynamic> getUserProperty(String key) async {
    await _ensureStaticInit();
    final propKey = '${_prefix}user_property_$key';
    return _staticPrefs!.get(propKey);
  }

  static Future<void> setUserProperties(Map<String, dynamic> properties) async {
    for (final entry in properties.entries) {
      await setUserProperty(entry.key, entry.value);
    }
  }

  static Future<Map<String, dynamic>> getUserProperties() async {
    await _ensureStaticInit();
    final properties = <String, dynamic>{};
    const prefix = '${_prefix}user_property_';

    for (final key in _staticPrefs!.getKeys()) {
      if (key.startsWith(prefix)) {
        final propKey = key.substring(prefix.length);
        properties[propKey] = _staticPrefs!.get(key);
      }
    }

    return properties;
  }

  static Future<void> removeUserProperty(String key) async {
    await _ensureStaticInit();
    final propKey = '${_prefix}user_property_$key';
    await _staticPrefs!.remove(propKey);
  }

  static Future<void> removeUserProperties(List<String> keys) async {
    for (final key in keys) {
      await removeUserProperty(key);
    }
  }

  // Log level
  static Future<void> setLogLevel(int level) async {
    await _ensureStaticInit();
    await _staticPrefs!.setInt('${_prefix}log_level', level);
  }

  static Future<int?> getLogLevel() async {
    await _ensureStaticInit();
    return _staticPrefs!.getInt('${_prefix}log_level');
  }

  // Push token
  static Future<void> setPushToken(String token) async {
    await _ensureStaticInit();
    await _staticPrefs!.setString('${_prefix}push_token', token);
  }

  static Future<String?> getPushToken() async {
    await _ensureStaticInit();
    return _staticPrefs!.getString('${_prefix}push_token');
  }

  static Future<void> removePushToken() async {
    await _ensureStaticInit();
    await _staticPrefs!.remove('${_prefix}push_token');
  }

  // Web device ID
  static Future<void> setWebDeviceId(String deviceId) async {
    await _ensureStaticInit();
    await _staticPrefs!.setString('${_prefix}web_device_id', deviceId);
  }

  static Future<String?> getWebDeviceId() async {
    await _ensureStaticInit();
    return _staticPrefs!.getString('${_prefix}web_device_id');
  }

  static Future<void> removeWebDeviceId() async {
    await _ensureStaticInit();
    await _staticPrefs!.remove('${_prefix}web_device_id');
  }
}
