import '../utils/logging/clix_logger.dart';
import 'clix_api_client.dart';

class EventAPIService {
  final ClixAPIClient _apiClient;

  EventAPIService({required ClixAPIClient apiClient}) : _apiClient = apiClient;

  Future<void> trackEvent({
    required String deviceId,
    required String name,
    required Map<String, dynamic> properties,
    String? messageId,
  }) async {
    try {
      ClixLogger.debug('Tracking event: $name for device: $deviceId');
      
      final eventRequestBody = {
        'device_id': deviceId,
        'name': name,
        'event_property': {
          'custom_properties': properties,
          if (messageId != null) 'message_id': messageId,
        },
      };

      final response = await _apiClient.post(
        '/events',
        body: {
          'events': [eventRequestBody]
        },
      );
      
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }

      ClixLogger.info('Event tracked successfully: $name for device: $deviceId');
    } catch (e) {
      ClixLogger.error('Failed to track event: $name for device: $deviceId', e);
      rethrow;
    }
  }
}