
class ClixDevice {
  final String id;
  final String platform;
  final String model;
  final String manufacturer;
  final String osName;
  final String osVersion;
  final String localeRegion;
  final String localeLanguage;
  final String timezone;
  final String appName;
  final String appVersion;
  final String sdkType;
  final String sdkVersion;
  final String? adId;
  final bool isPushPermissionGranted;
  final String? pushToken;
  final String? pushTokenType;

  ClixDevice({
    required this.id,
    required this.platform,
    required this.model,
    required this.manufacturer,
    required this.osName,
    required this.osVersion,
    required this.localeRegion,
    required this.localeLanguage,
    required this.timezone,
    required this.appName,
    required this.appVersion,
    required this.sdkType,
    required this.sdkVersion,
    this.adId,
    required this.isPushPermissionGranted,
    this.pushToken,
    this.pushTokenType,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'platform': platform,
        'model': model,
        'manufacturer': manufacturer,
        'os_name': osName,
        'os_version': osVersion,
        'locale_region': localeRegion,
        'locale_language': localeLanguage,
        'timezone': timezone,
        'app_name': appName,
        'app_version': appVersion,
        'sdk_type': sdkType,
        'sdk_version': sdkVersion,
        'ad_id': adId,
        'is_push_permission_granted': isPushPermissionGranted,
        'push_token': pushToken,
        'push_token_type': pushTokenType,
      };

  factory ClixDevice.fromJson(Map<String, dynamic> json) => ClixDevice(
        id: json['id'] as String,
        platform: json['platform'] as String,
        model: json['model'] as String,
        manufacturer: json['manufacturer'] as String,
        osName: json['os_name'] as String,
        osVersion: json['os_version'] as String,
        localeRegion: json['locale_region'] as String,
        localeLanguage: json['locale_language'] as String,
        timezone: json['timezone'] as String,
        appName: json['app_name'] as String,
        appVersion: json['app_version'] as String,
        sdkType: json['sdk_type'] as String,
        sdkVersion: json['sdk_version'] as String,
        adId: json['ad_id'] as String?,
        isPushPermissionGranted: json['is_push_permission_granted'] as bool,
        pushToken: json['push_token'] as String?,
        pushTokenType: json['push_token_type'] as String?,
      );

  ClixDevice copyWith({
    String? id,
    String? platform,
    String? model,
    String? manufacturer,
    String? osName,
    String? osVersion,
    String? localeRegion,
    String? localeLanguage,
    String? timezone,
    String? appName,
    String? appVersion,
    String? sdkType,
    String? sdkVersion,
    String? adId,
    bool? isPushPermissionGranted,
    String? pushToken,
    String? pushTokenType,
  }) {
    return ClixDevice(
      id: id ?? this.id,
      platform: platform ?? this.platform,
      model: model ?? this.model,
      manufacturer: manufacturer ?? this.manufacturer,
      osName: osName ?? this.osName,
      osVersion: osVersion ?? this.osVersion,
      localeRegion: localeRegion ?? this.localeRegion,
      localeLanguage: localeLanguage ?? this.localeLanguage,
      timezone: timezone ?? this.timezone,
      appName: appName ?? this.appName,
      appVersion: appVersion ?? this.appVersion,
      sdkType: sdkType ?? this.sdkType,
      sdkVersion: sdkVersion ?? this.sdkVersion,
      adId: adId ?? this.adId,
      isPushPermissionGranted: isPushPermissionGranted ?? this.isPushPermissionGranted,
      pushToken: pushToken ?? this.pushToken,
      pushTokenType: pushTokenType ?? this.pushTokenType,
    );
  }
}