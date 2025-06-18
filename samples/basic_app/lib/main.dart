import 'dart:async';

import 'package:clix_flutter/clix_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'clix_info.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();


  await Clix.initialize(const ClixConfig(
    projectId: ClixInfo.projectId,
    apiKey: ClixInfo.apiKey,
    logLevel: ClixLogLevel.debug,
  ));

  runApp(const ClixSampleApp());
}

class ClixSampleApp extends StatelessWidget {
  const ClixSampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clix Sample',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF007AFF),
          brightness: Brightness.dark,
          surface: const Color(0xFF48484A),
          onSurface: Colors.white,
          primary: const Color(0xFF007AFF),
          onPrimary: Colors.white,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Colors.white,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Colors.white,
          ),
          labelLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        cardTheme: const CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          color: Color(0xFF48484A),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            backgroundColor: const Color(0xFFE5E5EA),
            foregroundColor: Colors.black,
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF3A3A3C),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          hintStyle: const TextStyle(
            color: Color(0xFF8E8E93),
            fontSize: 16,
          ),
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _userIdController = TextEditingController();
  final _propertyKeyController = TextEditingController();
  final _propertyValueController = TextEditingController();

  final String _projectId = ClixInfo.projectId;
  final String _apiKey = ClixInfo.apiKey;
  String? _deviceId;
  String? _pushToken;
  StreamSubscription<ClixPushNotificationPayload>? _receivedSubscription;
  StreamSubscription<ClixPushNotificationPayload>? _tappedSubscription;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _setupNotificationStreams();
  }

  Future<void> _initializeData() async {
    try {
      final deviceId = await Clix.getDeviceId();
      final pushToken = await Clix.getPushToken();

      setState(() {
        _deviceId = deviceId;
        _pushToken = pushToken;
      });
    } catch (e) {
      debugPrint('Failed to load device information: $e');
    }
  }

  void _setupNotificationStreams() {
    debugPrint('Notification streams setup - handled internally by Clix SDK');
  }

  Future<void> _setUserId() async {
    final userId = _userIdController.text.trim();
    if (userId.isEmpty) return;

    final messenger = ScaffoldMessenger.of(context);

    try {
      await Clix.setUserId(userId);
      _userIdController.clear();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('User ID set successfully'),
          backgroundColor: Color(0xFF34C759),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to set user ID: $e'),
          backgroundColor: const Color(0xFFFF3B30),
        ),
      );
    }
  }

  Future<void> _setUserProperty() async {
    final key = _propertyKeyController.text.trim();
    final value = _propertyValueController.text.trim();

    if (key.isEmpty || value.isEmpty) return;

    final messenger = ScaffoldMessenger.of(context);

    try {
      await Clix.setUserProperty(key, value);
      _propertyKeyController.clear();
      _propertyValueController.clear();
      messenger.showSnackBar(
        SnackBar(
          content: Text('Property set: $key = $value'),
          backgroundColor: const Color(0xFF34C759),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to set property: $e'),
          backgroundColor: const Color(0xFFFF3B30),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161618),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow('Project ID:', _projectId),
                      const SizedBox(height: 16),
                      _buildInfoRow('API Key:', _apiKey),
                      const SizedBox(height: 16),
                      _buildInfoRow('Device ID:', _deviceId ?? 'Loading...'),
                      const SizedBox(height: 16),
                      _buildInfoRow('Push Token:',
                          _pushToken != null ? _pushToken! : 'Not available'),

                      const SizedBox(height: 32),

                      const Text(
                        'User ID',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _userIdController,
                              decoration: const InputDecoration(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: _setUserId,
                            child: const Text('Submit'),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      const Text(
                        'User Property Key',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),

                      TextField(
                        controller: _propertyKeyController,
                        decoration: const InputDecoration(
                          hintText: 'Enter property key',
                        ),
                        style: const TextStyle(color: Colors.white),
                      ),

                      const SizedBox(height: 24),

                      const Text(
                        'User Property Value',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),

                      TextField(
                        controller: _propertyValueController,
                        decoration: const InputDecoration(
                          hintText: 'Enter property value',
                        ),
                        style: const TextStyle(color: Colors.white),
                      ),

                      const SizedBox(height: 32),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _setUserProperty,
                          child: const Text('Set User Property'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ));
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF8E8E93),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _userIdController.dispose();
    _propertyKeyController.dispose();
    _propertyValueController.dispose();
    _receivedSubscription?.cancel();
    _tappedSubscription?.cancel();
    super.dispose();
  }
}
