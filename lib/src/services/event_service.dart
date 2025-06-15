import 'dart:async';
import 'event_api_service.dart';
import 'device_service.dart';
import '../models/clix_event.dart';
import '../utils/logger.dart';

class EventService {
  final EventAPIService _eventAPIService;
  final DeviceService _deviceService;
  String? _currentMessageId;

  EventService({
    required EventAPIService eventAPIService,
    required DeviceService deviceService,
  })  : _eventAPIService = eventAPIService,
        _deviceService = deviceService;

  Future<void> initialize() async {
    ClixLogger.debug('EventService initialized');
  }

  void setMessageId(String? messageId) {
    _currentMessageId = messageId;
    ClixLogger.debug('Current message ID set: $messageId');
  }

  void clearMessageId() {
    _currentMessageId = null;
    ClixLogger.debug('Current message ID cleared');
  }

  Future<void> trackEvent(
    String name, {
    Map<String, dynamic>? properties,
    String? messageId,
  }) async {
    try {
      final deviceId = _deviceService.deviceId;
      if (deviceId == null) {
        ClixLogger.warning('Cannot track event without device ID');
        return;
      }

      final event = ClixEvent(
        name: name,
        deviceId: deviceId,
        userId: _deviceService.userId,
        properties: properties,
        messageId: messageId ?? _currentMessageId,
      );

      await _eventAPIService.trackEvent(event);

      ClixLogger.info('Event tracked: $name');
      ClixLogger.verbose('Event properties: ${event.toJson()}');
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to track event: $name', e, stackTrace);
    }
  }

  Future<void> trackPushNotificationReceived({
    String? campaignId,
    String? messageId,
    String? trackingId,
    Map<String, dynamic>? customProperties,
  }) async {
    final deviceId = _deviceService.deviceId;
    if (deviceId == null) {
      ClixLogger.warning('Cannot track notification event without device ID');
      return;
    }

    await _eventAPIService.trackPushNotificationReceived(
      deviceId: deviceId,
      userId: _deviceService.userId,
      campaignId: campaignId,
      messageId: messageId,
      trackingId: trackingId,
      customProperties: customProperties,
    );
  }

  Future<void> trackPushNotificationTapped({
    String? campaignId,
    String? messageId,
    String? trackingId,
    String? landingUrl,
    Map<String, dynamic>? customProperties,
  }) async {
    final deviceId = _deviceService.deviceId;
    if (deviceId == null) {
      ClixLogger.warning('Cannot track notification event without device ID');
      return;
    }

    await _eventAPIService.trackPushNotificationTapped(
      deviceId: deviceId,
      userId: _deviceService.userId,
      campaignId: campaignId,
      messageId: messageId,
      trackingId: trackingId,
      landingUrl: landingUrl,
      customProperties: customProperties,
    );
  }
}
