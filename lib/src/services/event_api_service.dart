import '../utils/logging/clix_logger.dart';
import 'clix_api_client.dart';

/// EventAPIService that mirrors the iOS SDK EventAPIService implementation
class EventAPIService {
  final ClixAPIClient _apiClient;

  EventAPIService({required ClixAPIClient apiClient}) : _apiClient = apiClient;

  /// Track event - mirrors iOS trackEvent method
  Future<void> trackEvent({
    required String deviceId,
    required String name,
    required Map<String, dynamic> properties,
    String? messageId,
  }) async {
    try {
      ClixLogger.debug('Tracking event: $name for device: $deviceId');
      
      // Match iOS EventRequestBody structure exactly
      final eventRequestBody = {
        'device_id': deviceId,
        'name': name,
        'event_property': {
          'custom_properties': properties,
          if (messageId != null) 'message_id': messageId,
        },
      };

      await _apiClient.post<Map<String, dynamic>>(
        '/events',
        body: {
          'events': [eventRequestBody]
        },
      );

      ClixLogger.info('Event tracked successfully: $name for device: $deviceId');
    } catch (e) {
      ClixLogger.error('Failed to track event: $name for device: $deviceId', e);
      rethrow;
    }
  }
}