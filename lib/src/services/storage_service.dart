import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/logging/clix_logger.dart';

class StorageService {
  SharedPreferences? _prefs;
  
  Future<SharedPreferences> get _preferences async {
    if (_prefs != null) return _prefs!;
    
    try {
      ClixLogger.debug('Initializing storage service');
      _prefs = await SharedPreferences.getInstance();
      ClixLogger.debug('Successfully configured storage service');
      return _prefs!;
    } catch (e) {
      ClixLogger.error('Failed to initialize storage service', e);
      rethrow;
    }
  }

  Future<void> set<T>(String key, T? value) async {
    try {
      final prefs = await _preferences;
      
      if (value == null) {
        await prefs.remove(key);
        return;
      }

      final encoded = jsonEncode(value);
      await prefs.setString(key, encoded);
    } catch (e) {
      ClixLogger.error('Failed to set value for key: $key', e);
      rethrow;
    }
  }

  Future<T?> get<T>(String key) async {
    try {
      final prefs = await _preferences;
      final data = prefs.getString(key);
      if (data == null) return null;
      
      try {
        final decoded = jsonDecode(data);
        return decoded as T?;
      } catch (jsonError) {
        if (T == String) {
          ClixLogger.debug('Found legacy string value for key: $key, migrating to JSON format');
          await set<T>(key, data as T);
          return data as T?;
        }
        rethrow;
      }
    } catch (e) {
      ClixLogger.error('Failed to get value for key: $key', e);
      return null;
    }
  }

  Future<void> remove(String key) async {
    try {
      final prefs = await _preferences;
      await prefs.remove(key);
    } catch (e) {
      ClixLogger.error('Failed to remove key: $key', e);
      rethrow;
    }
  }
}