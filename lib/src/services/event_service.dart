import 'package:json_annotation/json_annotation.dart';
import '../utils/logger.dart';
import '../utils/clix_error.dart';
import 'clix_api_client.dart';
import 'device_service.dart';

part 'event_service.g.dart';

/// Event model for tracking
@JsonSerializable(fieldRename: FieldRename.snake)
class ClixEvent {
  final String name;
  final Map<String, dynamic>? properties;
  final String? messageId;
  final DateTime timestamp;

  ClixEvent({
    required this.name,
    this.properties,
    this.messageId,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Convert to JSON
  Map<String, dynamic> toJson() => _$ClixEventToJson(this);

  /// Create from JSON
  factory ClixEvent.fromJson(Map<String, dynamic> json) =>
      _$ClixEventFromJson(json);
}

/// Event service for tracking user events
class EventService {
  final ClixAPIClient _apiClient;
  final DeviceService _deviceService;

  EventService({
    required ClixAPIClient apiClient,
    required DeviceService deviceService,
  })  : _apiClient = apiClient,
        _deviceService = deviceService;

  /// Track a custom event
  Future<void> trackEvent(
    String eventName, {
    Map<String, dynamic>? properties,
    String? messageId,
  }) async {
    try {
      ClixLogger.debug('Tracking event: $eventName');

      final event = ClixEvent(
        name: eventName,
        properties: properties,
        messageId: messageId,
      );

      await _sendEvent(event);

      ClixLogger.info('Event tracked successfully: $eventName');
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to track event: $eventName', e, stackTrace);
      throw ClixError.now(
        code: 'TRACK_EVENT_ERROR',
        message: 'Failed to track event: $e',
        details: e,
      );
    }
  }

  /// Track multiple events in batch
  Future<void> trackEvents(List<ClixEvent> events) async {
    try {
      ClixLogger.debug('Tracking ${events.length} events in batch');

      await _sendEvents(events);

      ClixLogger.info('${events.length} events tracked successfully');
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to track events batch', e, stackTrace);
      throw ClixError.now(
        code: 'TRACK_EVENTS_ERROR',
        message: 'Failed to track events: $e',
        details: e,
      );
    }
  }

  /// Track notification received event
  Future<void> trackNotificationReceived(
    String messageId, {
    Map<String, dynamic>? properties,
  }) async {
    final eventProperties = <String, dynamic>{
      'messageId': messageId,
      if (properties != null) ...properties,
    };

    await trackEvent(
      'notification_received',
      properties: eventProperties,
      messageId: messageId,
    );
  }

  /// Track notification tapped event
  Future<void> trackNotificationTapped(
    String messageId, {
    Map<String, dynamic>? properties,
  }) async {
    final eventProperties = <String, dynamic>{
      'messageId': messageId,
      if (properties != null) ...properties,
    };

    await trackEvent(
      'notification_tapped',
      properties: eventProperties,
      messageId: messageId,
    );
  }

  /// Track app opened event
  Future<void> trackAppOpened({
    Map<String, dynamic>? properties,
  }) async {
    await trackEvent(
      'app_opened',
      properties: properties,
    );
  }

  /// Track app backgrounded event
  Future<void> trackAppBackgrounded({
    Map<String, dynamic>? properties,
  }) async {
    await trackEvent(
      'app_backgrounded',
      properties: properties,
    );
  }

  /// Track session started event
  Future<void> trackSessionStarted({
    Map<String, dynamic>? properties,
  }) async {
    await trackEvent(
      'session_started',
      properties: properties,
    );
  }

  /// Track session ended event
  Future<void> trackSessionEnded({
    Map<String, dynamic>? properties,
  }) async {
    await trackEvent(
      'session_ended',
      properties: properties,
    );
  }

  /// Track purchase event
  Future<void> trackPurchase({
    required String productId,
    required double amount,
    required String currency,
    Map<String, dynamic>? properties,
  }) async {
    final eventProperties = <String, dynamic>{
      'productId': productId,
      'amount': amount,
      'currency': currency,
      if (properties != null) ...properties,
    };

    await trackEvent(
      'purchase',
      properties: eventProperties,
    );
  }

  /// Track screen view event
  Future<void> trackScreenView(
    String screenName, {
    Map<String, dynamic>? properties,
  }) async {
    final eventProperties = <String, dynamic>{
      'screenName': screenName,
      if (properties != null) ...properties,
    };

    await trackEvent(
      'screen_view',
      properties: eventProperties,
    );
  }

  // Private helper methods

  Future<void> _sendEvent(ClixEvent event) async {
    final deviceId = _deviceService.getDeviceId();
    if (deviceId == null) {
      throw ClixError.now(
        code: 'NO_DEVICE_ID',
        message: 'Device ID not available for event tracking',
      );
    }

    final eventData = {
      'deviceId': deviceId,
      'userId': _deviceService.getUserId(),
      'event': event.toJson(),
    };

    await _apiClient.post<Map<String, dynamic>>(
      '/events',
      body: eventData,
    );
  }

  Future<void> _sendEvents(List<ClixEvent> events) async {
    final deviceId = _deviceService.getDeviceId();
    if (deviceId == null) {
      throw ClixError.now(
        code: 'NO_DEVICE_ID',
        message: 'Device ID not available for event tracking',
      );
    }

    final eventData = {
      'deviceId': deviceId,
      'userId': _deviceService.getUserId(),
      'events': events.map((e) => e.toJson()).toList(),
    };

    await _apiClient.post<Map<String, dynamic>>(
      '/events/batch',
      body: eventData,
    );
  }
}
