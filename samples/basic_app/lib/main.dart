import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:clix_flutter/clix.dart';

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Handling a background message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Set up background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize Clix SDK with static method
  await Clix.initialize(const ClixConfig(
    projectId: 'YOUR_PROJECT_ID',
    apiKey: 'YOUR_API_KEY',
    logLevel: ClixLogLevel.debug,
  ));

  runApp(const ClixSampleApp());
}

class ClixSampleApp extends StatelessWidget {
  const ClixSampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clix iOS-Style Sample',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // iOS-inspired color scheme
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF007AFF), // iOS blue
          brightness: Brightness.light,
        ),
        
        // iOS-inspired typography
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
          headlineMedium: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
          headlineSmall: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.1,
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          bodyLarge: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w400,
          ),
          bodyMedium: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
        ),
        
        // iOS-inspired card design
        cardTheme: const CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            side: BorderSide(
              color: Color(0xFFE0E0E0),
              width: 0.5,
            ),
          ),
          color: Colors.white,
        ),
        
        // iOS-inspired button design
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        
        // iOS-inspired input field design
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF007AFF), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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

  String _statusMessage = 'SDK Initialized Successfully';
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
      _updateStatus('Failed to load device information: $e');
    }
  }

  void _setupNotificationStreams() {
    _receivedSubscription = Clix.onNotificationReceived?.listen((payload) {
      _updateStatus('Notification received: ${payload.messageId}');
    });

    _tappedSubscription = Clix.onNotificationTapped?.listen((payload) {
      _updateStatus('Notification tapped: ${payload.messageId}');
      
      // Handle deep links
      if (payload.landingUrl != null) {
        _handleDeepLink(payload.landingUrl!);
      }
    });
  }

  void _handleDeepLink(String url) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening: $url'),
        backgroundColor: const Color(0xFF007AFF),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _updateStatus(String message) {
    setState(() {
      _statusMessage = message;
    });
  }

  Future<void> _setUserId() async {
    final userId = _userIdController.text.trim();
    if (userId.isEmpty) {
      _updateStatus('Please enter a user ID');
      return;
    }

    try {
      await Clix.setUserId(userId);
      _updateStatus('User ID set: $userId');
      _userIdController.clear();
    } catch (e) {
      _updateStatus('Failed to set user ID: $e');
    }
  }

  Future<void> _removeUserId() async {
    try {
      await Clix.removeUserId();
      _updateStatus('User ID removed successfully');
    } catch (e) {
      _updateStatus('Failed to remove user ID: $e');
    }
  }

  Future<void> _setUserProperty() async {
    final key = _propertyKeyController.text.trim();
    final value = _propertyValueController.text.trim();
    
    if (key.isEmpty || value.isEmpty) {
      _updateStatus('Please enter both property key and value');
      return;
    }

    try {
      await Clix.setUserProperty(key, value);
      _updateStatus('Property set: $key = $value');
      _propertyKeyController.clear();
      _propertyValueController.clear();
    } catch (e) {
      _updateStatus('Failed to set property: $e');
    }
  }

  Future<void> _removeUserProperty() async {
    final key = _propertyKeyController.text.trim();
    if (key.isEmpty) {
      _updateStatus('Please enter a property key to remove');
      return;
    }

    try {
      await Clix.removeUserProperty(key);
      _updateStatus('Property removed: $key');
      _propertyKeyController.clear();
    } catch (e) {
      _updateStatus('Failed to remove property: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header with logo and title
              _buildHeader(),
              const SizedBox(height: 24),
              
              // SDK Status Card
              _buildStatusCard(),
              const SizedBox(height: 20),
              
              // Device Information Card
              _buildDeviceInfoCard(),
              const SizedBox(height: 20),
              
              // User Management Section
              _buildUserManagementCard(),
              const SizedBox(height: 20),
              
              // User Properties Section
              _buildUserPropertiesCard(),
              const SizedBox(height: 20),
              
              // Quick Actions
              _buildQuickActionsCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Logo
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              'assets/logo.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Title
        Text(
          'Clix SDK Sample',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'iOS-Style Flutter Implementation',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: Color(0xFF007AFF),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Status',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF007AFF).withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF007AFF).withValues(alpha: 0.1),
                ),
              ),
              child: Text(
                _statusMessage,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF007AFF),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.phone_iphone,
                  color: Colors.grey.shade700,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Device Information',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            _buildInfoRow('Device ID', _deviceId ?? 'Loading...'),
            const SizedBox(height: 8),
            _buildInfoRow('Push Token', _pushToken?.substring(0, 20) ?? 'Loading...'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontFamily: 'Monaco',
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserManagementCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  color: Colors.green.shade600,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'User Management',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: _userIdController,
              decoration: const InputDecoration(
                labelText: 'User ID',
                hintText: 'Enter user identifier',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _setUserId,
                    icon: const Icon(Icons.person_add, size: 18),
                    label: const Text('Set User ID'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _removeUserId,
                    icon: const Icon(Icons.person_remove, size: 18),
                    label: const Text('Remove'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserPropertiesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.settings_outlined,
                  color: Colors.orange.shade600,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'User Properties',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: _propertyKeyController,
              decoration: const InputDecoration(
                labelText: 'Property Key',
                hintText: 'e.g., subscription_plan',
                prefixIcon: Icon(Icons.key_outlined),
              ),
            ),
            const SizedBox(height: 12),
            
            TextField(
              controller: _propertyValueController,
              decoration: const InputDecoration(
                labelText: 'Property Value',
                hintText: 'e.g., premium',
                prefixIcon: Icon(Icons.edit_outlined),
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _setUserProperty,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Set Property'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade600,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _removeUserProperty,
                    icon: const Icon(Icons.remove, size: 18),
                    label: const Text('Remove'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.flash_on_outlined,
                  color: Colors.purple.shade600,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _initializeData,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Refresh Device Info'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple.shade600,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
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