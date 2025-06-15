import 'dart:async';
import 'package:flutter/material.dart';
import 'package:clix/clix.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Clix SDK with static method
  await Clix.initialize(const ClixConfig(
    projectId: 'YOUR_PROJECT_ID',
    apiKey: 'YOUR_API_KEY',
    logLevel: ClixLogLevel.debug,
  ));

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clix Flutter SDK Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _userIdController = TextEditingController();
  final _propertyNameController = TextEditingController();
  final _propertyValueController = TextEditingController();
  final _eventNameController = TextEditingController();

  String _status = 'SDK Initialized';
  StreamSubscription<ClixPushNotificationPayload>? _receivedSubscription;
  StreamSubscription<ClixPushNotificationPayload>? _tappedSubscription;

  @override
  void initState() {
    super.initState();
    _setupNotificationStreams();
  }

  void _setupNotificationStreams() {
    // Use streams for notification handling (more Dart-idiomatic)
    _receivedSubscription = Clix.onNotificationReceived?.listen((payload) {
      setState(() {
        _status = 'Notification received: ${payload.messageId}';
      });
    });

    _tappedSubscription = Clix.onNotificationTapped?.listen((payload) {
      setState(() {
        _status = 'Notification tapped: ${payload.messageId}';
      });

      // Handle deep links
      if (payload.landingUrl != null) {
        _handleDeepLink(payload.landingUrl!);
      }
    });
  }

  void _handleDeepLink(String url) {
    // Handle deep link navigation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening: $url')),
    );
  }

  Future<void> _setUserId() async {
    final userId = _userIdController.text.trim();
    if (userId.isEmpty) return;

    try {
      await Clix.setUserId(userId);
      setState(() {
        _status = 'User ID set: $userId';
      });
    } catch (e) {
      setState(() {
        _status = 'Error setting user ID: $e';
      });
    }
  }

  Future<void> _setUserProperty() async {
    final name = _propertyNameController.text.trim();
    final value = _propertyValueController.text.trim();
    if (name.isEmpty || value.isEmpty) return;

    try {
      await Clix.setUserProperty(name, value);
      setState(() {
        _status = 'User property set: $name = $value';
      });
    } catch (e) {
      setState(() {
        _status = 'Error setting property: $e';
      });
    }
  }

  // This method is provided as an example of how to track events with Clix SDK
  // It's not currently used in the UI but is kept for reference and future use
  Future<void> _trackEvent() async {
    final eventName = _eventNameController.text.trim();
    if (eventName.isEmpty) return;

    try {
      await Clix.trackEvent(
        eventName,
        properties: {
          'timestamp': DateTime.now().toIso8601String(),
          'source': 'example_app',
          'screen': 'home',
        },
      );
      setState(() {
        _status = 'Event tracked: $eventName';
      });
    } catch (e) {
      setState(() {
        _status = 'Error tracking event: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clix SDK Example (Dart Idiomatic)'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // SDK Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SDK Information',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text('Device ID: ${Clix.getDeviceIdSync() ?? 'N/A'}'),
                    const Text('User ID: Not available in static API'),
                    Text('Status: $_status'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // User ID Section
            _buildInputSection(
              title: 'Set User ID',
              controller: _userIdController,
              hintText: 'Enter user ID',
              buttonText: 'Set User ID',
              onPressed: _setUserId,
            ),
            const SizedBox(height: 16),

            // User Property Section
            _buildPropertySection(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildInputSection({
    required String title,
    required TextEditingController controller,
    required String hintText,
    required String buttonText,
    required VoidCallback onPressed,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: title,
                hintText: hintText,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: onPressed,
              child: Text(buttonText),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Set User Property',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _propertyNameController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Property Name',
                hintText: 'e.g., subscription_plan',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _propertyValueController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Property Value',
                hintText: 'e.g., premium',
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _setUserProperty,
              child: const Text('Set Property'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _userIdController.dispose();
    _propertyNameController.dispose();
    _propertyValueController.dispose();
    _eventNameController.dispose();
    _receivedSubscription?.cancel();
    _tappedSubscription?.cancel();
    super.dispose();
  }
}
