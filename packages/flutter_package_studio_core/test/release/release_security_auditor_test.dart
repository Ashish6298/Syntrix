import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:test/test.dart';

void main() {
  group('ReleaseSecurityAuditor Unit Tests', () {
    late ReleaseSecurityAuditor auditor;

    setUp(() {
      auditor = ReleaseSecurityAuditor();
    });

    test('Plans security audit targets and validates output path safety', () {
      const options = SecurityAuditOptions(
          packageName: 'awesome_pkg',
          version: '1.0.0',
          outputDir: 'doc/release');
      final plan = auditor.planAudit(options);

      expect(plan.packageName, equals('awesome_pkg'));
      expect(plan.version, equals('1.0.0'));
      expect(plan.targets.length, equals(3));
    });

    test('Audits clean package and returns clean security result', () {
      const options = SecurityAuditOptions(packageName: 'awesome_pkg');
      final plan = auditor.planAudit(options);
      final result = auditor.auditPackage(plan);

      expect(result.packageName, equals('awesome_pkg'));
      expect(result.isClean, isTrue);
      expect(result.findings, isEmpty);

      final md = result.toMarkdown();
      expect(md,
          contains('# Release Security & Secret Audit Report: awesome_pkg'));
      expect(md, contains('CLEAN ✓'));
    });

    test('Rejects absolute output directory paths', () {
      const options =
          SecurityAuditOptions(packageName: 'pkg', outputDir: '/etc/security');
      expect(() => auditor.planAudit(options),
          throwsA(isA<ReleaseSecurityAuditException>()));
    });

    test('Rejects path traversal ".." in output directory', () {
      const options =
          SecurityAuditOptions(packageName: 'pkg', outputDir: '../security');
      expect(() => auditor.planAudit(options),
          throwsA(isA<ReleaseSecurityAuditException>()));
    });

    test('Rejects absolute artifact directory paths', () {
      const options = SecurityAuditOptions(
          packageName: 'pkg', artifactDir: '/tmp/artifacts');
      expect(() => auditor.planAudit(options),
          throwsA(isA<ReleaseSecurityAuditException>()));
    });
  });
}
