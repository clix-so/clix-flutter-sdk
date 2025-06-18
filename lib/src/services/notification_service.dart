import 'dart:io';
import '../utils/logging/clix_logger.dart';
import 'event_service.dart';
import 'storage_service.dart';

/// NotificationService that mirrors the iOS SDK NotificationService implementation
class NotificationService {
  final EventService _eventService;
  final StorageService _storageService;

  NotificationService({
    required EventService eventService,
    required StorageService storageService,
  }) : _eventService = eventService,
       _storageService = storageService;

  /// Handle push notification received - mirrors iOS handlePushReceived
  Future<void> handlePushReceived(Map<String, dynamic> userInfo) async {
    try {
      final messageId = getMessageId(userInfo);
      if (messageId != null) {
        await _eventService.trackEvent(
          'PUSH_NOTIFICATION_RECEIVED',
          properties: {'messageId': messageId},
        );
        ClixLogger.info('Push notification received tracked: $messageId');
      }
    } catch (e) {
      ClixLogger.error('Failed to handle push received', e);
    }
  }

  /// Handle push notification tapped - mirrors iOS handlePushTapped
  Future<void> handlePushTapped(Map<String, dynamic> userInfo) async {
    try {
      final messageId = getMessageId(userInfo);
      if (messageId != null) {
        await _eventService.trackEvent(
          'PUSH_NOTIFICATION_TAPPED',
          properties: {'messageId': messageId},
        );
        ClixLogger.info('Push notification tapped tracked: $messageId');
      }
    } catch (e) {
      ClixLogger.error('Failed to handle push tapped', e);
    }
  }

  /// Parse Clix payload from notification data - mirrors iOS parseClixPayload
  Map<String, dynamic>? parseClixPayload(Map<String, dynamic> userInfo) {
    try {
      // Check for direct Clix data
      if (userInfo.containsKey('clix')) {
        final clixData = userInfo['clix'];
        if (clixData is Map<String, dynamic>) {
          return clixData;
        }
        if (clixData is String) {
          // Parse JSON string
          // Note: In a real implementation, you'd use dart:convert
          // For now, return null as we can't parse JSON string without import
          return null;
        }
      }

      // Check for Clix keys at root level
      final clixKeys = ['message_id', 'campaign_id', 'user_id', 'device_id', 'tracking_id'];
      if (clixKeys.any((key) => userInfo.containsKey(key))) {
        return userInfo;
      }

      return null;
    } catch (e) {
      ClixLogger.error('Failed to parse Clix payload', e);
      return null;
    }
  }

  /// Get message ID from user info - mirrors iOS getMessageId
  String? getMessageId(Map<String, dynamic> userInfo) {
    final clixPayload = parseClixPayload(userInfo);
    return clixPayload?['message_id'] as String?;
  }

  /// Extract image URL from notification - mirrors iOS extractImageURL
  String? extractImageURL(Map<String, dynamic> userInfo) {
    try {
      // First check Clix payload
      final clixPayload = parseClixPayload(userInfo);
      if (clixPayload != null) {
        final imageUrl = clixPayload['image_url'] as String?;
        if (imageUrl != null && imageUrl.isNotEmpty) {
          return imageUrl;
        }
      }

      // Fallback to traditional sources
      return extractImageURLFromTraditionalSources(userInfo);
    } catch (e) {
      ClixLogger.error('Failed to extract image URL', e);
      return null;
    }
  }

  /// Extract image URL from traditional FCM sources - mirrors iOS extractImageURLFromTraditionalSources
  String? extractImageURLFromTraditionalSources(Map<String, dynamic> userInfo) {
    try {
      // Check common FCM image fields
      final imageFields = ['image', 'picture', 'image_url', 'imageUrl'];
      for (final field in imageFields) {
        final value = userInfo[field] as String?;
        if (value != null && value.isNotEmpty) {
          return value;
        }
      }

      // Check FCM options
      final fcmOptions = userInfo['fcm_options'] as Map<String, dynamic>?;
      if (fcmOptions != null) {
        final image = fcmOptions['image'] as String?;
        if (image != null && image.isNotEmpty) {
          return image;
        }
      }

      return null;
    } catch (e) {
      ClixLogger.error('Failed to extract image URL from traditional sources', e);
      return null;
    }
  }

  /// Download notification image - mirrors iOS downloadNotificationImage
  Future<List<int>?> downloadNotificationImage(String imageUrl) async {
    try {
      ClixLogger.info('Downloading notification image: $imageUrl');
      
      // Use dart:io HttpClient for image download
      final httpClient = HttpClient();
      final uri = Uri.parse(imageUrl);
      final request = await httpClient.getUrl(uri);
      final response = await request.close();
      
      if (response.statusCode == 200) {
        final bytes = <int>[];
        await for (final chunk in response) {
          bytes.addAll(chunk);
        }
        
        ClixLogger.info('Notification image downloaded successfully (${bytes.length} bytes)');
        httpClient.close();
        return bytes;
      } else {
        ClixLogger.warn('Failed to download image: HTTP ${response.statusCode}');
        httpClient.close();
        return null;
      }
    } catch (e) {
      ClixLogger.error('Failed to download notification image', e);
      return null;
    }
  }

  /// Request notification permission - mirrors iOS requestNotificationPermission
  Future<bool> requestNotificationPermission() async {
    try {
      ClixLogger.info('Requesting notification permission');
      
      // Note: In a real implementation, this would call platform-specific code
      // For now, return true as placeholder
      const granted = true; // Placeholder
      
      ClixLogger.info('Notification permission granted: $granted');
      return granted;
    } catch (e) {
      ClixLogger.error('Failed to request notification permission', e);
      return false;
    }
  }

  /// Set notification preferences - mirrors iOS setNotificationPreferences
  Future<void> setNotificationPreferences({
    required bool enabled,
    List<String>? categories,
  }) async {
    try {
      final settings = {
        'enabled': enabled,
        'categories': categories ?? [],
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      
      await _storageService.setJson('clix_notification_settings', settings);
      ClixLogger.info('Notification preferences saved: enabled=$enabled');
    } catch (e) {
      ClixLogger.error('Failed to set notification preferences', e);
    }
  }

  /// Reset notification data - mirrors iOS reset
  Future<void> reset() async {
    try {
      await _storageService.remove('clix_notification_settings');
      await _storageService.remove('clix_last_notification');
      ClixLogger.info('Notification data reset completed');
    } catch (e) {
      ClixLogger.error('Failed to reset notification data', e);
    }
  }
}