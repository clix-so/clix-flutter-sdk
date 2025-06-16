class ClixPushNotificationPayload {
  final String? messageId;
  final String? campaignId;
  final String? userId;
  final String? deviceId;
  final String? trackingId;
  final String? landingUrl;
  final String? imageUrl;
  final Map<String, dynamic> customProperties;

  ClixPushNotificationPayload({
    this.messageId,
    this.campaignId,
    this.userId,
    this.deviceId,
    this.trackingId,
    this.landingUrl,
    this.imageUrl,
    Map<String, dynamic>? customProperties,
  }) : customProperties = customProperties ?? {};


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

    return ClixPushNotificationPayload(
      messageId: data['clix_message_id'] as String? ?? data['message_id'] as String?,
      campaignId: data['clix_campaign_id'] as String? ?? data['campaign_id'] as String?,
      userId: data['clix_user_id'] as String? ?? data['user_id'] as String?,
      deviceId: data['clix_device_id'] as String? ?? data['device_id'] as String?,
      trackingId: data['clix_tracking_id'] as String? ?? data['tracking_id'] as String?,
      landingUrl: data['clix_landing_url'] as String? ?? data['landing_url'] as String?,
      imageUrl: data['clix_image_url'] as String? ?? data['image_url'] as String?,
      customProperties: customProps,
    );
  }

  Map<String, dynamic> toJson() => {
        'message_id': messageId,
        'campaign_id': campaignId,
        'user_id': userId,
        'device_id': deviceId,
        'tracking_id': trackingId,
        'landing_url': landingUrl,
        'image_url': imageUrl,
        'custom_properties': customProperties,
      };

  factory ClixPushNotificationPayload.fromJson(Map<String, dynamic> json) {
    return ClixPushNotificationPayload(
      messageId: json['message_id'] as String?,
      campaignId: json['campaign_id'] as String?,
      userId: json['user_id'] as String?,
      deviceId: json['device_id'] as String?,
      trackingId: json['tracking_id'] as String?,
      landingUrl: json['landing_url'] as String?,
      imageUrl: json['image_url'] as String?,
      customProperties: Map<String, dynamic>.from(json['custom_properties'] ?? {}),
    );
  }
}