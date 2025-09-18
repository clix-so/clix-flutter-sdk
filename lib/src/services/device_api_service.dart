import '../models/clix_device.dart';
import '../models/clix_user_property.dart';
import '../utils/logging/clix_logger.dart';
import 'clix_api_client.dart';

class DeviceAPIService {
  final ClixAPIClient _apiClient;

  DeviceAPIService({required ClixAPIClient apiClient}) : _apiClient = apiClient;

  Future<void> registerDevice({required ClixDevice device}) async {
    try {
      ClixLogger.debug('Upserting device: ${device.id}');

      final response = await _apiClient.post(
        '/devices',
        body: {
          'devices': [device.toJson()]
        },
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }

      ClixLogger.info('Device upserted successfully: ${device.id}');
    } catch (e) {
      ClixLogger.error('Failed to upsert device: ${device.id}', e);
      rethrow;
    }
  }

  Future<void> setProjectUserId({
    required String deviceId,
    required String projectUserId,
  }) async {
    try {
      ClixLogger.debug('Setting project user ID for device: $deviceId');

      final response = await _apiClient.post(
        '/devices/$deviceId/user/project-user-id',
        body: {
          'project_user_id': projectUserId,
        },
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }

      ClixLogger.info('Project user ID set successfully for device: $deviceId');
    } catch (e) {
      ClixLogger.error(
          'Failed to set project user ID for device: $deviceId', e);
      rethrow;
    }
  }

  Future<void> removeProjectUserId({required String deviceId}) async {
    try {
      ClixLogger.debug('Removing project user ID for device: $deviceId');

      final response = await _apiClient.delete(
        '/devices/$deviceId/user/project-user-id',
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }

      ClixLogger.info(
          'Project user ID removed successfully for device: $deviceId');
    } catch (e) {
      ClixLogger.error(
          'Failed to remove project user ID for device: $deviceId', e);
      rethrow;
    }
  }

  Future<void> upsertUserProperties({
    required String deviceId,
    required List<ClixUserProperty> properties,
  }) async {
    try {
      ClixLogger.debug(
          'Upserting ${properties.length} user properties for device: $deviceId');

      final response = await _apiClient.post(
        '/devices/$deviceId/user/properties',
        body: {
          'properties': properties.map((p) => p.toJson()).toList(),
        },
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }

      ClixLogger.info(
          'User properties upserted successfully for device: $deviceId');
    } catch (e) {
      ClixLogger.error(
          'Failed to upsert user properties for device: $deviceId', e);
      rethrow;
    }
  }

  Future<void> removeUserProperties({
    required String deviceId,
    required List<String> propertyNames,
  }) async {
    try {
      ClixLogger.debug(
          'Removing ${propertyNames.length} user properties for device: $deviceId');

      final response = await _apiClient.delete(
        '/devices/$deviceId/user/properties',
        queryParameters: {
          'property_names': propertyNames.join(','),
        },
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }

      ClixLogger.info(
          'User properties removed successfully for device: $deviceId');
    } catch (e) {
      ClixLogger.error(
          'Failed to remove user properties for device: $deviceId', e);
      rethrow;
    }
  }
}
