/// Single authority for synthesising upstream checks, evaluating new security signals, and classifying plugin trust (Phase 7.14).
library;

import 'dart:io' as io;
import 'package:syntrix/src/plugin/configuration/plugin_configuration_models.dart';
import 'package:syntrix/src/plugin/contract/plugin_contract_models.dart';
import 'package:syntrix/src/plugin/contract/plugin_contract_validator.dart';
import 'package:syntrix/src/plugin/dependency/plugin_dependency_resolver.dart';
import 'package:syntrix/src/plugin/permission/plugin_permission_gate.dart';
import 'package:syntrix/src/plugin/permission/plugin_permission_models.dart';
import 'package:syntrix/src/plugin/trust/plugin_trust_models.dart';
import 'package:path/path.dart' as p;

/// Single authority for plugin trust and security classification.
class PluginTrustGate {
  final PluginContractValidator _contractValidator;
  final PluginPermissionGate _permissionGate;
  final PluginDependencyResolver _dependencyResolver;

  PluginTrustGate({
    PluginContractValidator? contractValidator,
    PluginPermissionGate? permissionGate,
    PluginDependencyResolver? dependencyResolver,
  })  : _contractValidator = contractValidator ?? PluginContractValidator(),
        _permissionGate = permissionGate ?? PluginPermissionGate(),
        _dependencyResolver = dependencyResolver ?? PluginDependencyResolver();

  /// Known verified publishers or provenance sources.
  static const Set<String> verifiedAuthors = {
    'FPS Core Team',
    'Flutter Package Studio',
    'Official Flutter Team',
  };

  /// Disallowed or suspicious file extensions (native binaries, compiled libraries, executables).
  static const Set<String> suspiciousExtensions = {
    '.exe',
    '.dll',
    '.so',
    '.dylib',
    '.bin',
    '.cmd',
    '.bat',
    '.ps1',
    '.sh',
    '.vbs',
  };

  /// Evaluates the complete trust classification of a plugin.
  ///
  /// Combines:
  /// 1. Upstream Contract Validation (Phase 7.1)
  /// 2. Upstream Permission Approval (Phase 7.8)
  /// 3. Upstream Dependency Graph Validity (Phase 7.6)
  /// 4. Manifest Integrity Check (Cryptographic Checksum)
  /// 5. Unsafe Configuration Detection (Dangerous Permission combinations / Injection risks)
  /// 6. Suspicious Executable / Resource Inspection (Non-executing directory inspection)
  /// 7. Dependency Trust Propagation (Inherited trust from dependency chain)
  /// 8. Author Provenance Verification
  PluginTrustClassification evaluateTrust({
    required PluginManifest manifest,
    List<PluginManifest> dependencyManifests = const [],
    String? manifestRawContent,
    String? expectedChecksum,
    String? pluginDirectoryPath,
    RuntimeConfiguration? configuration,
    Map<String, PluginTrustLevel> dependencyTrustMap = const {},
    bool forceAmbiguity = false,
  }) {
    final findings = <TrustFinding>[];
    final pluginId = manifest.id.value;

    // ─────────────────────────────────────────────────────────────────────────
    // 1. Upstream Contract Validation (Phase 7.1)
    // ─────────────────────────────────────────────────────────────────────────
    final contractRes = _contractValidator.validateRawJson(manifest.toJson());
    if (!contractRes.isValid) {
      findings.add(TrustFinding(
        signalType: TrustSignalType.contractValidation,
        status: TrustSignalStatus.failed,
        checkName: 'Contract Schema & Constraints',
        description:
            'Failed contract validation: ${contractRes.violations.join("; ")}',
        remediation:
            'Fix plugin manifest to adhere to the Phase 7.1 specification.',
      ));

      return PluginTrustClassification(
        pluginId: pluginId,
        version: manifest.version,
        trustLevel: PluginTrustLevel.invalid,
        findings: findings,
        summary:
            'Plugin rejected as INVALID due to contract validation failures.',
      );
    } else {
      findings.add(const TrustFinding(
        signalType: TrustSignalType.contractValidation,
        status: TrustSignalStatus.passed,
        checkName: 'Contract Schema & Constraints',
        description:
            'Plugin manifest passes all Phase 7.1 structural and constraint rules.',
      ));
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 2. Manifest Integrity Check (Cryptographic Checksum / Tamper Detection)
    // ─────────────────────────────────────────────────────────────────────────
    if (manifestRawContent != null && expectedChecksum != null) {
      final actualChecksum =
          PluginTrustClassification.computeManifestChecksum(manifestRawContent);
      if (actualChecksum != expectedChecksum) {
        findings.add(TrustFinding(
          signalType: TrustSignalType.manifestIntegrity,
          status: TrustSignalStatus.failed,
          checkName: 'Manifest Cryptographic Checksum',
          description:
              'Manifest integrity mismatch. Expected "$expectedChecksum", got "$actualChecksum". Possible tampering or corruption.',
          remediation:
              'Verify manifest signature and ensure files were not modified after release.',
        ));

        return PluginTrustClassification(
          pluginId: pluginId,
          version: manifest.version,
          trustLevel: PluginTrustLevel.blocked,
          findings: findings,
          summary:
              'Plugin is BLOCKED due to manifest cryptographic integrity mismatch.',
        );
      } else {
        findings.add(const TrustFinding(
          signalType: TrustSignalType.manifestIntegrity,
          status: TrustSignalStatus.passed,
          checkName: 'Manifest Cryptographic Checksum',
          description:
              'Manifest content matches declared cryptographic SHA-256 signature.',
        ));
      }
    } else {
      findings.add(const TrustFinding(
        signalType: TrustSignalType.manifestIntegrity,
        status: TrustSignalStatus.skipped,
        checkName: 'Manifest Cryptographic Checksum',
        description: 'No external manifest checksum supplied for comparison.',
      ));
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 3. Upstream Permission Authorization Check (Phase 7.8)
    // ─────────────────────────────────────────────────────────────────────────
    bool permissionDenied = false;
    for (final raw in manifest.securityRequirements.permissions) {
      final perm = PluginPermission.tryParse(raw);
      if (perm != null) {
        final approved = _permissionGate.check(
          manifest: manifest,
          permission: perm,
          operationAttempted: 'TrustGate.evaluateTrust',
        );
        if (!approved) {
          permissionDenied = true;
          findings.add(TrustFinding(
            signalType: TrustSignalType.permissionAuthorization,
            status: TrustSignalStatus.failed,
            checkName: 'Permission Gate Approval: ${perm.wireName}',
            description:
                'Permission "${perm.wireName}" was declared but is not approved in PermissionGate.',
            remediation:
                'Grant explicit permission approval via PluginPermissionGate before activation.',
          ));
        } else {
          findings.add(TrustFinding(
            signalType: TrustSignalType.permissionAuthorization,
            status: TrustSignalStatus.passed,
            checkName: 'Permission Gate Approval: ${perm.wireName}',
            description:
                'Permission "${perm.wireName}" is declared and approved.',
          ));
        }
      }
    }

    if (permissionDenied) {
      return PluginTrustClassification(
        pluginId: pluginId,
        version: manifest.version,
        trustLevel: PluginTrustLevel.blocked,
        findings: findings,
        summary:
            'Plugin is BLOCKED due to unapproved permission requirements in PermissionGate.',
      );
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 4. Upstream Dependency Resolution & Trust Propagation (Phase 7.6)
    // ─────────────────────────────────────────────────────────────────────────
    bool hasBlockedDependency = false;
    bool hasRestrictedDependency = false;

    if (manifest.dependencies.isNotEmpty) {
      final allManifests = [manifest, ...dependencyManifests];
      // Only invoke dependency resolver if target dependencies manifests are supplied or we want graph resolution
      if (dependencyManifests.isNotEmpty) {
        final depRes = _dependencyResolver.resolveDependencies(allManifests);
        if (!depRes.isCompatible) {
          findings.add(TrustFinding(
            signalType: TrustSignalType.dependencyTrust,
            status: TrustSignalStatus.failed,
            checkName: 'Dependency Resolution',
            description:
                'Dependency resolution failed: ${depRes.findings.map((f) => f.message).join("; ")}',
            remediation:
                'Resolve dependency version conflicts or circular references.',
          ));

          return PluginTrustClassification(
            pluginId: pluginId,
            version: manifest.version,
            trustLevel: PluginTrustLevel.blocked,
            findings: findings,
            summary:
                'Plugin is BLOCKED due to unresolvable or conflicting dependencies.',
          );
        }
      }

      // Check dependency trust ratings
      for (final dep in manifest.dependencies) {
        final depTrust = dependencyTrustMap[dep.name];
        if (depTrust == PluginTrustLevel.blocked ||
            depTrust == PluginTrustLevel.invalid) {
          hasBlockedDependency = true;
          findings.add(TrustFinding(
            signalType: TrustSignalType.dependencyTrust,
            status: TrustSignalStatus.failed,
            checkName: 'Dependency Trust: ${dep.name}',
            description: 'Plugin depends on "${dep.name}" which is $depTrust.',
            remediation: 'Remove or replace the blocked dependency.',
          ));
        } else if (depTrust == PluginTrustLevel.restricted) {
          hasRestrictedDependency = true;
          findings.add(TrustFinding(
            signalType: TrustSignalType.dependencyTrust,
            status: TrustSignalStatus.riskWarning,
            checkName: 'Dependency Trust: ${dep.name}',
            description: depTrust == null
                ? 'Dependency "${dep.name}" has unverified / unknown trust classification.'
                : 'Dependency "${dep.name}" is RESTRICTED, propagating risk to parent.',
            remediation: 'Audit and approve the untrusted dependency.',
          ));
        } else {
          findings.add(TrustFinding(
            signalType: TrustSignalType.dependencyTrust,
            status: TrustSignalStatus.passed,
            checkName: 'Dependency Trust: ${dep.name}',
            description:
                'Dependency "${dep.name}" is trusted/validated ($depTrust).',
          ));
        }
      }
    } else {
      findings.add(const TrustFinding(
        signalType: TrustSignalType.dependencyTrust,
        status: TrustSignalStatus.passed,
        checkName: 'Dependency Graph',
        description:
            'Plugin has zero external dependencies (no trust chain dependencies).',
      ));
    }

    if (hasBlockedDependency) {
      return PluginTrustClassification(
        pluginId: pluginId,
        version: manifest.version,
        trustLevel: PluginTrustLevel.blocked,
        findings: findings,
        summary:
            'Plugin is BLOCKED because it depends on one or more blocked/invalid plugins.',
      );
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 5. Unsafe Configuration Detection (Heuristic Risk Analysis)
    // ─────────────────────────────────────────────────────────────────────────
    bool hasUnsafeConfigRisk = false;

    // Check high-risk permission combinations: process.execute + network.access
    final declaredPermissions = manifest.securityRequirements.permissions;
    if (declaredPermissions.contains('process.execute') &&
        declaredPermissions.contains('network.access')) {
      hasUnsafeConfigRisk = true;
      findings.add(const TrustFinding(
        signalType: TrustSignalType.configurationSafety,
        status: TrustSignalStatus.riskWarning,
        checkName: 'Dangerous Permission Combination',
        description:
            'Plugin declares both "process.execute" and "network.access". This combination presents an elevated remote-code-execution risk.',
        remediation:
            'Restrict plugin capabilities or require operator acknowledgment before running.',
      ));
    }

    // Check config schema properties for command injection or path traversal vectors
    for (final prop in manifest.configSchema.properties) {
      final keyLower = prop.key.toLowerCase();
      if (keyLower.contains('cmd') ||
          keyLower.contains('exec') ||
          keyLower.contains('command') ||
          keyLower.contains('script') ||
          keyLower.contains('shell')) {
        hasUnsafeConfigRisk = true;
        findings.add(TrustFinding(
          signalType: TrustSignalType.configurationSafety,
          status: TrustSignalStatus.riskWarning,
          checkName: 'Command Execution Config Property: "${prop.key}"',
          description:
              'Configuration schema exposes executable command property "${prop.key}" which may allow arbitrary shell injection.',
          remediation:
              'Use fixed service contributions instead of raw execution parameters.',
        ));
      }
    }

    // Check runtime configuration values for path traversal strings
    if (configuration != null) {
      for (final entry in configuration.values.entries) {
        final valStr = entry.value.toString();
        if (valStr.contains('../') || valStr.contains(r'..\')) {
          hasUnsafeConfigRisk = true;
          findings.add(TrustFinding(
            signalType: TrustSignalType.configurationSafety,
            status: TrustSignalStatus.riskWarning,
            checkName: 'Path Traversal Config Value: "${entry.key}"',
            description:
                'Runtime configuration contains directory traversal sequences ("..") in property "${entry.key}".',
            remediation:
                'Sanitize runtime configuration values to remove path traversal sequences.',
          ));
        }
      }
    }

    if (!hasUnsafeConfigRisk) {
      findings.add(const TrustFinding(
        signalType: TrustSignalType.configurationSafety,
        status: TrustSignalStatus.passed,
        checkName: 'Configuration Safety',
        description:
            'No high-risk permission combinations or injection vectors detected in configuration schema.',
      ));
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 6. Suspicious Executable / Resource Inspection (Non-Executing)
    // ─────────────────────────────────────────────────────────────────────────
    bool hasSuspiciousResources = false;
    if (pluginDirectoryPath != null) {
      final dir = io.Directory(pluginDirectoryPath);
      if (dir.existsSync()) {
        try {
          final entities = dir.listSync(recursive: true, followLinks: false);
          for (final entity in entities) {
            if (entity is io.File) {
              final ext = p.extension(entity.path).toLowerCase();
              if (suspiciousExtensions.contains(ext)) {
                hasSuspiciousResources = true;
                findings.add(TrustFinding(
                  signalType: TrustSignalType.resourceSafety,
                  status: TrustSignalStatus.riskWarning,
                  checkName:
                      'Suspicious Native Executable / Script: "${p.basename(entity.path)}"',
                  description:
                      'Plugin directory contains unexpected binary or script executable resource "${p.basename(entity.path)}".',
                  remediation:
                      'Remove compiled binaries or native scripts from plugin bundle.',
                ));
              }
            }
          }
        } catch (_) {
          // If directory listing fails, fail closed
          hasSuspiciousResources = true;
        }
      }
    }

    // Check entry point anomalies
    if (manifest.entryPoint != null) {
      final ep = manifest.entryPoint!.toLowerCase();
      if (ep.startsWith('/') ||
          ep.contains('..') ||
          ep.endsWith('.exe') ||
          ep.endsWith('.dll')) {
        hasSuspiciousResources = true;
        findings.add(TrustFinding(
          signalType: TrustSignalType.resourceSafety,
          status: TrustSignalStatus.riskWarning,
          checkName: 'Anomalous Entry Point: "${manifest.entryPoint}"',
          description:
              'Plugin declares an entry point pointing to an unusual or dangerous path.',
          remediation:
              'Use a relative standard Dart entry point within the plugin root.',
        ));
      }
    }

    if (!hasSuspiciousResources) {
      findings.add(const TrustFinding(
        signalType: TrustSignalType.resourceSafety,
        status: TrustSignalStatus.passed,
        checkName: 'Resource Safety',
        description:
            'Non-executing inspection detected no unexpected compiled binaries, native libraries, or anomalous entry points.',
      ));
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 7. Provenance Verification
    // ─────────────────────────────────────────────────────────────────────────
    final isVerifiedAuthor =
        verifiedAuthors.contains(manifest.author.name.trim());
    if (isVerifiedAuthor) {
      findings.add(TrustFinding(
        signalType: TrustSignalType.provenance,
        status: TrustSignalStatus.passed,
        checkName: 'Author Provenance',
        description:
            'Author "${manifest.author.name}" is a verified trusted publisher.',
      ));
    } else {
      findings.add(TrustFinding(
        signalType: TrustSignalType.provenance,
        status: TrustSignalStatus.skipped,
        checkName: 'Author Provenance',
        description:
            'Author "${manifest.author.name}" is unverified / third-party.',
      ));
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 8. Fail-Closed On Ambiguity & Final Classification Synthesis
    // ─────────────────────────────────────────────────────────────────────────
    if (forceAmbiguity) {
      findings.add(const TrustFinding(
        signalType: TrustSignalType.manifestIntegrity,
        status: TrustSignalStatus.riskWarning,
        checkName: 'Ambiguous Security Signal',
        description:
            'Signal evaluation encountered uninterpretable state. Failing closed to RESTRICTED.',
      ));
      return PluginTrustClassification(
        pluginId: pluginId,
        version: manifest.version,
        trustLevel: PluginTrustLevel.restricted,
        findings: findings,
        summary:
            'Plugin classified as RESTRICTED due to fail-closed bias on ambiguous security signal.',
      );
    }

    // Determine final classification
    PluginTrustLevel finalLevel;
    String summary;

    if (hasUnsafeConfigRisk ||
        hasSuspiciousResources ||
        hasRestrictedDependency) {
      finalLevel = PluginTrustLevel.restricted;
      summary =
          'Plugin classified as RESTRICTED due to heuristic risk signals (unsafe configuration, suspicious resources, or untrusted dependencies). Requires operator acknowledgment to activate.';
    } else if (isVerifiedAuthor) {
      finalLevel = PluginTrustLevel.trusted;
      summary =
          'Plugin classified as TRUSTED: passes all hard checks with zero risk signals and verified publisher provenance.';
    } else {
      finalLevel = PluginTrustLevel.validated;
      summary =
          'Plugin classified as VALIDATED: passes all hard contract and security checks with zero risk signals (unverified author provenance).';
    }

    return PluginTrustClassification(
      pluginId: pluginId,
      version: manifest.version,
      trustLevel: finalLevel,
      findings: findings,
      summary: summary,
    );
  }
}
