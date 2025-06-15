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
      throw StateError('StorageService not initialized. Call initialize() first.');
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
}