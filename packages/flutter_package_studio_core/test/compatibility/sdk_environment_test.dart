import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:test/test.dart';

void main() {
  group('SdkEnvironment Tests', () {
    test(
        'MockSdkEnvironment properties are populated correctly without OS/process read',
        () {
      final env = MockSdkEnvironment(
        dartVersion: '3.6.0',
        flutterVersion: '3.24.0',
        operatingSystem: 'windows',
      );

      expect(env.dartVersion, equals('3.6.0'));
      expect(env.flutterVersion, equals('3.24.0'));
      expect(env.operatingSystem, equals('windows'));
      expect(env.isFlutterAvailable, isTrue);
      expect(env.supportsPlatform('WINDOWS'), isTrue);
      expect(env.supportsPlatform('linux'), isFalse);
    });

    test(
        'MockSdkEnvironment without Flutter returns isFlutterAvailable = false',
        () {
      final env = MockSdkEnvironment(
        dartVersion: '3.5.0',
        operatingSystem: 'macos',
      );

      expect(env.flutterVersion, isNull);
      expect(env.isFlutterAvailable, isFalse);
    });

    test('Predefined standard environments match expected defaults', () {
      expect(MockSdkEnvironment.standard.dartVersion, equals('3.5.0'));
      expect(MockSdkEnvironment.standard.flutterVersion, equals('3.22.0'));
      expect(MockSdkEnvironment.dartOnly.isFlutterAvailable, isFalse);
    });
  });
}
