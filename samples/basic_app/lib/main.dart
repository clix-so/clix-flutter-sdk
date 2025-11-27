import 'package:clix_flutter/clix_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_state.dart';
import 'app_theme.dart';
import 'clix_configuration.dart';
import 'content_view.dart';

class BasicApplication {
  static const String prefsName = 'user_preferences';
  static const String keyUserId = 'user_id';

  static late SharedPreferences sharedPreferences;

  static Future<void> initialize() async {
    sharedPreferences = await SharedPreferences.getInstance();

    // Initialize configuration (loads once and caches)
    await ClixConfiguration.initialize();

    // Get cached configuration
    final config = ClixConfiguration.config;

    // Update app state with configuration for UI display
    AppState().updateConfiguration(config.projectId, config.apiKey);

    // Initialize Clix SDK with the loaded configuration
    await Clix.initialize(config);

    await _updateClixValues();

    final storedUserId = sharedPreferences.getString(keyUserId);
    if (storedUserId != null && storedUserId.isNotEmpty) {
      await Clix.setUserId(storedUserId);
    }
  }

  static Future<void> _updateClixValues() async {
    final deviceId = await Clix.getDeviceId();
    final fcmToken = await Clix.Notification.getToken();

    AppState().updateDeviceId(deviceId);
    AppState().updateFCMToken(fcmToken);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  await BasicApplication.initialize();

  runApp(const ClixSampleApp());
}

class ClixSampleApp extends StatelessWidget {
  const ClixSampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clix Sample',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const MainActivity(),
    );
  }
}

class MainActivity extends StatelessWidget {
  const MainActivity({super.key});

  @override
  Widget build(BuildContext context) {
    return const ContentView();
  }
}
