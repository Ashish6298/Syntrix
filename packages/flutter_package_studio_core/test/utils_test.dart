import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';

class MockPlatformUtils extends Mock implements PlatformUtils {}

class MockFileUtils extends Mock implements FileUtils {}

void main() {
  group('StringUtils Tests', () {
    test('capitalize', () {
      expect(StringUtils.capitalize(''), '');
      expect(StringUtils.capitalize('a'), 'A');
      expect(StringUtils.capitalize('hello'), 'Hello');
      expect(StringUtils.capitalize('Hello'), 'Hello');
    });

    test('splitWords', () {
      expect(StringUtils.splitWords(''), isEmpty);
      expect(StringUtils.splitWords('helloWorld'), ['hello', 'World']);
      expect(StringUtils.splitWords('hello_world-test'),
          ['hello', 'world', 'test']);
      expect(StringUtils.splitWords('HTTPClient'), ['HTTP', 'Client']);
    });

    test('casing conversions', () {
      const sample = 'hello_world-test Casing';
      expect(StringUtils.toCamelCase(sample), 'helloWorldTestCasing');
      expect(StringUtils.toSnakeCase(sample), 'hello_world_test_casing');
      expect(StringUtils.toKebabCase(sample), 'hello-world-test-casing');
      expect(StringUtils.toPascalCase(sample), 'HelloWorldTestCasing');
    });
  });

  group('VersionUtils Tests', () {
    test('isValid semver validation', () {
      expect(VersionUtils.isValid('1.0.0'), isTrue);
      expect(VersionUtils.isValid('v1.0.0'), isTrue);
      expect(VersionUtils.isValid('0.0.1-alpha.1'), isTrue);
      expect(VersionUtils.isValid('1.0.0+build.1'), isTrue);
      expect(VersionUtils.isValid('1.0.0-beta+exp.sha.5114f85'), isTrue);

      expect(VersionUtils.isValid(''), isFalse);
      expect(VersionUtils.isValid('1'), isFalse);
      expect(VersionUtils.isValid('1.0'), isFalse);
      expect(VersionUtils.isValid('1.0.0.0'), isFalse);
      expect(VersionUtils.isValid('a.b.c'), isFalse);
    });

    test('compare versions', () {
      // Equality
      expect(VersionUtils.compare('1.0.0', '1.0.0'), 0);
      expect(VersionUtils.compare('v1.0.0', '1.0.0'), 0);

      // Core versions
      expect(VersionUtils.compare('2.0.0', '1.9.9'), greaterThan(0));
      expect(VersionUtils.compare('1.1.0', '1.0.9'), greaterThan(0));
      expect(VersionUtils.compare('1.0.1', '1.0.0'), greaterThan(0));
      expect(VersionUtils.compare('1.0.0', '2.0.0'), lessThan(0));

      // Pre-release versions
      expect(VersionUtils.compare('1.0.0-alpha', '1.0.0'), lessThan(0));
      expect(VersionUtils.compare('1.0.0-alpha', '1.0.0-alpha.1'), lessThan(0));
      expect(VersionUtils.compare('1.0.0-alpha.1', '1.0.0-alpha.beta'),
          lessThan(0));
      expect(VersionUtils.compare('1.0.0-beta', '1.0.0-beta.2'), lessThan(0));
      expect(VersionUtils.compare('1.0.0-beta.11', '1.0.0-beta.2'),
          greaterThan(0));
      expect(
          VersionUtils.compare('1.0.0-rc.1', '1.0.0-beta.11'), greaterThan(0));

      // Argument errors
      expect(
          () => VersionUtils.compare('invalid', '1.0.0'), throwsArgumentError);
      expect(
          () => VersionUtils.compare('1.0.0', 'invalid'), throwsArgumentError);
    });
  });

  group('Mockable utilities works', () {
    test('PlatformUtils mock', () {
      final mock = MockPlatformUtils();
      when(() => mock.isWindows).thenReturn(true);
      when(() => mock.isMac).thenReturn(false);

      expect(mock.isWindows, isTrue);
      expect(mock.isMac, isFalse);
    });

    test('FileUtils mock', () {
      final mock = MockFileUtils();
      when(() => mock.exists('/some/path')).thenReturn(true);
      when(() => mock.readAsString('/some/path')).thenReturn('hello');

      expect(mock.exists('/some/path'), isTrue);
      expect(mock.readAsString('/some/path'), 'hello');
    });
  });
}
