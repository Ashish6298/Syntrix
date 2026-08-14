import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:test/test.dart';

void main() {
  group('SdkVersionConstraint Tests', () {
    test('Wildcard constraint matches any version', () {
      final c1 = SdkVersionConstraint.parse('*');
      final c2 = SdkVersionConstraint.parse('');

      expect(c1.isWildcard, isTrue);
      expect(c2.isWildcard, isTrue);
      expect(c1.isSatisfiedBy('3.5.0'), isTrue);
      expect(c2.isSatisfiedBy('2.19.0'), isTrue);
    });

    test('Range constraints parse and evaluate correctly', () {
      final c = SdkVersionConstraint.parse('>=3.5.0 <4.0.0');

      expect(c.isSatisfiedBy('3.5.0'), isTrue);
      expect(c.isSatisfiedBy('3.22.0'), isTrue);
      expect(c.isSatisfiedBy('3.99.99'), isTrue);
      expect(c.isSatisfiedBy('3.4.9'), isFalse);
      expect(c.isSatisfiedBy('4.0.0'), isFalse);
    });

    test('Caret constraints evaluate major compatibility', () {
      final c = SdkVersionConstraint.parse('^3.5.0');

      expect(c.isSatisfiedBy('3.5.0'), isTrue);
      expect(c.isSatisfiedBy('3.8.0'), isTrue);
      expect(c.isSatisfiedBy('3.4.0'), isFalse);
      expect(c.isSatisfiedBy('4.0.0'), isFalse);
    });

    test('Exact version constraints evaluate strict equality', () {
      final c1 = SdkVersionConstraint.parse('3.5.0');
      final c2 = SdkVersionConstraint.parse('=3.5.0');
      final c3 = SdkVersionConstraint.parse('==3.5.0');

      expect(c1.isSatisfiedBy('3.5.0'), isTrue);
      expect(c2.isSatisfiedBy('3.5.0'), isTrue);
      expect(c3.isSatisfiedBy('3.5.0'), isTrue);

      expect(c1.isSatisfiedBy('3.5.1'), isFalse);
    });

    test('Prerelease versions handling', () {
      final c = SdkVersionConstraint.parse('>=3.5.0-beta.1');
      expect(c.isSatisfiedBy('3.5.0-beta.2'), isTrue);
      expect(c.isSatisfiedBy('3.5.0'), isTrue);
    });

    test('Malformed constraint expression throws InvalidSdkConstraintException',
        () {
      expect(
        () => SdkVersionConstraint.parse('>=abc'),
        throwsA(isA<InvalidSdkConstraintException>()),
      );
      expect(
        () => SdkVersionConstraint.parse('>='),
        throwsA(isA<InvalidSdkConstraintException>()),
      );
      expect(
        () => SdkVersionConstraint.parse('^invalid'),
        throwsA(isA<InvalidSdkConstraintException>()),
      );
    });

    test(
        'Evaluating invalid target version string throws InvalidSdkConstraintException',
        () {
      final c = SdkVersionConstraint.parse('>=3.0.0');
      expect(
        () => c.isSatisfiedBy('invalid_version'),
        throwsA(isA<InvalidSdkConstraintException>()),
      );
      expect(
        () => c.isSatisfiedBy(''),
        throwsA(isA<InvalidSdkConstraintException>()),
      );
    });

    test(
        'isSatisfiedBySafe returns null on invalid version instead of throwing',
        () {
      final c = SdkVersionConstraint.parse('>=3.0.0');
      expect(c.isSatisfiedBySafe('invalid_version'), isNull);
      expect(c.isSatisfiedBySafe('3.5.0'), isTrue);
    });
  });
}
