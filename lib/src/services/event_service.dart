import '../utils/clix_error.dart';
import '../utils/logging/clix_logger.dart';
import 'event_api_service.dart';
import 'device_service.dart';

/// EventService that mirrors the iOS SDK EventService implementation
class EventService {
  final EventAPIService _eventAPIService;
  final DeviceService _deviceService;

  EventService({
    required EventAPIService eventAPIService,
    required DeviceService deviceService,
  }) : _eventAPIService = eventAPIService,
       _deviceService = deviceService;

  /// Track a custom event - mirrors iOS trackEvent method
  Future<void> trackEvent(
    String name, {
    Map<String, dynamic>? properties,
    String? messageId,
  }) async {
    try {
      ClixLogger.debug('Tracking event: $name');
      
      final deviceId = _deviceService.getDeviceId();
      if (deviceId == null) {
        throw ClixError.unknownErrorWithReason('Device ID not available for event tracking');
      }

      // Clean properties to match iOS behavior - remove null values
      final cleanProperties = <String, dynamic>{};
      if (properties != null) {
        for (final entry in properties.entries) {
          if (entry.value != null) {
            cleanProperties[entry.key] = entry.value;
          }
        }
      }

      await _eventAPIService.trackEvent(
        deviceId: deviceId,
        name: name,
        properties: cleanProperties,
        messageId: messageId,
      );

      ClixLogger.info('Event tracked successfully: $name');
    } catch (e) {
      ClixLogger.error("Failed to track event '$name': $e. Make sure Clix.initialize() has been called.");
      rethrow;
    }
  }
}