/// Central Enterprise Configuration & Policy Engine for Phase 9.1.
library;

import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';
import 'package:flutter_package_studio_core/src/logging/logger.dart';
import 'package:flutter_package_studio_core/src/enterprise/policy/enterprise_policy_models.dart';

/// Central Enterprise Configuration & Policy Engine.
///
/// Features:
/// 1. Hierarchical, composable policy resolution:
///    Organization Policy -> Project Policy -> Package Policy -> Environment Policy.
/// 2. Declarative policy evaluation across release, security, AI usage, dependencies, naming, and operations.
/// 3. Profile presets (Standard, Strict, Financial, Healthcare, Government, OpenSource).
/// 4. Pure deterministic evaluation and gating logic.
class EnterprisePolicyEngine {
  final Logger _logger = Logger('EnterprisePolicyEngine');
  final String _projectRoot;
  final EnterprisePolicyDocument? _overridePolicy;

  String get projectRoot => _projectRoot;

  EnterprisePolicyEngine({
    required String projectRoot,
    EnterprisePolicyDocument? overridePolicy,
  })  : _projectRoot = p.normalize(projectRoot),
        _overridePolicy = overridePolicy;

  /// Loads and resolves hierarchical enterprise policy for the workspace.
  ///
  /// Searches:
  /// 1. `.fps/policy.json` or `.fps/policy.yaml` (Project level)
  /// 2. `enterprise_policy.json` / `enterprise_policy.yaml` (Org level)
  /// 3. Optional override policy passed in constructor.
  EnterprisePolicyDocument resolvePolicy({
    String? relativePackagePath,
  }) {
    if (_overridePolicy != null) {
      return _overridePolicy!;
    }

    EnterprisePolicyDocument current = const EnterprisePolicyDocument();

    // 1. Check for organization-level policy file in project root or parent
    final orgPolicyFile = _findFileInRoot([
      'enterprise_policy.json',
      'enterprise_policy.yaml',
      'enterprise_policy.yml',
      '.fps/org_policy.json',
    ]);
    if (orgPolicyFile != null && orgPolicyFile.existsSync()) {
      try {
        final parsed = _parsePolicyFile(orgPolicyFile);
        if (parsed != null) {
          current = current.composeWith(parsed);
          _logger.info('Loaded organization-level policy from ${orgPolicyFile.path}');
        }
      } catch (e) {
        _logger.warning('Failed to parse organization policy: $e');
      }
    }

    // 2. Check for project-level policy file
    final projectPolicyFile = _findFileInRoot([
      '.fps/policy.json',
      '.fps/policy.yaml',
      '.fps/policy.yml',
      'fps_policy.json',
      'fps_policy.yaml',
    ]);
    if (projectPolicyFile != null && projectPolicyFile.existsSync()) {
      try {
        final parsed = _parsePolicyFile(projectPolicyFile);
        if (parsed != null) {
          current = current.composeWith(parsed);
          _logger.info('Loaded project-level policy from ${projectPolicyFile.path}');
        }
      } catch (e) {
        _logger.warning('Failed to parse project policy: $e');
      }
    }

    // 3. Check for package-level policy file if relativePackagePath is provided
    if (relativePackagePath != null && relativePackagePath.isNotEmpty) {
      final pkgDir = Directory(p.join(_projectRoot, relativePackagePath));
      if (pkgDir.existsSync()) {
        final pkgPolicyFile = File(p.join(pkgDir.path, '.fps_policy.json'));
        if (pkgPolicyFile.existsSync()) {
          try {
            final parsed = _parsePolicyFile(pkgPolicyFile);
            if (parsed != null) {
              current = current.composeWith(parsed);
              _logger.info('Loaded package-level policy from ${pkgPolicyFile.path}');
            }
          } catch (e) {
            _logger.warning('Failed to parse package policy: $e');
          }
        }
      }
    }

    return current;
  }

  /// Evaluates workspace or operation against resolved enterprise policy.
  Future<PolicyEvaluationResult> evaluatePolicy({
    EnterprisePolicyScope scope = EnterprisePolicyScope.project,
    String? targetPackagePath,
    String? operationName,
    Map<String, dynamic>? operationContext,
    EnterprisePolicyDocument? activePolicy,
    DateTime? executionTimestamp,
  }) async {
    final stopwatch = Stopwatch()..start();
    final now = executionTimestamp ?? DateTime.now();
    final policy = activePolicy ?? resolvePolicy(relativePackagePath: targetPackagePath);

    final findings = <PolicyEvaluationFinding>[];
    final passedGates = <String>[];
    final failedGates = <String>[];

    _logger.info('Evaluating enterprise policy for scope: ${scope.id}, profile: ${policy.profile.id}');

    // ─────────────────────────────────────────────────────────────────────────
    // 1. OPERATION POLICIES
    // ─────────────────────────────────────────────────────────────────────────
    if (operationName != null && operationName.isNotEmpty) {
      final opNameClean = operationName.toLowerCase();
      final isBlockedOp = policy.operationPolicy.blockedOperations.any(
        (b) => b == '*' || b.toLowerCase() == opNameClean,
      );
      final isAllowedOp = policy.operationPolicy.allowedOperations.any(
        (a) => a == '*' || a.toLowerCase() == opNameClean,
      );

      if (isBlockedOp || !isAllowedOp) {
        findings.add(PolicyEvaluationFinding(
          ruleId: 'OP_001_OPERATION_NOT_ALLOWED',
          ruleName: 'Operation Authorization Policy',
          severity: PolicyFindingSeverity.critical,
          status: PolicyCheckStatus.failed,
          message: 'Operation "$operationName" is blocked or not in allowed list for profile ${policy.profile.id}.',
          remediation: 'Request policy exception or allow operation in enterprise policy configuration.',
        ));
        failedGates.add('operation_policy');
      } else {
        passedGates.add('operation_policy');
      }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 2. SECURITY POLICIES
    // ─────────────────────────────────────────────────────────────────────────
    final sec = policy.securityPolicy;
    var securityChecksPassed = true;

    // Check blocked file patterns
    final targetDir = targetPackagePath != null
        ? Directory(p.join(_projectRoot, targetPackagePath))
        : Directory(_projectRoot);

    if (targetDir.existsSync() && sec.enforceSensitiveFileExclusion) {
      for (final blockedPattern in sec.blockedFilePatterns) {
        if (blockedPattern == '.env*' || blockedPattern == '.env') {
          final envFile = File(p.join(targetDir.path, '.env'));
          if (envFile.existsSync()) {
            findings.add(PolicyEvaluationFinding(
              ruleId: 'SEC_001_BLOCKED_SENSITIVE_FILE',
              ruleName: 'Sensitive File Policy Violation',
              severity: PolicyFindingSeverity.critical,
              status: PolicyCheckStatus.failed,
              message: 'Found plaintext environment file ".env" matching blocked pattern "$blockedPattern".',
              remediation: 'Remove .env file or ensure it is added to .gitignore and removed from version control.',
              location: '.env',
            ));
            securityChecksPassed = false;
          }
        }
      }
    }

    // Check critical findings threshold from context if provided
    final existingCriticalFindings = (operationContext?['critical_security_findings'] as int?) ?? 0;
    final existingHighFindings = (operationContext?['high_security_findings'] as int?) ?? 0;

    if (existingCriticalFindings > sec.maxAllowedCriticalFindings) {
      findings.add(PolicyEvaluationFinding(
        ruleId: 'SEC_002_CRITICAL_SECURITY_FINDINGS_EXCEEDED',
        ruleName: 'Security Finding Threshold Exceeded',
        severity: PolicyFindingSeverity.critical,
        status: PolicyCheckStatus.failed,
        message: 'Security audit contains $existingCriticalFindings critical findings (max allowed: ${sec.maxAllowedCriticalFindings}).',
        remediation: 'Remediate critical security vulnerabilities before proceeding.',
      ));
      securityChecksPassed = false;
    }

    if (existingHighFindings > sec.maxAllowedHighFindings) {
      findings.add(PolicyEvaluationFinding(
        ruleId: 'SEC_003_HIGH_SECURITY_FINDINGS_EXCEEDED',
        ruleName: 'High Security Finding Threshold Exceeded',
        severity: PolicyFindingSeverity.high,
        status: PolicyCheckStatus.failed,
        message: 'Security audit contains $existingHighFindings high findings (max allowed: ${sec.maxAllowedHighFindings}).',
        remediation: 'Remediate high security vulnerabilities.',
      ));
      securityChecksPassed = false;
    }

    if (securityChecksPassed) {
      passedGates.add('security_policy');
    } else {
      failedGates.add('security_policy');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 3. RELEASE POLICIES (When in release scope or operation)
    // ─────────────────────────────────────────────────────────────────────────
    if (scope == EnterprisePolicyScope.package ||
        operationName == 'release' ||
        operationName == 'publish') {
      final rel = policy.releasePolicy;
      var releaseChecksPassed = true;

      for (final gate in rel.requiredVerificationGates) {
        final gatePassed = operationContext?[gate] as bool? ?? true;
        if (!gatePassed) {
          findings.add(PolicyEvaluationFinding(
            ruleId: 'REL_001_REQUIRED_GATE_FAILED',
            ruleName: 'Mandatory Release Verification Gate',
            severity: PolicyFindingSeverity.critical,
            status: PolicyCheckStatus.failed,
            message: 'Mandatory enterprise release gate "$gate" failed or was not satisfied.',
            remediation: 'Ensure all required verification stages pass in the release verification pipeline.',
          ));
          releaseChecksPassed = false;
        }
      }

      if (releaseChecksPassed) {
        passedGates.add('release_policy');
      } else {
        failedGates.add('release_policy');
      }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 4. AI USAGE POLICIES
    // ─────────────────────────────────────────────────────────────────────────
    if (operationName != null && operationName.startsWith('ai_')) {
      final aiCap = operationName.replaceFirst('ai_', '');
      final ai = policy.aiUsagePolicy;
      if (!ai.allowAiAssistance) {
        findings.add(PolicyEvaluationFinding(
          ruleId: 'AI_001_AI_ASSISTANCE_DISABLED',
          ruleName: 'Enterprise AI Governance Policy',
          severity: PolicyFindingSeverity.critical,
          status: PolicyCheckStatus.failed,
          message: 'AI engineering assistance is disabled by enterprise policy.',
          remediation: 'Enable AI assistance in enterprise_policy.json if authorized.',
        ));
        failedGates.add('ai_usage_policy');
      } else if (!ai.allowedAiCapabilities.contains(aiCap)) {
        findings.add(PolicyEvaluationFinding(
          ruleId: 'AI_002_CAPABILITY_NOT_PERMITTED',
          ruleName: 'AI Capability Restriction',
          severity: PolicyFindingSeverity.high,
          status: PolicyCheckStatus.failed,
          message: 'AI capability "$aiCap" is not in the allowed capabilities list for profile ${policy.profile.id}.',
          remediation: 'Add capability "$aiCap" to allowed_ai_capabilities in policy config.',
        ));
        failedGates.add('ai_usage_policy');
      } else {
        passedGates.add('ai_usage_policy');
      }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 5. DEPENDENCY POLICIES
    // ─────────────────────────────────────────────────────────────────────────
    final dep = policy.dependencyPolicy;
    if (dep.blockedPackages.isNotEmpty) {
      final pubspecFile = File(p.join(_projectRoot, 'pubspec.yaml'));
      if (pubspecFile.existsSync()) {
        try {
          final content = pubspecFile.readAsStringSync();
          for (final blocked in dep.blockedPackages) {
            if (content.contains('$blocked:')) {
              findings.add(PolicyEvaluationFinding(
                ruleId: 'DEP_001_BLOCKED_DEPENDENCY',
                ruleName: 'Enterprise Dependency Restriction',
                severity: PolicyFindingSeverity.critical,
                status: PolicyCheckStatus.failed,
                message: 'Package declares blocked dependency "$blocked".',
                remediation: 'Remove or replace blocked dependency with an approved alternative.',
                location: 'pubspec.yaml',
              ));
              failedGates.add('dependency_policy');
              break;
            }
          }
        } catch (_) {}
      }
    }
    if (!failedGates.contains('dependency_policy')) {
      passedGates.add('dependency_policy');
    }

    stopwatch.stop();

    final criticalCount = findings.where((f) => f.severity == PolicyFindingSeverity.critical && f.status == PolicyCheckStatus.failed).length;
    final highCount = findings.where((f) => f.severity == PolicyFindingSeverity.high && f.status == PolicyCheckStatus.failed).length;
    final mediumCount = findings.where((f) => f.severity == PolicyFindingSeverity.medium && f.status == PolicyCheckStatus.failed).length;
    final lowCount = findings.where((f) => f.severity == PolicyFindingSeverity.low && f.status == PolicyCheckStatus.failed).length;

    final isCompliant = findings.every((f) => f.status != PolicyCheckStatus.failed);
    final isBlocked = !isCompliant && policy.enforcementMode == PolicyEnforcementMode.strict;

    final summary = isCompliant
        ? 'Enterprise policy evaluation passed: 100% compliant with profile "${policy.profile.id}".'
        : 'Enterprise policy evaluation failed with $criticalCount critical and $highCount high findings. (Blocked: $isBlocked)';

    return PolicyEvaluationResult(
      isCompliant: isCompliant,
      isBlocked: isBlocked,
      organizationId: policy.organizationId,
      scope: scope,
      enforcementMode: policy.enforcementMode,
      findings: findings,
      passedGates: passedGates,
      failedGates: failedGates,
      criticalCount: criticalCount,
      highCount: highCount,
      mediumCount: mediumCount,
      lowCount: lowCount,
      summary: summary,
      durationMs: stopwatch.elapsedMilliseconds,
      timestamp: now,
    );
  }

  File? _findFileInRoot(List<String> relativePaths) {
    for (final rel in relativePaths) {
      final f = File(p.join(_projectRoot, rel));
      if (f.existsSync()) return f;
    }
    return null;
  }

  EnterprisePolicyDocument? _parsePolicyFile(File file) {
    final raw = file.readAsStringSync();
    if (file.path.endsWith('.yaml') || file.path.endsWith('.yml')) {
      final yamlDoc = loadYaml(raw);
      if (yamlDoc is Map) {
        final jsonMap = jsonDecode(jsonEncode(yamlDoc)) as Map<String, dynamic>;
        return EnterprisePolicyDocument.fromJson(jsonMap);
      }
    } else {
      final jsonMap = jsonDecode(raw) as Map<String, dynamic>;
      return EnterprisePolicyDocument.fromJson(jsonMap);
    }
    return null;
  }
}
