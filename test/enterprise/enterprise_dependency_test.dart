import 'dart:io';
import 'package:syntrix/flutter_package_studio_core.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('Phase 9.6 — Enterprise Dependency Governance Tests', () {
    late Directory tempDir;
    late String rootPath;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('fps_enterprise_dep_test_');
      rootPath = tempDir.path;

      // Scaffold project workspace with various dependency profiles
      File(p.join(rootPath, 'pubspec.yaml')).writeAsStringSync('''
name: enterprise_governed_pkg
version: 1.0.0
environment:
  sdk: '>=3.5.0 <4.0.0'
dependencies:
  flutter:
    sdk: flutter
  http: ^1.2.0
  path: ^1.9.0
  package_x: ^0.1.0
  package_y: ^2.0.0
  gpl_helper: ^1.0.0
dev_dependencies:
  flutter_test:
    sdk: flutter
  test: ^1.24.0
''');
    });

    tearDown(() {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 1: Allowed, Restricted, and Blocked Dependency Policy Enforcement
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '1. Dependency Registry Policy: flags approved, restricted, and blocked packages',
        () async {
      final engine =
          EnterpriseDependencyGovernanceEngine(projectRoot: rootPath);

      final policy = const EnterpriseDependencyPolicy(
        approvedPackages: ['flutter', 'flutter_test', 'http', 'path'],
        restrictedPackages: ['package_x'],
        blockedPackages: ['package_y'],
      );

      final result = await engine.auditDependencies(policy: policy);

      expect(result.isBlocked, isTrue); // package_y is blocked
      expect(result.blockedCount, equals(1));
      expect(result.restrictedCount, equals(1));
      expect(result.approvedCount, greaterThanOrEqualTo(3));

      final blockedFinding =
          result.findings.firstWhere((f) => f.packageName == 'package_y');
      expect(blockedFinding.status, equals(DependencyGovernanceStatus.blocked));
      expect(blockedFinding.isBlocking, isTrue);

      final restrictedFinding =
          result.findings.firstWhere((f) => f.packageName == 'package_x');
      expect(restrictedFinding.status,
          equals(DependencyGovernanceStatus.restricted));
      expect(restrictedFinding.isBlocking, isFalse);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 2: License Compliance Enforcement (GPL / AGPL vs. Permissive)
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '2. License Restrictions: blocks GPL/AGPL copyleft libraries in enterprise releases',
        () async {
      final engine =
          EnterpriseDependencyGovernanceEngine(projectRoot: rootPath);

      final policy = const EnterpriseDependencyPolicy(
        allowedLicenses: ['MIT', 'Apache-2.0', 'BSD-3-Clause'],
        blockedLicenses: ['GPL-3.0', 'AGPL-3.0'],
      );

      final licenses = {
        'http': 'Apache-2.0',
        'path': 'BSD-3-Clause',
        'gpl_helper': 'GPL-3.0',
      };

      final result = await engine.auditDependencies(
        policy: policy,
        packageLicenses: licenses,
      );

      expect(result.licenseViolationCount, equals(1));
      final gplFinding =
          result.findings.firstWhere((f) => f.packageName == 'gpl_helper');
      expect(gplFinding.status,
          equals(DependencyGovernanceStatus.licenseViolation));
      expect(gplFinding.isBlocking, isTrue);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 3: Known Vulnerability / Advisory Detection
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '3. Vulnerability Detection: blocks packages with active security advisories',
        () async {
      final engine =
          EnterpriseDependencyGovernanceEngine(projectRoot: rootPath);

      final result = await engine.auditDependencies(
        knownVulnerablePackages: ['http'], // simulate vulnerable package
      );

      expect(result.vulnerableCount, equals(1));
      final vulnFinding =
          result.findings.firstWhere((f) => f.packageName == 'http');
      expect(vulnFinding.status, equals(DependencyGovernanceStatus.vulnerable));
      expect(vulnFinding.advisoryId, equals('SEC-DEP-HTTP'));
      expect(vulnFinding.isBlocking, isTrue);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 4: Path and Git Dependency Leaks
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '4. Release Isolation: blocks path/git dependencies in release candidate pubspec',
        () async {
      // Create pubspec with path and git dependencies
      File(p.join(rootPath, 'pubspec.yaml')).writeAsStringSync('''
name: leak_pkg
version: 1.0.0
dependencies:
  local_core:
    path: ../local_core
  git_tool:
    git:
      url: https://github.com/example/git_tool.git
''');

      final engine =
          EnterpriseDependencyGovernanceEngine(projectRoot: rootPath);
      final result = await engine.auditDependencies();

      expect(result.isBlocked, isTrue);
      expect(
          result.findings
              .any((f) => f.packageName == 'local_core' && f.isBlocking),
          isTrue);
      expect(
          result.findings
              .any((f) => f.packageName == 'git_tool' && f.isBlocking),
          isTrue);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 5: Pure Dual-Format Renderer Conformance
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '5. Renderer Conformance: generates deterministic JSON and Markdown dependency governance reports',
        () async {
      final engine =
          EnterpriseDependencyGovernanceEngine(projectRoot: rootPath);
      final result = await engine.auditDependencies();
      const renderer = EnterpriseDependencyRenderer();

      final json1 = renderer.renderJson(result);
      final json2 = renderer.renderJson(result);
      expect(json1, equals(json2));

      final md = renderer.renderMarkdown(result);
      expect(md, contains('# Enterprise Dependency Governance Report'));
      expect(md, contains('**Target Package**: `enterprise_governed_pkg`'));
      expect(md, contains('## Executive Summary'));
    });
  });
}
