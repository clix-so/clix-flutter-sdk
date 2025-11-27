import 'package:flutter/foundation.dart';

class AppState extends ChangeNotifier {
  static final AppState _instance = AppState._internal();

  factory AppState() => _instance;

  AppState._internal();

  String _projectId = 'Loading...';
  String _apiKey = 'Loading...';
  String _deviceId = 'Loading...';
  String _fcmToken = 'Loading...';

  String get projectId => _projectId;
  String get apiKey => _apiKey;

  String get deviceId => _deviceId;
  String get fcmToken => _fcmToken;

  void updateConfiguration(String projectId, String apiKey) {
    debugPrint('updateConfiguration: $projectId, $apiKey');
    _projectId = projectId;
    _apiKey = apiKey;
    notifyListeners();
  }

  void updateDeviceId(String? deviceId) {
    final value = deviceId ?? 'Not available';
    debugPrint('updateDeviceId: $value');
    _deviceId = value;
    notifyListeners();
  }

  void updateFCMToken(String? token) {
    final value = token ?? 'Not available';
    debugPrint('updateFCMToken: $value');
    _fcmToken = value;
    notifyListeners();
  }
}
