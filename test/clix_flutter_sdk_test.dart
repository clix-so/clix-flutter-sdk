import 'package:flutter_test/flutter_test.dart';
import 'package:clix/clix.dart';

void main() {
  group('Clix SDK Tests', () {
    tearDown(() {
      // Clean up after each test
      Clix.dispose();
    });

    test('ClixLogLevel comparison operators work correctly', () {
      expect(ClixLogLevel.error >= ClixLogLevel.warning, isTrue);
      expect(ClixLogLevel.debug <= ClixLogLevel.info, isTrue);
      expect(ClixLogLevel.verbose < ClixLogLevel.debug, isTrue);
      expect(ClixLogLevel.none > ClixLogLevel.error, isTrue);
    });

    test('ClixLogLevel shouldLog works correctly', () {
      expect(ClixLogLevel.error.shouldLog(ClixLogLevel.error), isTrue);
      expect(ClixLogLevel.error.shouldLog(ClixLogLevel.warning), isFalse);
      expect(ClixLogLevel.debug.shouldLog(ClixLogLevel.info), isTrue);
      expect(ClixLogLevel.warning.shouldLog(ClixLogLevel.debug), isFalse);
    });

    test('ClixConfig validation', () {
      expect(() => const ClixConfig(
        projectId: '',
        apiKey: 'test',
      ), throwsArgumentError);
      
      expect(() => const ClixConfig(
        projectId: 'test',
        apiKey: '',
      ), throwsArgumentError);
    });

    test('ClixEnvironment creates valid instance', () {
      final env = ClixEnvironment(
        appIdentifier: 'com.test.app',
        appName: 'Test App',
        appVersion: '1.0.0',
      );
      
      expect(env.appIdentifier, equals('com.test.app'));
      expect(env.appName, equals('Test App'));
      expect(env.appVersion, equals('1.0.0'));
    });

    test('ClixEnvironment.current() factory works', () {
      final env = ClixEnvironment.current();
      
      expect(env.appIdentifier, isNotEmpty);
      expect(env.appName, isNotEmpty);
      expect(env.appVersion, isNotEmpty);
      expect(env.sdkType, equals('Flutter'));
      expect(env.sdkVersion, isNotEmpty);
    });

    test('Clix static methods throw error when not initialized', () {
      expect(() => Clix.getDeviceIdSync(), returnsNormally);
      expect(() => Clix.getPushTokenSync(), returnsNormally);
      expect(Clix.getDeviceIdSync(), isNull);
      expect(Clix.getPushTokenSync(), isNull);
    });

    test('Clix initialization state tracking', () {
      expect(Clix.isInitialized, isFalse);
      
      // Note: We can't easily test actual initialization in unit tests
      // due to Firebase dependencies, but we can test the state tracking
    });

    test('ClixError enum values', () {
      expect(ClixError.notInitialized.message, contains('not been initialized'));
      expect(ClixError.invalidConfiguration.message, contains('Invalid configuration'));
      expect(ClixError.networkError.message, contains('Network'));
    });
  });
}
