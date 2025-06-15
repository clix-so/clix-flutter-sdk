import 'dart:async';
import 'event_service.dart';
import '../models/clix_push_notification_payload.dart';
import '../utils/logger.dart';

typedef NotificationHandler = void Function(ClixPushNotificationPayload payload);

class NotificationService {
  final EventService _eventService;

  final StreamController<ClixPushNotificationPayload> _receivedController = 
      StreamController<ClixPushNotificationPayload>.broadcast();
  final StreamController<ClixPushNotificationPayload> _tappedController = 
      StreamController<ClixPushNotificationPayload>.broadcast();

  NotificationHandler? _receivedHandler;
  NotificationHandler? _tappedHandler;

  NotificationService({
    required EventService eventService,
  })  : _eventService = eventService;

  // Stream-based API (more Dart-idiomatic)
  Stream<ClixPushNotificationPayload> get onNotificationReceived => 
      _receivedController.stream;

  Stream<ClixPushNotificationPayload> get onNotificationTapped => 
      _tappedController.stream;

  // Handler-based API (for backward compatibility)
  void setReceivedHandler(NotificationHandler? handler) {
    _receivedHandler = handler;
  }

  void setTappedHandler(NotificationHandler? handler) {
    _tappedHandler = handler;
  }

  void dispose() {
    _receivedController.close();
    _tappedController.close();
  }

  Future<void> handleNotificationReceived(ClixPushNotificationPayload payload) async {
    try {
      ClixLogger.info('Handling notification received: ${payload.messageId}');

      await _eventService.trackPushNotificationReceived(
        campaignId: payload.campaignId,
        messageId: payload.messageId,
        trackingId: payload.trackingId,
        customProperties: payload.customProperties,
      );

      // Emit to stream
      _receivedController.add(payload);

      // Call handler for backward compatibility
      _receivedHandler?.call(payload);

      if (payload.imageUrl != null) {
        await _downloadNotificationImage(payload.imageUrl!);
      }
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to handle notification received', e, stackTrace);
    }
  }

  Future<void> handleNotificationTapped(ClixPushNotificationPayload payload) async {
    try {
      ClixLogger.info('Handling notification tapped: ${payload.messageId}');

      await _eventService.trackPushNotificationTapped(
        campaignId: payload.campaignId,
        messageId: payload.messageId,
        trackingId: payload.trackingId,
        landingUrl: payload.landingUrl,
        customProperties: payload.customProperties,
      );

      // Emit to stream
      _tappedController.add(payload);

      // Call handler for backward compatibility
      _tappedHandler?.call(payload);

      if (payload.landingUrl != null) {
        await _openUrl(payload.landingUrl!);
      }
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to handle notification tapped', e, stackTrace);
    }
  }

  Future<void> _downloadNotificationImage(String imageUrl) async {
    try {
      ClixLogger.debug('Downloading notification image: $imageUrl');
      // Note: In a real implementation, this would download and cache the image
      // For now, we just log it
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to download notification image', e, stackTrace);
    }
  }

  Future<void> _openUrl(String url) async {
    try {
      ClixLogger.debug('Opening URL: $url');
      // Note: In a real implementation, this would open the URL using url_launcher
      // For now, we just log it
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to open URL', e, stackTrace);
    }
  }
}
