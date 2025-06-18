import '../models/clix_device.dart';
import '../models/clix_user_property.dart';
import '../utils/logging/clix_logger.dart';
import 'clix_api_client.dart';

/// DeviceAPIService that mirrors the iOS SDK DeviceAPIService implementation
class DeviceAPIService {
  final ClixAPIClient _apiClient;

  DeviceAPIService({required ClixAPIClient apiClient}) : _apiClient = apiClient;

  /// Upsert device - mirrors iOS upsertDevice method
  Future<void> upsertDevice(ClixDevice device) async {
    try {
      ClixLogger.debug('Upserting device: ${device.id}');
      
      await _apiClient.post<Map<String, dynamic>>(
        '/devices',
        body: {
          'devices': [device.toJson()]
        },
      );

      ClixLogger.info('Device upserted successfully: ${device.id}');
    } catch (e) {
      ClixLogger.error('Failed to upsert device: ${device.id}', e);
      rethrow;
    }
  }

  /// Set project user ID - mirrors iOS setProjectUserId method
  Future<void> setProjectUserId({
    required String deviceId,
    required String projectUserId,
  }) async {
    try {
      ClixLogger.debug('Setting project user ID for device: $deviceId');
      
      await _apiClient.put<Map<String, dynamic>>(
        '/devices/$deviceId/project-user-id',
        body: {
          'project_user_id': projectUserId,
        },
      );

      ClixLogger.info('Project user ID set successfully for device: $deviceId');
    } catch (e) {
      ClixLogger.error('Failed to set project user ID for device: $deviceId', e);
      rethrow;
    }
  }

  /// Upsert user properties - mirrors iOS upsertUserProperties method
  Future<void> upsertUserProperties({
    required String deviceId,
    required List<ClixUserProperty> properties,
  }) async {
    try {
      ClixLogger.debug('Upserting ${properties.length} user properties for device: $deviceId');
      
      await _apiClient.post<Map<String, dynamic>>(
        '/devices/$deviceId/user/properties',
        body: {
          'properties': properties.map((p) => p.toJson()).toList(),
        },
      );

      ClixLogger.info('User properties upserted successfully for device: $deviceId');
    } catch (e) {
      ClixLogger.error('Failed to upsert user properties for device: $deviceId', e);
      rethrow;
    }
  }

  /// Remove user properties - mirrors iOS removeUserProperties method
  Future<void> removeUserProperties({
    required String deviceId,
    required List<String> propertyNames,
  }) async {
    try {
      ClixLogger.debug('Removing ${propertyNames.length} user properties for device: $deviceId');
      
      await _apiClient.delete<Map<String, dynamic>>(
        '/devices/$deviceId/user/properties',
        queryParameters: {
          'property_names': propertyNames.join(','),
        },
      );

      ClixLogger.info('User properties removed successfully for device: $deviceId');
    } catch (e) {
      ClixLogger.error('Failed to remove user properties for device: $deviceId', e);
      rethrow;
    }
  }
}