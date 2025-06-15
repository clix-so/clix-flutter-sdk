class ClixEvent {
  final String name;
  final String deviceId;
  final String? userId;
  final Map<String, dynamic>? properties;
  final String? messageId;
  final DateTime timestamp;

  ClixEvent({
    required this.name,
    required this.deviceId,
    this.userId,
    this.properties,
    this.messageId,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'name': name,
        'device_id': deviceId,
        'user_id': userId,
        'properties': properties,
        'message_id': messageId,
        'timestamp': timestamp.toIso8601String(),
      };

  factory ClixEvent.fromJson(Map<String, dynamic> json) => ClixEvent(
        name: json['name'] as String,
        deviceId: json['device_id'] as String,
        userId: json['user_id'] as String?,
        properties: json['properties'] as Map<String, dynamic>?,
        messageId: json['message_id'] as String?,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}