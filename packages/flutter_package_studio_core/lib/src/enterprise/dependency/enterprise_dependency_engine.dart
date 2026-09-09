/// Central Enterprise Dependency Governance Engine for Phase 9.6.
library;

import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';
import 'package:flutter_package_studio_core/src/logging/logger.dart';
import 'package:flutter_package_studio_core/src/enterprise/dependency/enterprise_dependency_models.dart';

/// Central Enterprise Dependency Governance Engine.
///
/// Features:
/// 1. Evaluates direct and dev dependencies from `pubspec.yaml` without duplicate discovery.
/// 2. Enforces allowed, restricted, and blocked package registries.
/// 3. Checks for license compliance (e.g. GPL vs. MIT/Apache).
/// 4. Disallows path/git dependency leaks into production releases.
/// 5. Flags known high-risk or vulnerable dependencies.
class EnterpriseDependencyGovernanceEngine {
  final Logger _logger = Logger('EnterpriseDependencyGovernanceEngine');
  final String _projectRoot;

  String get projectRoot => _projectRoot;

  EnterpriseDependencyGovernanceEngine({
    required String projectRoot,
  }) : _projectRoot = p.normalize(projectRoot);

  /// Evaluates package dependencies against an enterprise dependency policy.
  Future<DependencyGovernanceResult> auditDependencies({
    String? relativePackagePath,
    EnterpriseDependencyPolicy policy = const EnterpriseDependencyPolicy(),
    Map<String, String>? packageLicenses,
    List<String>? knownVulnerablePackages,
    DateTime? executionTimestamp,
  }) async {
    final sw = Stopwatch()..start();
    final now = executionTimestamp ?? DateTime.now();

    final targetDir =
        relativePackagePath != null && relativePackagePath.isNotEmpty
            ? Directory(p.join(_projectRoot, relativePackagePath))
            : Directory(_projectRoot);

    final pubspecFile = File(p.join(targetDir.path, 'pubspec.yaml'));
    if (!pubspecFile.existsSync()) {
      sw.stop();
      return DependencyGovernanceResult(
        isCompliant: false,
        isBlocked: true,
        targetPackageName: 'unknown',
        totalDependenciesAnalyzed: 0,
        findings: [
          const DependencyGovernanceFinding(
            packageName: 'pubspec.yaml',
            declaredVersion: 'missing',
            dependencyType: DependencyType.direct,
            status: DependencyGovernanceStatus.blocked,
            reason: 'Missing pubspec.yaml in target project root.',
            isBlocking: true,
          ),
        ],
        approvedCount: 0,
        restrictedCount: 0,
        blockedCount: 1,
        vulnerableCount: 0,
        licenseViolationCount: 0,
        summary: 'Dependency audit failed: pubspec.yaml not found.',
        durationMs: sw.elapsedMilliseconds,
        timestamp: now,
      );
    }

    final findings = <DependencyGovernanceFinding>[];
    String packageName = 'unknown';

    try {
      final rawYaml = pubspecFile.readAsStringSync();
      final doc = loadYaml(rawYaml);

      if (doc is Map) {
        packageName = doc['name']?.toString() ?? 'unknown';

        final deps = doc['dependencies'];
        if (deps is Map) {
          _evaluateDependencyMap(
            deps,
            DependencyType.direct,
            policy,
            findings,
            packageLicenses,
            knownVulnerablePackages,
          );
        }

        final devDeps = doc['dev_dependencies'];
        if (devDeps is Map) {
          _evaluateDependencyMap(
            devDeps,
            DependencyType.dev,
            policy,
            findings,
            packageLicenses,
            knownVulnerablePackages,
          );
        }
      }
    } catch (e) {
      _logger
          .error('Failed to parse pubspec.yaml for dependency governance: $e');
    }

    sw.stop();

    final totalDeps = findings.length;
    final approvedCount = findings
        .where((f) => f.status == DependencyGovernanceStatus.approved)
        .length;
    final restrictedCount = findings
        .where((f) => f.status == DependencyGovernanceStatus.restricted)
        .length;
    final blockedCount = findings
        .where((f) => f.status == DependencyGovernanceStatus.blocked)
        .length;
    final vulnerableCount = findings
        .where((f) => f.status == DependencyGovernanceStatus.vulnerable)
        .length;
    final licenseViolationCount = findings
        .where((f) => f.status == DependencyGovernanceStatus.licenseViolation)
        .length;

    final isBlocked = findings.any((f) => f.isBlocking);
    final isCompliant =
        !isBlocked && licenseViolationCount == 0 && vulnerableCount == 0;

    final summary = isCompliant
        ? 'Dependency governance audit passed: $totalDeps dependencies analyzed, 0 blocking violations.'
        : 'Dependency governance audit failed: $blockedCount blocked, $vulnerableCount vulnerable, $licenseViolationCount license violation(s).';

    return DependencyGovernanceResult(
      isCompliant: isCompliant,
      isBlocked: isBlocked,
      targetPackageName: packageName,
      totalDependenciesAnalyzed: totalDeps,
      findings: findings,
      approvedCount: approvedCount,
      restrictedCount: restrictedCount,
      blockedCount: blockedCount,
      vulnerableCount: vulnerableCount,
      licenseViolationCount: licenseViolationCount,
      summary: summary,
      durationMs: sw.elapsedMilliseconds,
      timestamp: now,
    );
  }

  void _evaluateDependencyMap(
    Map<dynamic, dynamic> depMap,
    DependencyType type,
    EnterpriseDependencyPolicy policy,
    List<DependencyGovernanceFinding> findings,
    Map<String, String>? packageLicenses,
    List<String>? knownVulnerablePackages,
  ) {
    for (final entry in depMap.entries) {
      final name = entry.key.toString();
      final val = entry.value;
      final versionStr =
          val is String ? val : (val is Map ? val.toString() : 'any');

      // 1. Check for Path / Git dependencies in release policy
      if (val is Map) {
        if (val.containsKey('path') && policy.blockPathDependencies) {
          findings.add(DependencyGovernanceFinding(
            packageName: name,
            declaredVersion: versionStr,
            dependencyType: type,
            status: DependencyGovernanceStatus.blocked,
            reason:
                'Path dependency is disallowed in enterprise release packages.',
            recommendation:
                'Publish dependency to private enterprise repository or reference hosted package.',
            isBlocking: true,
          ));
          continue;
        }

        if (val.containsKey('git') && policy.blockGitDependencies) {
          findings.add(DependencyGovernanceFinding(
            packageName: name,
            declaredVersion: versionStr,
            dependencyType: type,
            status: DependencyGovernanceStatus.blocked,
            reason:
                'Git dependency is disallowed in enterprise release packages.',
            recommendation: 'Publish dependency to private hosted repository.',
            isBlocking: true,
          ));
          continue;
        }
      }

      // 2. Check Blocked Packages List
      if (policy.blockedPackages.contains(name)) {
        findings.add(DependencyGovernanceFinding(
          packageName: name,
          declaredVersion: versionStr,
          dependencyType: type,
          status: DependencyGovernanceStatus.blocked,
          reason: 'Package is on the enterprise blocked dependency list.',
          recommendation: 'Replace with approved enterprise alternative.',
          isBlocking: true,
        ));
        continue;
      }

      // 3. Check Known Vulnerable Packages
      if (policy.blockKnownVulnerabilities &&
          knownVulnerablePackages != null &&
          knownVulnerablePackages.contains(name)) {
        findings.add(DependencyGovernanceFinding(
          packageName: name,
          declaredVersion: versionStr,
          dependencyType: type,
          status: DependencyGovernanceStatus.vulnerable,
          advisoryId: 'SEC-DEP-${name.toUpperCase()}',
          reason: 'Package has an active security advisory / vulnerability.',
          recommendation: 'Upgrade to patched upstream version immediately.',
          isBlocking: true,
        ));
        continue;
      }

      // 4. Check License Restrictions
      final license = packageLicenses?[name];
      if (license != null && policy.blockedLicenses.contains(license)) {
        findings.add(DependencyGovernanceFinding(
          packageName: name,
          declaredVersion: versionStr,
          dependencyType: type,
          license: license,
          status: DependencyGovernanceStatus.licenseViolation,
          reason:
              'License "$license" violates enterprise license restriction policy.',
          recommendation:
              'Use a library with permissive licensing (${policy.allowedLicenses.join(", ")}).',
          isBlocking: true,
        ));
        continue;
      }

      // 5. Check Restricted Packages List
      if (policy.restrictedPackages.contains(name)) {
        findings.add(DependencyGovernanceFinding(
          packageName: name,
          declaredVersion: versionStr,
          dependencyType: type,
          license: license,
          status: DependencyGovernanceStatus.restricted,
          reason:
              'Package is classified as restricted; requires security approval before production release.',
          recommendation: 'Obtain security review sign-off.',
          isBlocking: false,
        ));
        continue;
      }

      // 6. Check Approved vs. Unapproved Policy
      if (policy.approvedPackages.contains(name)) {
        findings.add(DependencyGovernanceFinding(
          packageName: name,
          declaredVersion: versionStr,
          dependencyType: type,
          license: license ?? 'MIT',
          status: DependencyGovernanceStatus.approved,
          reason: 'Package is approved for enterprise use.',
          isBlocking: false,
        ));
      } else if (policy.blockUnapprovedPackages) {
        findings.add(DependencyGovernanceFinding(
          packageName: name,
          declaredVersion: versionStr,
          dependencyType: type,
          license: license,
          status: DependencyGovernanceStatus.blocked,
          reason:
              'Package is not in the enterprise approved list (Strict Allowlist Policy).',
          recommendation:
              'Submit dependency for organizational whitelist approval.',
          isBlocking: true,
        ));
      } else {
        findings.add(DependencyGovernanceFinding(
          packageName: name,
          declaredVersion: versionStr,
          dependencyType: type,
          license: license,
          status: DependencyGovernanceStatus.unclassified,
          reason: 'Package is permitted under standard policy.',
          isBlocking: false,
        ));
      }
    }
  }
}
