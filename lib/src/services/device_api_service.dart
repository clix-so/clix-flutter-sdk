import 'dart:async';
import 'clix_api_client.dart';
import '../models/clix_device.dart';
import '../models/clix_user_property.dart';
import '../utils/logger.dart';

class DeviceAPIService {
  final ClixAPIClient _apiClient;

  DeviceAPIService({
    required ClixAPIClient apiClient,
  }) : _apiClient = apiClient;

  Future<void> syncDevice(ClixDevice device) async {
    try {
      await _apiClient.post('/devices', body: device.toJson());
      ClixLogger.debug('Device synced successfully');
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to sync device', e, stackTrace);
      rethrow;
    }
  }

  Future<void> updatePushToken({
    required String deviceId,
    required String token,
    required String tokenType,
  }) async {
    try {
      await _apiClient.put(
        '/devices/$deviceId/push-token',
        body: {
          'token': token,
          'type': tokenType,
        },
      );
      ClixLogger.debug('Push token updated successfully');
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to update push token', e, stackTrace);
      rethrow;
    }
  }

  Future<void> setUserId({
    required String deviceId,
    required String userId,
  }) async {
    try {
      await _apiClient.post(
        '/devices/$deviceId/user/project-user-id',
        body: {'project_user_id': userId},
      );
      ClixLogger.info('User ID set: $userId');
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to set user ID', e, stackTrace);
      rethrow;
    }
  }

  Future<void> removeUserId({
    required String deviceId,
  }) async {
    try {
      await _apiClient.delete('/devices/$deviceId/user/project-user-id');
      ClixLogger.info('User ID removed');
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to remove user ID', e, stackTrace);
      rethrow;
    }
  }

  Future<void> setUserProperty({
    required String deviceId,
    required String name,
    required dynamic value,
  }) async {
    try {
      final property = ClixUserProperty(name: name, valueString: value);
      await _apiClient.post(
        '/devices/$deviceId/user/properties',
        body: {
          'properties': [property.toJson()],
        },
      );
      ClixLogger.debug('User property set: $name = $value');
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to set user property', e, stackTrace);
      rethrow;
    }
  }

  Future<void> setUserProperties({
    required String deviceId,
    required Map<String, dynamic> properties,
  }) async {
    try {
      final props = properties.entries
          .map((e) => ClixUserProperty(name: e.key, valueString: e.value))
          .map((p) => p.toJson())
          .toList();

      await _apiClient.post(
        '/devices/$deviceId/user/properties',
        body: {
          'properties': props,
        },
      );
      ClixLogger.debug('User properties set: ${properties.keys.join(', ')}');
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to set user properties', e, stackTrace);
      rethrow;
    }
  }

  Future<void> removeUserProperty({
    required String deviceId,
    required String name,
  }) async {
    try {
      await _apiClient.delete(
        '/devices/$deviceId/user/properties',
        queryParams: {'names[]': name},
      );
      ClixLogger.debug('User property removed: $name');
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to remove user property', e, stackTrace);
      rethrow;
    }
  }

  Future<void> removeUserProperties({
    required String deviceId,
    required List<String> names,
  }) async {
    try {
      final queryParams = <String, String>{};
      for (int i = 0; i < names.length; i++) {
        queryParams['names[$i]'] = names[i];
      }

      await _apiClient.delete(
        '/devices/$deviceId/user/properties',
        queryParams: queryParams,
      );
      ClixLogger.debug('User properties removed: ${names.join(', ')}');
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to remove user properties', e, stackTrace);
      rethrow;
    }
  }
}
