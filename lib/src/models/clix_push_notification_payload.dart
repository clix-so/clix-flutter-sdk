import 'package:json_annotation/json_annotation.dart';

part 'clix_push_notification_payload.g.dart';

/// ClixPushNotificationPayload that mirrors the iOS SDK ClixPushNotificationPayload implementation
@JsonSerializable()
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

  /// Convert to JSON map
  Map<String, dynamic> toJson() => _$ClixPushNotificationPayloadToJson(this);

  /// Create from JSON map
  factory ClixPushNotificationPayload.fromJson(Map<String, dynamic> json) =>
      _$ClixPushNotificationPayloadFromJson(json);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ClixPushNotificationPayload && other.messageId == messageId;
  }

  @override
  int get hashCode => messageId.hashCode;

  @override
  String toString() {
    return 'ClixPushNotificationPayload(messageId: $messageId, campaignId: $campaignId)';
  }
}