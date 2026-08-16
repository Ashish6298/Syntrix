import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:test/test.dart';

void main() {
  group('ReleaseCertificationGate Unit Tests', () {
    late ReleaseCertificationGate gate;

    setUp(() {
      gate = ReleaseCertificationGate();
    });

    test('Plans release certification gates and validates output path safety',
        () {
      const options = ReleaseCertificationOptions(
          packageName: 'awesome_pkg',
          version: '1.0.0',
          outputDir: 'doc/release');
      final plan = gate.planCertification(options);

      expect(plan.packageName, equals('awesome_pkg'));
      expect(plan.version, equals('1.0.0'));
      expect(plan.gates.length, equals(11));
    });

    test('Certifies release and renders Markdown report output', () {
      const options = ReleaseCertificationOptions(packageName: 'awesome_pkg');
      final plan = gate.planCertification(options);
      final result = gate.certifyRelease(plan);

      expect(result.packageName, equals('awesome_pkg'));
      expect(result.isSuccess, isTrue);
      expect(result.overallStatus,
          equals(ReleaseCertificationGateStatus.certified));

      final md = result.toMarkdown();
      expect(
          md,
          contains(
              '# Release Certification & Final Delivery Gate Report: awesome_pkg'));
      expect(md, contains('CERTIFIED FOR FINAL DELIVERY ✓'));
    });

    test(
        'Blocks certification when rollback checksum is tampered or mismatched',
        () {
      const options = ReleaseCertificationOptions(packageName: 'awesome_pkg');
      final plan = gate.planCertification(options,
          rollbackChecksum: 'invalid_tampered_checksum');
      final result = gate.certifyRelease(plan);

      expect(result.isSuccess, isFalse);
      expect(
          result.overallStatus, equals(ReleaseCertificationGateStatus.failed));

      final rollbackGate =
          result.gates.firstWhere((g) => g.id == 'GATE-11-ROLLBACK');
      expect(
          rollbackGate.status, equals(ReleaseCertificationGateStatus.failed));
      expect(rollbackGate.details,
          contains('TAMPERED OR MISMATCHED ROLLBACK CHECKSUM DETECTED'));
    });

    test('Rejects absolute output directory paths', () {
      const options = ReleaseCertificationOptions(
          packageName: 'pkg', outputDir: '/etc/cert');
      expect(() => gate.planCertification(options),
          throwsA(isA<ReleaseCertificationException>()));
    });

    test('Rejects path traversal ".." in output directory', () {
      const options =
          ReleaseCertificationOptions(packageName: 'pkg', outputDir: '../cert');
      expect(() => gate.planCertification(options),
          throwsA(isA<ReleaseCertificationException>()));
    });
  });
}
