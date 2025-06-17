import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/clix_push_notification_payload.dart';
import '../utils/logger.dart';
import 'event_service.dart';
import 'device_service.dart';
import '../utils/http_client.dart';

/// Notification service for handling push notifications
class NotificationService {
  final EventService _eventService;
  final DeviceService _deviceService;
  final ClixHttpClient _httpClient;

  NotificationService({
    required EventService eventService,
    required DeviceService deviceService,
    ClixHttpClient? httpClient,
  })  : _eventService = eventService,
        _deviceService = deviceService,
        _httpClient = httpClient ?? ClixHttpClient();

  /// Handle notification received in foreground
  Future<void> handleNotificationReceived(
      ClixPushNotificationPayload payload) async {
    try {
      ClixLogger.info('Handling notification received: ${payload.messageId}');

      // Track notification received event
      await _eventService.trackNotificationReceived(
        payload.messageId,
        properties: _buildEventProperties(payload),
      );

      // Download image if available
      if (payload.imageUrl != null && payload.imageUrl!.isNotEmpty) {
        await _downloadNotificationImage(payload.imageUrl!);
      }

      ClixLogger.debug('Notification received handling completed');
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to handle notification received', e, stackTrace);
      // Don't throw - notification handling should be resilient
    }
  }

  /// Handle notification tapped
  Future<void> handleNotificationTapped(
      ClixPushNotificationPayload payload) async {
    try {
      ClixLogger.info('Handling notification tapped: ${payload.messageId}');

      // Track notification tapped event
      await _eventService.trackNotificationTapped(
        payload.messageId,
        properties: _buildEventProperties(payload),
      );

      // Handle landing URL if available
      if (payload.landingUrl != null && payload.landingUrl!.isNotEmpty) {
        ClixLogger.info('Notification has landing URL: ${payload.landingUrl}');
        // Note: URL opening would be handled by the app, not the SDK
      }

      ClixLogger.debug('Notification tapped handling completed');
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to handle notification tapped', e, stackTrace);
      // Don't throw - notification handling should be resilient
    }
  }

  /// Handle notification received in background
  Future<void> handleNotificationReceivedBackground(
      ClixPushNotificationPayload payload) async {
    try {
      ClixLogger.info('Handling background notification: ${payload.messageId}');

      // Track background notification event
      await _eventService.trackEvent(
        'notification_received_background',
        properties: _buildEventProperties(payload),
        messageId: payload.messageId,
      );

      ClixLogger.debug('Background notification handling completed');
    } catch (e, stackTrace) {
      ClixLogger.error(
          'Failed to handle background notification', e, stackTrace);
      // Don't throw - notification handling should be resilient
    }
  }

  /// Parse notification payload from different sources
  ClixPushNotificationPayload? parseNotificationPayload(
      Map<String, dynamic> data) {
    try {
      return ClixPushNotificationPayload.fromMap(data);
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to parse notification payload', e, stackTrace);
      return null;
    }
  }

  /// Check if payload is from Clix
  bool isClixNotification(Map<String, dynamic> data) {
    // Check for Clix-specific keys
    return data.containsKey('clix_message_id') ||
        data.containsKey('message_id') ||
        data.containsKey('clix_campaign_id');
  }

  /// Get notification permission status
  Future<bool> getNotificationPermissionStatus() async {
    try {
      // This would be implemented by the platform-specific code
      // For now, return cached status
      return _deviceService.isPushPermissionGranted();
    } catch (e, stackTrace) {
      ClixLogger.error(
          'Failed to get notification permission status', e, stackTrace);
      return false;
    }
  }

  /// Request notification permissions
  Future<bool> requestNotificationPermissions() async {
    try {
      ClixLogger.info('Requesting notification permissions');

      // This would typically call platform-specific code
      // For now, we'll assume permission is granted
      // In a real implementation, this would call PlatformService.requestNotificationPermissions()

      const permissionGranted = true; // Placeholder

      // Update device with permission status
      await _deviceService.updatePushPermission(permissionGranted);

      ClixLogger.info('Notification permissions result: $permissionGranted');
      return permissionGranted;
    } catch (e, stackTrace) {
      ClixLogger.error(
          'Failed to request notification permissions', e, stackTrace);
      return false;
    }
  }

  /// Check if notifications are supported on current platform
  bool get supportsNotifications {
    if (kIsWeb) return false;
    return Platform.isIOS || Platform.isAndroid;
  }

  /// Check if rich notifications (with images) are supported
  bool get supportsRichNotifications {
    if (kIsWeb) return false;
    return Platform.isIOS || Platform.isAndroid;
  }

  /// Get notification settings
  Future<Map<String, dynamic>?> getNotificationSettings() async {
    try {
      // This would call platform-specific code to get detailed settings
      // For now, return basic information
      return {
        'authorizationStatus':
            _deviceService.isPushPermissionGranted() ? 'authorized' : 'denied',
        'alertSetting': 'enabled',
        'badgeSetting': Platform.isIOS ? 'enabled' : 'disabled',
        'soundSetting': 'enabled',
        'notificationCenterSetting': 'enabled',
        'lockScreenSetting': 'enabled',
        'carPlaySetting': Platform.isIOS ? 'enabled' : 'disabled',
        'criticalAlertSetting': 'disabled',
        'providesAppNotificationSettings': false,
      };
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to get notification settings', e, stackTrace);
      return null;
    }
  }

  /// Set notification badge count (iOS only)
  Future<bool> setNotificationBadge(int count) async {
    try {
      if (!Platform.isIOS) return false;

      ClixLogger.debug('Setting notification badge to: $count');
      // This would call platform-specific code
      // For now, just log and return success
      return true;
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to set notification badge', e, stackTrace);
      return false;
    }
  }

  /// Clear notification badge (iOS only)
  Future<bool> clearNotificationBadge() async {
    return setNotificationBadge(0);
  }

  /// Subscribe to FCM topic (Android)
  Future<bool> subscribeToTopic(String topic) async {
    try {
      if (!Platform.isAndroid) return false;

      ClixLogger.info('Subscribing to topic: $topic');
      // This would call platform-specific code
      // For now, just log and return success
      return true;
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to subscribe to topic: $topic', e, stackTrace);
      return false;
    }
  }

  /// Unsubscribe from FCM topic (Android)
  Future<bool> unsubscribeFromTopic(String topic) async {
    try {
      if (!Platform.isAndroid) return false;

      ClixLogger.info('Unsubscribing from topic: $topic');
      // This would call platform-specific code
      // For now, just log and return success
      return true;
    } catch (e, stackTrace) {
      ClixLogger.error(
          'Failed to unsubscribe from topic: $topic', e, stackTrace);
      return false;
    }
  }

  /// Close the notification service
  void close() {
    _httpClient.close();
  }

  // Private helper methods

  Map<String, dynamic> _buildEventProperties(
      ClixPushNotificationPayload payload) {
    final properties = <String, dynamic>{
      'messageId': payload.messageId,
    };

    if (payload.campaignId != null) {
      properties['campaignId'] = payload.campaignId;
    }
    if (payload.userId != null) {
      properties['userId'] = payload.userId;
    }
    if (payload.deviceId != null) {
      properties['deviceId'] = payload.deviceId;
    }
    if (payload.trackingId != null) {
      properties['trackingId'] = payload.trackingId;
    }
    if (payload.landingUrl != null) {
      properties['landingUrl'] = payload.landingUrl;
    }
    if (payload.imageUrl != null) {
      properties['imageUrl'] = payload.imageUrl;
    }
    if (payload.customProperties != null) {
      properties['customProperties'] = payload.customProperties;
    }

    return properties;
  }

  Future<void> _downloadNotificationImage(String imageUrl) async {
    try {
      ClixLogger.debug('Downloading notification image: $imageUrl');

      final imageBytes = await _httpClient.downloadFile(imageUrl);

      if (imageBytes.isNotEmpty) {
        ClixLogger.debug(
            'Notification image downloaded successfully (${imageBytes.length} bytes)');
        // Image would be cached for use in notification display
        // This would be handled by platform-specific code
      }
    } catch (e, stackTrace) {
      ClixLogger.warning(
          'Failed to download notification image: $imageUrl', e, stackTrace);
      // Don't throw - image download failure shouldn't break notification handling
    }
  }
}
