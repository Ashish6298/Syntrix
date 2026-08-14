import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:test/test.dart';

void main() {
  group('CompatibilityPolicy Tests', () {
    test('Policy flags match specified strictness matrix', () {
      expect(CompatibilityPolicy.permissive.checksDartSdk, isTrue);
      expect(CompatibilityPolicy.permissive.checksFlutterSdk, isFalse);
      expect(CompatibilityPolicy.permissive.checksProjectType, isFalse);
      expect(CompatibilityPolicy.permissive.checksPlatforms, isFalse);
      expect(CompatibilityPolicy.permissive.checksCapabilities, isFalse);
      expect(CompatibilityPolicy.permissive.checksDependencies, isFalse);
      expect(CompatibilityPolicy.permissive.warningsAreErrors, isFalse);

      expect(CompatibilityPolicy.standard.checksFlutterSdk, isTrue);
      expect(CompatibilityPolicy.standard.checksProjectType, isTrue);
      expect(CompatibilityPolicy.standard.checksPlatforms, isFalse);

      expect(CompatibilityPolicy.strict.checksPlatforms, isTrue);
      expect(CompatibilityPolicy.strict.checksCapabilities, isTrue);
      expect(CompatibilityPolicy.strict.checksDependencies, isTrue);
      expect(CompatibilityPolicy.strict.warningsAreErrors, isFalse);

      expect(CompatibilityPolicy.release.warningsAreErrors, isTrue);
    });

    test('Release policy promotes warnings to errors', () {
      final warning = CompatibilityIssue.metadataWarning('Test warning');
      final error = CompatibilityIssue.dartSdkError('>=3.0.0', '2.19.0');

      final issues = [warning, error];
      final promoted = CompatibilityPolicy.release.applyPromotions(issues);

      expect(promoted.length, equals(2));
      expect(
          promoted.every((i) => i.severity == CompatibilityIssueSeverity.error),
          isTrue);
      expect(promoted.first.message, contains('[Release policy]'));
    });

    test('fromString parses string representation safely', () {
      expect(CompatibilityPolicyX.fromString('permissive'),
          equals(CompatibilityPolicy.permissive));
      expect(CompatibilityPolicyX.fromString('STANDARD'),
          equals(CompatibilityPolicy.standard));
      expect(CompatibilityPolicyX.fromString('strict'),
          equals(CompatibilityPolicy.strict));
      expect(CompatibilityPolicyX.fromString('release'),
          equals(CompatibilityPolicy.release));
      expect(CompatibilityPolicyX.fromString('unknown'),
          equals(CompatibilityPolicy.standard));
    });
  });
}
