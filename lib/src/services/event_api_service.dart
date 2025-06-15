import 'dart:async';
import 'clix_api_client.dart';
import '../models/clix_event.dart';
import '../utils/logger.dart';

class EventAPIService {
  final ClixAPIClient _apiClient;

  EventAPIService({
    required ClixAPIClient apiClient,
  }) : _apiClient = apiClient;

  Future<void> trackEvent(ClixEvent event) async {
    try {
      await _apiClient.post('/events', body: event.toJson());
      ClixLogger.info('Event tracked: ${event.name}');
      ClixLogger.verbose('Event properties: ${event.toJson()}');
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to track event: ${event.name}', e, stackTrace);
      rethrow;
    }
  }

  Future<void> trackPushNotificationReceived({
    required String deviceId,
    String? userId,
    String? campaignId,
    String? messageId,
    String? trackingId,
    Map<String, dynamic>? customProperties,
  }) async {
    final event = ClixEvent(
      name: 'push_notification_received',
      deviceId: deviceId,
      userId: userId,
      properties: {
        if (campaignId != null) 'campaign_id': campaignId,
        if (trackingId != null) 'tracking_id': trackingId,
        ...?customProperties,
      },
      messageId: messageId,
    );

    await trackEvent(event);
  }

  Future<void> trackPushNotificationTapped({
    required String deviceId,
    String? userId,
    String? campaignId,
    String? messageId,
    String? trackingId,
    String? landingUrl,
    Map<String, dynamic>? customProperties,
  }) async {
    final event = ClixEvent(
      name: 'push_notification_tapped',
      deviceId: deviceId,
      userId: userId,
      properties: {
        if (campaignId != null) 'campaign_id': campaignId,
        if (trackingId != null) 'tracking_id': trackingId,
        if (landingUrl != null) 'landing_url': landingUrl,
        ...?customProperties,
      },
      messageId: messageId,
    );

    await trackEvent(event);
  }
}
