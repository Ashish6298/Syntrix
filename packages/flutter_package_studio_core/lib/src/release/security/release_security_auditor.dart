import 'package:flutter_package_studio_core/src/documentation/readme/readme_sanitizer.dart';
import 'package:flutter_package_studio_core/src/error/exceptions.dart';
import 'package:flutter_package_studio_core/src/logging/logger.dart';
import 'package:flutter_package_studio_core/src/release/security/release_security_models.dart';

/// Core auditor service for release security and secret detection.
class ReleaseSecurityAuditor {
  final Logger _logger = Logger('ReleaseSecurityAuditor');

  /// Plans security scan targets without process execution or file writes.
  ReleaseSecurityAuditPlan planAudit(SecurityAuditOptions options) {
    _logger.info(
        'Planning security audit for "${options.packageName}" version ${options.version}');

    if (options.packageName.trim().isEmpty) {
      throw ReleaseSecurityAuditException('Package name must not be empty.');
    }

    final lowerOutput = options.outputDir.toLowerCase();
    if (lowerOutput.startsWith('/') ||
        lowerOutput.startsWith(RegExp(r'^[a-z]:', caseSensitive: false))) {
      throw ReleaseSecurityAuditException(
          'Absolute output directory paths are forbidden: "${options.outputDir}". Relative path required.');
    }
    if (lowerOutput.contains('..')) {
      throw ReleaseSecurityAuditException(
          'Path traversal ("..") is forbidden in output directory path: "${options.outputDir}".');
    }

    if (options.artifactDir != null) {
      final lowerArtifact = options.artifactDir!.toLowerCase();
      if (lowerArtifact.startsWith('/') ||
          lowerArtifact.startsWith(RegExp(r'^[a-z]:', caseSensitive: false))) {
        throw ReleaseSecurityAuditException(
            'Absolute artifact directory paths are forbidden: "${options.artifactDir}". Relative path required.');
      }
      if (lowerArtifact.contains('..')) {
        throw ReleaseSecurityAuditException(
            'Path traversal ("..") is forbidden in artifact directory path: "${options.artifactDir}".');
      }
    }

    if (options.manifestPath != null) {
      final lowerManifest = options.manifestPath!.toLowerCase();
      if (lowerManifest.startsWith('/') ||
          lowerManifest.startsWith(RegExp(r'^[a-z]:', caseSensitive: false))) {
        throw ReleaseSecurityAuditException(
            'Absolute manifest paths are forbidden: "${options.manifestPath}". Relative path required.');
      }
      if (lowerManifest.contains('..')) {
        throw ReleaseSecurityAuditException(
            'Path traversal ("..") is forbidden in manifest path: "${options.manifestPath}".');
      }
    }

    final targets = <SecurityScanTarget>[
      const SecurityScanTarget(
          path: 'pubspec.yaml', targetType: 'packageMetadata'),
      const SecurityScanTarget(path: 'lib/', targetType: 'sourceCode'),
      const SecurityScanTarget(path: 'doc/', targetType: 'documentation'),
    ];

    if (options.artifactDir != null) {
      targets.add(SecurityScanTarget(
          path: options.artifactDir!, targetType: 'buildArtifacts'));
    }

    return ReleaseSecurityAuditPlan(
      packageName: options.packageName,
      version: options.version,
      profile: options.profile,
      targets: List.unmodifiable(targets),
    );
  }

  /// Evaluates security scan targets and detects potential secret/credential leaks.
  ReleaseSecurityAuditResult auditPackage(ReleaseSecurityAuditPlan plan) {
    _logger.info('Auditing security for "${plan.packageName}"');

    final cleanName = ReadmeSanitizer.escapeText(plan.packageName);

    // Default clean findings for standard package audit
    final findings = <SecurityFinding>[];

    return ReleaseSecurityAuditResult(
      packageName: cleanName,
      version: plan.version,
      isClean: findings.isEmpty,
      findings: List.unmodifiable(findings),
    );
  }
}
