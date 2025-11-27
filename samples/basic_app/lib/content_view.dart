import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:clix_flutter/clix_flutter.dart';
import 'app_state.dart';
import 'app_theme.dart';
import 'main.dart';

class ContentView extends StatefulWidget {
  const ContentView({super.key});

  @override
  State<ContentView> createState() => _ContentViewState();
}

class _ContentViewState extends State<ContentView> {
  final _appState = AppState();
  final _userIdController = TextEditingController();
  final _userPropertyKeyController = TextEditingController();
  final _userPropertyValueController = TextEditingController();
  final _eventNameController = TextEditingController(text: 'test');
  final _eventParamsController = TextEditingController(
    text: '''
{
  "string": "string",
  "number": 1.5,
  "boolean": true,
  "object": { "key": "value" }
}''',
  );

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _appState.addListener(_onAppStateChanged);
  }

  void _onAppStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadInitialData() async {
    final deviceId = await Clix.getDeviceId();
    final fcmToken = await Clix.Notification.getToken();
    _appState.updateDeviceId(deviceId);
    _appState.updateFCMToken(fcmToken);

    final storedUserId = BasicApplication.sharedPreferences
        .getString(BasicApplication.keyUserId);
    if (storedUserId != null && storedUserId.isNotEmpty) {
      _userIdController.text = storedUserId;
    }
  }

  Future<void> _showAlert(String message) async {
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _setUserId() async {
    final userId = _userIdController.text.trim();
    if (userId.isEmpty) {
      await _showAlert('Please enter a User ID');
      return;
    }

    try {
      await Clix.setUserId(userId);
      await BasicApplication.sharedPreferences
          .setString(BasicApplication.keyUserId, userId);
      await _showAlert('User ID set!');
    } catch (e) {
      await _showAlert('Failed to set user ID: $e');
    }
  }

  Future<void> _setUserProperty() async {
    final key = _userPropertyKeyController.text.trim();
    final value = _userPropertyValueController.text.trim();

    if (key.isEmpty || value.isEmpty) {
      await _showAlert('Please enter both key and value for user property');
      return;
    }

    try {
      await Clix.setUserProperty(key, value);
      await _showAlert('User property \'$key: $value\' set successfully');
      _userPropertyKeyController.clear();
      _userPropertyValueController.clear();
    } catch (e) {
      await _showAlert('Failed to set user property: $e');
    }
  }

  Future<void> _trackEvent() async {
    final eventName = _eventNameController.text.trim();
    if (eventName.isEmpty) {
      await _showAlert('Please enter an event name');
      return;
    }

    try {
      Map<String, dynamic>? properties;
      final params = _eventParamsController.text.trim();
      if (params.isNotEmpty && params != '{}') {
        properties = Map<String, dynamic>.from(jsonDecode(params) as Map);
      }

      await Clix.trackEvent(eventName, properties: properties);
      await _showAlert('Event tracked: $eventName');
    } catch (e) {
      await _showAlert('Invalid JSON format or tracking failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              Image.asset(
                'assets/logo.png',
                width: 120,
                height: 120,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 32),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                decoration: BoxDecoration(
                  color: AppTheme.surface.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Project ID', _appState.projectId),
                    _buildInfoRow('API Key', _appState.apiKey),
                    _buildInfoRow('Device ID', _appState.deviceId),
                    _buildInfoRow('FCM Token', _appState.fcmToken,
                        lastItem: true),
                    const SizedBox(height: 32),
                    _buildUserIdSection(),
                    const SizedBox(height: 32),
                    _buildUserPropertySection(),
                    const SizedBox(height: 32),
                    _buildTrackEventSection(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool lastItem = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: lastItem ? 0 : 12),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          color: AppTheme.text,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildUserIdSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'User ID',
          style: TextStyle(
            color: AppTheme.text,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: _userIdController,
          style: const TextStyle(color: AppTheme.text),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppTheme.surfaceVariant.withValues(alpha: 0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 56,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _setUserId,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.buttonBackground.withValues(alpha: 0.9),
              foregroundColor: AppTheme.buttonText,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Submit',
              style: TextStyle(
                color: AppTheme.buttonText,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserPropertySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'User Property Key',
          style: TextStyle(
            color: AppTheme.text,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: _userPropertyKeyController,
          style: const TextStyle(color: AppTheme.text),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppTheme.surfaceVariant.withValues(alpha: 0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'User Property Value',
          style: TextStyle(
            color: AppTheme.text,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: _userPropertyValueController,
          style: const TextStyle(color: AppTheme.text),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppTheme.surfaceVariant.withValues(alpha: 0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 56,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _setUserProperty,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.buttonBackground.withValues(alpha: 0.9),
              foregroundColor: AppTheme.buttonText,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Set User Property',
              style: TextStyle(
                color: AppTheme.buttonText,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrackEventSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Event Name',
          style: TextStyle(
            color: AppTheme.text,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: _eventNameController,
          style: const TextStyle(color: AppTheme.text),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppTheme.surfaceVariant.withValues(alpha: 0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Event Parameters',
          style: TextStyle(
            color: AppTheme.text,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: _eventParamsController,
          style: const TextStyle(color: AppTheme.text),
          maxLines: 6,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppTheme.surfaceVariant.withValues(alpha: 0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 56,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _trackEvent,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.buttonBackground.withValues(alpha: 0.9),
              foregroundColor: AppTheme.buttonText,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Track Event',
              style: TextStyle(
                color: AppTheme.buttonText,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _appState.removeListener(_onAppStateChanged);
    _userIdController.dispose();
    _userPropertyKeyController.dispose();
    _userPropertyValueController.dispose();
    _eventNameController.dispose();
    _eventParamsController.dispose();
    super.dispose();
  }
}
