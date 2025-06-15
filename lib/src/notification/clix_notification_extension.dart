import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/clix_push_notification_payload.dart';
import '../utils/logger.dart';

/// Flutter equivalent of iOS NotificationServiceExtension
/// Handles rich media notifications and tracking
class ClixNotificationExtension {
  static ClixNotificationExtension? _instance;
  
  static ClixNotificationExtension get instance {
    return _instance ??= ClixNotificationExtension._();
  }
  
  ClixNotificationExtension._();

  /// Process notification content for rich media attachments
  /// This is automatically called by Firebase Messaging when a notification is received
  static Future<RemoteMessage> processNotification(RemoteMessage message) async {
    try {
      ClixLogger.debug('Processing notification: ${message.messageId}');
      
      final payload = ClixPushNotificationPayload.fromRemoteMessage(message);
      
      // Download and attach image if present
      if (payload.imageUrl != null && payload.imageUrl!.isNotEmpty) {
        await _downloadAndAttachImage(message, payload.imageUrl!);
      }
      
      // Track notification received event
      await _trackNotificationReceived(payload);
      
      ClixLogger.debug('Notification processed successfully');
      return message;
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to process notification', e, stackTrace);
      return message; // Return original message on error
    }
  }

  /// Download image for rich media notification
  static Future<void> _downloadAndAttachImage(RemoteMessage message, String imageUrl) async {
    try {
      if (kIsWeb) {
        // Web doesn't support notification attachments in the same way
        ClixLogger.debug('Image attachments not supported on web platform');
        return;
      }

      ClixLogger.debug('Downloading notification image: $imageUrl');
      
      final httpClient = HttpClient();
      final request = await httpClient.getUrl(Uri.parse(imageUrl));
      final response = await request.close();
      
      if (response.statusCode == 200) {
        // On mobile platforms, the image would be processed here
        // Flutter doesn't have direct equivalent to iOS UNNotificationAttachment
        // but we can store the image data for use by the app
        ClixLogger.debug('Image downloaded successfully for notification');
        
        // The actual image attachment would be handled by platform-specific code
        // or by modifying the notification content through platform channels
      } else {
        ClixLogger.warning('Failed to download image: ${response.statusCode}');
      }
      
      httpClient.close();
    } catch (e, stackTrace) {
      ClixLogger.error('Error downloading notification image', e, stackTrace);
    }
  }

  /// Track notification received event
  static Future<void> _trackNotificationReceived(ClixPushNotificationPayload payload) async {
    try {
      // This would typically send an analytics event
      // In a real implementation, this would integrate with the main SDK
      ClixLogger.debug('Tracking notification received: ${payload.messageId}');
      
      // Since this runs in the background, we'd need to use a minimal HTTP client
      // or queue the event for later processing when the app is active
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to track notification received', e, stackTrace);
    }
  }

  /// Handle notification action (when user taps notification)
  static Future<void> handleNotificationAction(RemoteMessage message) async {
    try {
      final payload = ClixPushNotificationPayload.fromRemoteMessage(message);
      
      ClixLogger.debug('Handling notification action: ${payload.messageId}');
      
      // Track notification tapped event
      await _trackNotificationTapped(payload);
      
      // Handle deep link if present
      if (payload.landingUrl != null && payload.landingUrl!.isNotEmpty) {
        await _handleDeepLink(payload.landingUrl!);
      }
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to handle notification action', e, stackTrace);
    }
  }

  /// Track notification tapped event
  static Future<void> _trackNotificationTapped(ClixPushNotificationPayload payload) async {
    try {
      ClixLogger.debug('Tracking notification tapped: ${payload.messageId}');
      
      // Queue event for tracking when app becomes active
      // In a real implementation, this would integrate with the event service
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to track notification tapped', e, stackTrace);
    }
  }

  /// Handle deep link from notification
  static Future<void> _handleDeepLink(String url) async {
    try {
      ClixLogger.debug('Handling deep link: $url');
      
      // This would typically be handled by the app's routing system
      // The URL would be processed when the app becomes active
    } catch (e, stackTrace) {
      ClixLogger.error('Failed to handle deep link', e, stackTrace);
    }
  }
}

/// Background message handler for Firebase Messaging
/// This runs when the app is in the background or terminated
@pragma('vm:entry-point')
Future<void> clixFirebaseMessagingBackgroundHandler(RemoteMessage message) async {
  ClixLogger.debug('Handling background message: ${message.messageId}');
  
  // Process the notification in the background
  await ClixNotificationExtension.processNotification(message);
}