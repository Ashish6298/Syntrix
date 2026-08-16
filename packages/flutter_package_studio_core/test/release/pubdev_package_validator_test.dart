import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:test/test.dart';

void main() {
  group('PubDevPackageValidator Unit Tests', () {
    late PubDevPackageValidator validator;

    setUp(() {
      validator = PubDevPackageValidator();
    });

    test('Plans pub.dev validation checks and validates config path safety',
        () {
      const options = PubDevValidationOptions(
          packageName: 'awesome_pkg',
          version: '1.0.0',
          configPath: 'pubdev_validation.json');
      final plan = validator.planValidation(options);

      expect(plan.packageName, equals('awesome_pkg'));
      expect(plan.version, equals('1.0.0'));
      expect(plan.checks.length, equals(5));
    });

    test('Evaluates pub.dev validation checks and returns publishable result',
        () {
      const options = PubDevValidationOptions(packageName: 'awesome_pkg');
      final plan = validator.planValidation(options);
      final result = validator.validatePackage(plan);

      expect(result.packageName, equals('awesome_pkg'));
      expect(result.isPublishable, isTrue);
      expect(result.checks.length, equals(5));

      final md = result.toMarkdown();
      expect(md, contains('# Pub.dev Package Validation Report: awesome_pkg'));
      expect(md, contains('READY FOR PUB.DEV'));
    });

    test('Rejects absolute config paths', () {
      const options = PubDevValidationOptions(
          packageName: 'pkg', configPath: '/etc/pubdev.json');
      expect(() => validator.planValidation(options),
          throwsA(isA<PubDevValidationException>()));
    });

    test('Rejects path traversal ".." in config path', () {
      const options = PubDevValidationOptions(
          packageName: 'pkg', configPath: '../pubdev.json');
      expect(() => validator.planValidation(options),
          throwsA(isA<PubDevValidationException>()));
    });

    test('Rejects absolute artifact paths', () {
      const options = PubDevValidationOptions(
          packageName: 'pkg', artifactPath: '/tmp/pkg.tar.gz');
      expect(() => validator.planValidation(options),
          throwsA(isA<PubDevValidationException>()));
    });
  });
}
