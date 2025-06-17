import 'package:json_annotation/json_annotation.dart';

part 'clix_push_notification_payload.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class ClixPushNotificationPayload {
  final String messageId;
  final String? campaignId;
  final String? userId;
  final String? deviceId;
  final String? trackingId;
  final String? landingUrl;
  final String? imageUrl;
  final Map<String, dynamic>? customProperties;

  const ClixPushNotificationPayload({
    required this.messageId,
    this.campaignId,
    this.userId,
    this.deviceId,
    this.trackingId,
    this.landingUrl,
    this.imageUrl,
    this.customProperties,
  });

  /// Create payload from platform-specific map data
  factory ClixPushNotificationPayload.fromMap(Map<String, dynamic> data) {
    final customProps = Map<String, dynamic>.from(data);

    final standardKeys = [
      'clix_message_id',
      'clix_campaign_id',
      'clix_user_id',
      'clix_device_id',
      'clix_tracking_id',
      'clix_landing_url',
      'clix_image_url',
      // Also handle keys without clix_ prefix for compatibility
      'message_id',
      'campaign_id',
      'user_id',
      'device_id',
      'tracking_id',
      'landing_url',
      'image_url',
    ];

    for (final key in standardKeys) {
      customProps.remove(key);
    }

    // Extract custom properties
    Map<String, dynamic>? customProperties;
    if (customProps.isNotEmpty) {
      customProperties = customProps;
    }

    final messageId = data['clix_message_id'] as String? ??
        data['message_id'] as String? ??
        ''; // Default empty string for required field

    return ClixPushNotificationPayload(
      messageId: messageId,
      campaignId:
          data['clix_campaign_id'] as String? ?? data['campaign_id'] as String?,
      userId: data['clix_user_id'] as String? ?? data['user_id'] as String?,
      deviceId:
          data['clix_device_id'] as String? ?? data['device_id'] as String?,
      trackingId:
          data['clix_tracking_id'] as String? ?? data['tracking_id'] as String?,
      landingUrl:
          data['clix_landing_url'] as String? ?? data['landing_url'] as String?,
      imageUrl:
          data['clix_image_url'] as String? ?? data['image_url'] as String?,
      customProperties: customProperties,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => _$ClixPushNotificationPayloadToJson(this);

  /// Create from JSON
  factory ClixPushNotificationPayload.fromJson(Map<String, dynamic> json) =>
      _$ClixPushNotificationPayloadFromJson(json);

  @override
  String toString() {
    return 'ClixPushNotificationPayload(messageId: $messageId, campaignId: $campaignId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ClixPushNotificationPayload && other.messageId == messageId;
  }

  @override
  int get hashCode => messageId.hashCode;
}
