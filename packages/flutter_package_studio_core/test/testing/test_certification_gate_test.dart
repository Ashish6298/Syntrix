import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:test/test.dart';

void main() {
  group('TestCertificationGate Unit Tests', () {
    late TestCertificationGate gate;

    setUp(() {
      gate = TestCertificationGate();
    });

    test('Plans certification evaluation and validates config path safety', () {
      const options = TestCertificationOptions(
          packageName: 'awesome_pkg', configPath: 'test/config.json');
      final plan = gate.planCertification(options);

      expect(plan.packageName, equals('awesome_pkg'));
      expect(plan.configPath, equals('test/config.json'));
    });

    test('Evaluates quality gates and grants certification', () {
      const options = TestCertificationOptions(packageName: 'awesome_pkg');
      final plan = gate.planCertification(options);
      final result = gate.certifyPackage(plan);

      expect(result.packageName, equals('awesome_pkg'));
      expect(result.isCertified, isTrue);
      expect(result.decision, equals(CertificationDecision.certified));
      expect(result.gates.length, equals(4));

      final md = result.toMarkdown();
      expect(
          md, contains('# Test Quality & Certification Report: awesome_pkg'));
      expect(md, contains('CERTIFIED'));
    });

    test('Rejects absolute config paths', () {
      const options = TestCertificationOptions(
          packageName: 'pkg', configPath: '/etc/config.json');
      expect(() => gate.planCertification(options),
          throwsA(isA<TestCertificationException>()));
    });

    test('Rejects path traversal ".." in config path', () {
      const options = TestCertificationOptions(
          packageName: 'pkg', configPath: '../config.json');
      expect(() => gate.planCertification(options),
          throwsA(isA<TestCertificationException>()));
    });
  });
}
