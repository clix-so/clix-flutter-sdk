// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clix_push_notification_payload.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ClixPushNotificationPayload _$ClixPushNotificationPayloadFromJson(Map json) =>
    ClixPushNotificationPayload(
      messageId: json['message_id'] as String,
      campaignId: json['campaign_id'] as String?,
      userId: json['user_id'] as String?,
      deviceId: json['device_id'] as String?,
      trackingId: json['tracking_id'] as String?,
      landingUrl: json['landing_url'] as String?,
      imageUrl: json['image_url'] as String?,
      customProperties: (json['custom_properties'] as Map?)?.map(
        (k, e) => MapEntry(k as String, e),
      ),
    );

Map<String, dynamic> _$ClixPushNotificationPayloadToJson(
        ClixPushNotificationPayload instance) =>
    <String, dynamic>{
      'message_id': instance.messageId,
      'campaign_id': instance.campaignId,
      'user_id': instance.userId,
      'device_id': instance.deviceId,
      'tracking_id': instance.trackingId,
      'landing_url': instance.landingUrl,
      'image_url': instance.imageUrl,
      'custom_properties': instance.customProperties,
    };
