/// Domain models for Phase 9.1: Enterprise Configuration & Policy Engine.
library;

import 'dart:convert';

/// Policy enforcement mode.
enum PolicyEnforcementMode {
  /// Strict enforcement: policy violations block operations.
  strict,

  /// Warning enforcement: policy violations emit warnings but do not block.
  permissive,

  /// Audit-only enforcement: policy checks run silently and record audit data.
  auditOnly;

  String get id => name;

  static PolicyEnforcementMode fromString(String? val) {
    if (val == null) return PolicyEnforcementMode.strict;
    return PolicyEnforcementMode.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => PolicyEnforcementMode.strict,
    );
  }
}

/// Target scope where the policy is evaluated.
enum EnterprisePolicyScope {
  organization,
  project,
  package,
  environment;

  String get id => name;

  static EnterprisePolicyScope fromString(String? val) {
    if (val == null) return EnterprisePolicyScope.project;
    return EnterprisePolicyScope.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => EnterprisePolicyScope.project,
    );
  }
}

/// Severity level of policy findings or evaluation items.
enum PolicyFindingSeverity {
  critical,
  high,
  medium,
  low,
  informational;

  String get label => name.toUpperCase();

  static PolicyFindingSeverity fromString(String? val) {
    if (val == null) return PolicyFindingSeverity.medium;
    return PolicyFindingSeverity.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => PolicyFindingSeverity.medium,
    );
  }
}

/// Outcome status for individual policy evaluation checks.
enum PolicyCheckStatus {
  passed,
  failed,
  warning,
  skipped;

  String get label => name.toUpperCase();

  static PolicyCheckStatus fromString(String? val) {
    if (val == null) return PolicyCheckStatus.passed;
    return PolicyCheckStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => PolicyCheckStatus.passed,
    );
  }
}

/// Built-in enterprise policy profile presets.
enum EnterprisePolicyProfile {
  standard,
  strict,
  financial,
  healthcare,
  government,
  openSource,
  custom;

  String get id => name;

  static EnterprisePolicyProfile fromString(String? val) {
    if (val == null) return EnterprisePolicyProfile.standard;
    return EnterprisePolicyProfile.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => EnterprisePolicyProfile.custom,
    );
  }
}

/// Configuration for Release Policy.
class ReleasePolicyConfig {
  final bool requireSecurityAudit;
  final bool requirePubDevValidation;
  final bool requireManifest;
  final bool requireReleaseVerification;
  final bool requireChangelog;
  final bool requireGitTag;
  final bool blockOnCriticalSecurityFindings;
  final List<String> requiredVerificationGates;
  final List<String> allowedChannels;

  const ReleasePolicyConfig({
    this.requireSecurityAudit = true,
    this.requirePubDevValidation = true,
    this.requireManifest = true,
    this.requireReleaseVerification = true,
    this.requireChangelog = true,
    this.requireGitTag = true,
    this.blockOnCriticalSecurityFindings = true,
    this.requiredVerificationGates = const [
      'security_audit',
      'pub_dev_validation',
      'release_verification',
      'manifest_generation',
    ],
    this.allowedChannels = const ['stable', 'beta', 'dev'],
  });

  Map<String, dynamic> toJson() => {
        'require_security_audit': requireSecurityAudit,
        'require_pub_dev_validation': requirePubDevValidation,
        'require_manifest': requireManifest,
        'require_release_verification': requireReleaseVerification,
        'require_changelog': requireChangelog,
        'require_git_tag': requireGitTag,
        'block_on_critical_security_findings': blockOnCriticalSecurityFindings,
        'required_verification_gates': requiredVerificationGates,
        'allowed_channels': allowedChannels,
      };

  factory ReleasePolicyConfig.fromJson(Map<String, dynamic> json) {
    return ReleasePolicyConfig(
      requireSecurityAudit: json['require_security_audit'] as bool? ?? true,
      requirePubDevValidation: json['require_pub_dev_validation'] as bool? ?? true,
      requireManifest: json['require_manifest'] as bool? ?? true,
      requireReleaseVerification: json['require_release_verification'] as bool? ?? true,
      requireChangelog: json['require_changelog'] as bool? ?? true,
      requireGitTag: json['require_git_tag'] as bool? ?? true,
      blockOnCriticalSecurityFindings: json['block_on_critical_security_findings'] as bool? ?? true,
      requiredVerificationGates: (json['required_verification_gates'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const ['security_audit', 'pub_dev_validation', 'release_verification', 'manifest_generation'],
      allowedChannels: (json['allowed_channels'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const ['stable', 'beta', 'dev'],
    );
  }
}

/// Configuration for Security Policy.
class SecurityPolicyConfig {
  final bool blockPlaintextSecrets;
  final bool enforceSensitiveFileExclusion;
  final bool requireSecretRedaction;
  final List<String> blockedFilePatterns;
  final int maxAllowedCriticalFindings;
  final int maxAllowedHighFindings;

  const SecurityPolicyConfig({
    this.blockPlaintextSecrets = true,
    this.enforceSensitiveFileExclusion = true,
    this.requireSecretRedaction = true,
    this.blockedFilePatterns = const [
      '.env*',
      '*.key',
      '*.pem',
      '*.p12',
      'key.properties',
      'credentials.json',
      'secrets.json',
    ],
    this.maxAllowedCriticalFindings = 0,
    this.maxAllowedHighFindings = 0,
  });

  Map<String, dynamic> toJson() => {
        'block_plaintext_secrets': blockPlaintextSecrets,
        'enforce_sensitive_file_exclusion': enforceSensitiveFileExclusion,
        'require_secret_redaction': requireSecretRedaction,
        'blocked_file_patterns': blockedFilePatterns,
        'max_allowed_critical_findings': maxAllowedCriticalFindings,
        'max_allowed_high_findings': maxAllowedHighFindings,
      };

  factory SecurityPolicyConfig.fromJson(Map<String, dynamic> json) {
    return SecurityPolicyConfig(
      blockPlaintextSecrets: json['block_plaintext_secrets'] as bool? ?? true,
      enforceSensitiveFileExclusion: json['enforce_sensitive_file_exclusion'] as bool? ?? true,
      requireSecretRedaction: json['require_secret_redaction'] as bool? ?? true,
      blockedFilePatterns: (json['blocked_file_patterns'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const ['.env*', '*.key', '*.pem', '*.p12', 'key.properties', 'credentials.json', 'secrets.json'],
      maxAllowedCriticalFindings: json['max_allowed_critical_findings'] as int? ?? 0,
      maxAllowedHighFindings: json['max_allowed_high_findings'] as int? ?? 0,
    );
  }
}

/// Configuration for AI Usage Policy.
class AiUsagePolicyConfig {
  final bool allowAiAssistance;
  final bool allowLocalAiProvider;
  final bool allowExternalAiProvider;
  final bool requireExplicitApprovalForModifications;
  final bool enforcePromptSanitization;
  final bool disallowDirectCommandExecution;
  final List<String> allowedAiCapabilities;

  const AiUsagePolicyConfig({
    this.allowAiAssistance = true,
    this.allowLocalAiProvider = true,
    this.allowExternalAiProvider = true,
    this.requireExplicitApprovalForModifications = true,
    this.enforcePromptSanitization = true,
    this.disallowDirectCommandExecution = true,
    this.allowedAiCapabilities = const [
      'analyze',
      'review',
      'debug',
      'test',
      'document',
      'security',
      'architecture',
      'dependencies',
      'release',
      'plan',
      'memory',
      'modify',
    ],
  });

  Map<String, dynamic> toJson() => {
        'allow_ai_assistance': allowAiAssistance,
        'allow_local_ai_provider': allowLocalAiProvider,
        'allow_external_ai_provider': allowExternalAiProvider,
        'require_explicit_approval_for_modifications': requireExplicitApprovalForModifications,
        'enforce_prompt_sanitization': enforcePromptSanitization,
        'disallow_direct_command_execution': disallowDirectCommandExecution,
        'allowed_ai_capabilities': allowedAiCapabilities,
      };

  factory AiUsagePolicyConfig.fromJson(Map<String, dynamic> json) {
    return AiUsagePolicyConfig(
      allowAiAssistance: json['allow_ai_assistance'] as bool? ?? true,
      allowLocalAiProvider: json['allow_local_ai_provider'] as bool? ?? true,
      allowExternalAiProvider: json['allow_external_ai_provider'] as bool? ?? true,
      requireExplicitApprovalForModifications: json['require_explicit_approval_for_modifications'] as bool? ?? true,
      enforcePromptSanitization: json['enforce_prompt_sanitization'] as bool? ?? true,
      disallowDirectCommandExecution: json['disallow_direct_command_execution'] as bool? ?? true,
      allowedAiCapabilities: (json['allowed_ai_capabilities'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [
            'analyze',
            'review',
            'debug',
            'test',
            'document',
            'security',
            'architecture',
            'dependencies',
            'release',
            'plan',
            'memory',
            'modify',
          ],
    );
  }
}

/// Configuration for Dependency Governance Policy.
class DependencyPolicyConfig {
  final List<String> allowedPackages;
  final List<String> blockedPackages;
  final List<String> allowedLicenseTypes;
  final bool disallowGitDependenciesInRelease;
  final bool disallowPathDependenciesInRelease;

  const DependencyPolicyConfig({
    this.allowedPackages = const [],
    this.blockedPackages = const [],
    this.allowedLicenseTypes = const ['MIT', 'Apache-2.0', 'BSD-3-Clause', 'BSD-2-Clause', 'ISC'],
    this.disallowGitDependenciesInRelease = true,
    this.disallowPathDependenciesInRelease = true,
  });

  Map<String, dynamic> toJson() => {
        'allowed_packages': allowedPackages,
        'blocked_packages': blockedPackages,
        'allowed_license_types': allowedLicenseTypes,
        'disallow_git_dependencies_in_release': disallowGitDependenciesInRelease,
        'disallow_path_dependencies_in_release': disallowPathDependenciesInRelease,
      };

  factory DependencyPolicyConfig.fromJson(Map<String, dynamic> json) {
    return DependencyPolicyConfig(
      allowedPackages: (json['allowed_packages'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      blockedPackages: (json['blocked_packages'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      allowedLicenseTypes: (json['allowed_license_types'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          const ['MIT', 'Apache-2.0', 'BSD-3-Clause', 'BSD-2-Clause', 'ISC'],
      disallowGitDependenciesInRelease: json['disallow_git_dependencies_in_release'] as bool? ?? true,
      disallowPathDependenciesInRelease: json['disallow_path_dependencies_in_release'] as bool? ?? true,
    );
  }
}

/// Configuration for Naming and Versioning Policy.
class NamingAndVersioningPolicyConfig {
  final String? packagePrefix;
  final String? orgDomainPrefix;
  final bool enforceSemver;
  final bool disallowPrereleaseInProduction;
  final List<String> allowedPackageNameRegexes;

  const NamingAndVersioningPolicyConfig({
    this.packagePrefix,
    this.orgDomainPrefix,
    this.enforceSemver = true,
    this.disallowPrereleaseInProduction = true,
    this.allowedPackageNameRegexes = const [r'^[a-z][a-z0-9_]*$'],
  });

  Map<String, dynamic> toJson() => {
        'package_prefix': packagePrefix,
        'org_domain_prefix': orgDomainPrefix,
        'enforce_semver': enforceSemver,
        'disallow_prerelease_in_production': disallowPrereleaseInProduction,
        'allowed_package_name_regexes': allowedPackageNameRegexes,
      };

  factory NamingAndVersioningPolicyConfig.fromJson(Map<String, dynamic> json) {
    return NamingAndVersioningPolicyConfig(
      packagePrefix: json['package_prefix'] as String?,
      orgDomainPrefix: json['org_domain_prefix'] as String?,
      enforceSemver: json['enforce_semver'] as bool? ?? true,
      disallowPrereleaseInProduction: json['disallow_prerelease_in_production'] as bool? ?? true,
      allowedPackageNameRegexes: (json['allowed_package_name_regexes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [r'^[a-z][a-z0-9_]*$'],
    );
  }
}

/// Configuration for Allowed / Blocked Operations.
class OperationPolicyConfig {
  final List<String> allowedOperations;
  final List<String> blockedOperations;
  final bool requireAuditLoggingForAllOperations;

  const OperationPolicyConfig({
    this.allowedOperations = const ['*'],
    this.blockedOperations = const [],
    this.requireAuditLoggingForAllOperations = true,
  });

  Map<String, dynamic> toJson() => {
        'allowed_operations': allowedOperations,
        'blocked_operations': blockedOperations,
        'require_audit_logging_for_all_operations': requireAuditLoggingForAllOperations,
      };

  factory OperationPolicyConfig.fromJson(Map<String, dynamic> json) {
    return OperationPolicyConfig(
      allowedOperations:
          (json['allowed_operations'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const ['*'],
      blockedOperations:
          (json['blocked_operations'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      requireAuditLoggingForAllOperations: json['require_audit_logging_for_all_operations'] as bool? ?? true,
    );
  }
}

/// Full Enterprise Policy Document.
class EnterprisePolicyDocument {
  final String version;
  final String organizationId;
  final String organizationName;
  final EnterprisePolicyProfile profile;
  final PolicyEnforcementMode enforcementMode;
  final ReleasePolicyConfig releasePolicy;
  final SecurityPolicyConfig securityPolicy;
  final AiUsagePolicyConfig aiUsagePolicy;
  final DependencyPolicyConfig dependencyPolicy;
  final NamingAndVersioningPolicyConfig namingAndVersioningPolicy;
  final OperationPolicyConfig operationPolicy;
  final Map<String, dynamic> customMetadata;

  const EnterprisePolicyDocument({
    this.version = '1.0.0',
    this.organizationId = 'default_org',
    this.organizationName = 'Enterprise Default Organization',
    this.profile = EnterprisePolicyProfile.standard,
    this.enforcementMode = PolicyEnforcementMode.strict,
    this.releasePolicy = const ReleasePolicyConfig(),
    this.securityPolicy = const SecurityPolicyConfig(),
    this.aiUsagePolicy = const AiUsagePolicyConfig(),
    this.dependencyPolicy = const DependencyPolicyConfig(),
    this.namingAndVersioningPolicy = const NamingAndVersioningPolicyConfig(),
    this.operationPolicy = const OperationPolicyConfig(),
    this.customMetadata = const {},
  });

  /// Factory creating predefined profiles.
  factory EnterprisePolicyDocument.fromProfile(
    EnterprisePolicyProfile profile, {
    String organizationId = 'enterprise_org',
    String organizationName = 'Enterprise Organization',
  }) {
    switch (profile) {
      case EnterprisePolicyProfile.strict:
      case EnterprisePolicyProfile.financial:
      case EnterprisePolicyProfile.government:
        return EnterprisePolicyDocument(
          organizationId: organizationId,
          organizationName: organizationName,
          profile: profile,
          enforcementMode: PolicyEnforcementMode.strict,
          releasePolicy: const ReleasePolicyConfig(
            requireSecurityAudit: true,
            requirePubDevValidation: true,
            requireManifest: true,
            requireReleaseVerification: true,
            requireChangelog: true,
            requireGitTag: true,
            blockOnCriticalSecurityFindings: true,
          ),
          securityPolicy: const SecurityPolicyConfig(
            blockPlaintextSecrets: true,
            enforceSensitiveFileExclusion: true,
            requireSecretRedaction: true,
            maxAllowedCriticalFindings: 0,
            maxAllowedHighFindings: 0,
          ),
          aiUsagePolicy: const AiUsagePolicyConfig(
            allowAiAssistance: true,
            allowLocalAiProvider: true,
            allowExternalAiProvider: false, // Disallow external AI for government/financial strictness
            requireExplicitApprovalForModifications: true,
            enforcePromptSanitization: true,
            disallowDirectCommandExecution: true,
          ),
          dependencyPolicy: const DependencyPolicyConfig(
            disallowGitDependenciesInRelease: true,
            disallowPathDependenciesInRelease: true,
          ),
          namingAndVersioningPolicy: const NamingAndVersioningPolicyConfig(
            enforceSemver: true,
            disallowPrereleaseInProduction: true,
          ),
        );

      case EnterprisePolicyProfile.healthcare:
        return EnterprisePolicyDocument(
          organizationId: organizationId,
          organizationName: organizationName,
          profile: profile,
          enforcementMode: PolicyEnforcementMode.strict,
          releasePolicy: const ReleasePolicyConfig(),
          securityPolicy: const SecurityPolicyConfig(
            blockPlaintextSecrets: true,
            enforceSensitiveFileExclusion: true,
            requireSecretRedaction: true,
            maxAllowedCriticalFindings: 0,
            maxAllowedHighFindings: 0,
          ),
          aiUsagePolicy: const AiUsagePolicyConfig(
            allowAiAssistance: true,
            allowLocalAiProvider: true,
            allowExternalAiProvider: false,
            requireExplicitApprovalForModifications: true,
          ),
        );

      case EnterprisePolicyProfile.openSource:
        return EnterprisePolicyDocument(
          organizationId: organizationId,
          organizationName: organizationName,
          profile: profile,
          enforcementMode: PolicyEnforcementMode.permissive,
          releasePolicy: const ReleasePolicyConfig(
            requireGitTag: false,
          ),
          aiUsagePolicy: const AiUsagePolicyConfig(
            allowAiAssistance: true,
            allowLocalAiProvider: true,
            allowExternalAiProvider: true,
          ),
        );

      case EnterprisePolicyProfile.standard:
      case EnterprisePolicyProfile.custom:
        return EnterprisePolicyDocument(
          organizationId: organizationId,
          organizationName: organizationName,
          profile: profile,
          enforcementMode: PolicyEnforcementMode.strict,
        );
    }
  }

  Map<String, dynamic> toJson() => {
        'version': version,
        'organization_id': organizationId,
        'organization_name': organizationName,
        'profile': profile.id,
        'enforcement_mode': enforcementMode.id,
        'release_policy': releasePolicy.toJson(),
        'security_policy': securityPolicy.toJson(),
        'ai_usage_policy': aiUsagePolicy.toJson(),
        'dependency_policy': dependencyPolicy.toJson(),
        'naming_and_versioning_policy': namingAndVersioningPolicy.toJson(),
        'operation_policy': operationPolicy.toJson(),
        'custom_metadata': customMetadata,
      };

  factory EnterprisePolicyDocument.fromJson(Map<String, dynamic> json) {
    return EnterprisePolicyDocument(
      version: json['version'] as String? ?? '1.0.0',
      organizationId: json['organization_id'] as String? ?? 'default_org',
      organizationName: json['organization_name'] as String? ?? 'Enterprise Default Organization',
      profile: EnterprisePolicyProfile.fromString(json['profile'] as String?),
      enforcementMode: PolicyEnforcementMode.fromString(json['enforcement_mode'] as String?),
      releasePolicy: json['release_policy'] is Map<String, dynamic>
          ? ReleasePolicyConfig.fromJson(json['release_policy'] as Map<String, dynamic>)
          : const ReleasePolicyConfig(),
      securityPolicy: json['security_policy'] is Map<String, dynamic>
          ? SecurityPolicyConfig.fromJson(json['security_policy'] as Map<String, dynamic>)
          : const SecurityPolicyConfig(),
      aiUsagePolicy: json['ai_usage_policy'] is Map<String, dynamic>
          ? AiUsagePolicyConfig.fromJson(json['ai_usage_policy'] as Map<String, dynamic>)
          : const AiUsagePolicyConfig(),
      dependencyPolicy: json['dependency_policy'] is Map<String, dynamic>
          ? DependencyPolicyConfig.fromJson(json['dependency_policy'] as Map<String, dynamic>)
          : const DependencyPolicyConfig(),
      namingAndVersioningPolicy: json['naming_and_versioning_policy'] is Map<String, dynamic>
          ? NamingAndVersioningPolicyConfig.fromJson(json['naming_and_versioning_policy'] as Map<String, dynamic>)
          : const NamingAndVersioningPolicyConfig(),
      operationPolicy: json['operation_policy'] is Map<String, dynamic>
          ? OperationPolicyConfig.fromJson(json['operation_policy'] as Map<String, dynamic>)
          : const OperationPolicyConfig(),
      customMetadata: (json['custom_metadata'] as Map<String, dynamic>?) ?? const {},
    );
  }

  /// Composes this policy with an overriding child policy (e.g. project over org, or package over project).
  EnterprisePolicyDocument composeWith(EnterprisePolicyDocument child) {
    return EnterprisePolicyDocument(
      version: child.version.isNotEmpty ? child.version : version,
      organizationId: child.organizationId != 'default_org' ? child.organizationId : organizationId,
      organizationName: child.organizationName != 'Enterprise Default Organization'
          ? child.organizationName
          : organizationName,
      profile: child.profile != EnterprisePolicyProfile.custom ? child.profile : profile,
      enforcementMode: child.enforcementMode,
      releasePolicy: child.releasePolicy,
      securityPolicy: child.securityPolicy,
      aiUsagePolicy: child.aiUsagePolicy,
      dependencyPolicy: child.dependencyPolicy,
      namingAndVersioningPolicy: child.namingAndVersioningPolicy,
      operationPolicy: child.operationPolicy,
      customMetadata: {
        ...customMetadata,
        ...child.customMetadata,
      },
    );
  }
}

/// Single policy verification finding.
class PolicyEvaluationFinding {
  final String ruleId;
  final String ruleName;
  final PolicyFindingSeverity severity;
  final PolicyCheckStatus status;
  final String message;
  final String? remediation;
  final String? location;

  const PolicyEvaluationFinding({
    required this.ruleId,
    required this.ruleName,
    required this.severity,
    required this.status,
    required this.message,
    this.remediation,
    this.location,
  });

  Map<String, dynamic> toJson() => {
        'rule_id': ruleId,
        'rule_name': ruleName,
        'severity': severity.name,
        'status': status.name,
        'message': message,
        'remediation': remediation,
        'location': location,
      };

  factory PolicyEvaluationFinding.fromJson(Map<String, dynamic> json) {
    return PolicyEvaluationFinding(
      ruleId: json['rule_id'] as String? ?? 'UNKNOWN',
      ruleName: json['rule_name'] as String? ?? 'Unnamed Rule',
      severity: PolicyFindingSeverity.fromString(json['severity'] as String?),
      status: PolicyCheckStatus.fromString(json['status'] as String?),
      message: json['message'] as String? ?? '',
      remediation: json['remediation'] as String?,
      location: json['location'] as String?,
    );
  }
}

/// Comprehensive result of evaluating enterprise policies against an operation or project.
class PolicyEvaluationResult {
  final bool isCompliant;
  final bool isBlocked;
  final String organizationId;
  final EnterprisePolicyScope scope;
  final PolicyEnforcementMode enforcementMode;
  final List<PolicyEvaluationFinding> findings;
  final List<String> passedGates;
  final List<String> failedGates;
  final int criticalCount;
  final int highCount;
  final int mediumCount;
  final int lowCount;
  final String summary;
  final int durationMs;
  final DateTime timestamp;

  const PolicyEvaluationResult({
    required this.isCompliant,
    required this.isBlocked,
    required this.organizationId,
    required this.scope,
    required this.enforcementMode,
    required this.findings,
    required this.passedGates,
    required this.failedGates,
    required this.criticalCount,
    required this.highCount,
    required this.mediumCount,
    required this.lowCount,
    required this.summary,
    required this.durationMs,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'is_compliant': isCompliant,
        'is_blocked': isBlocked,
        'organization_id': organizationId,
        'scope': scope.id,
        'enforcement_mode': enforcementMode.id,
        'findings': findings.map((f) => f.toJson()).toList(),
        'passed_gates': passedGates,
        'failed_gates': failedGates,
        'critical_count': criticalCount,
        'high_count': highCount,
        'medium_count': mediumCount,
        'low_count': lowCount,
        'summary': summary,
        'duration_ms': durationMs,
        'timestamp': timestamp.toIso8601String(),
      };

  factory PolicyEvaluationResult.fromJson(Map<String, dynamic> json) {
    return PolicyEvaluationResult(
      isCompliant: json['is_compliant'] as bool? ?? false,
      isBlocked: json['is_blocked'] as bool? ?? true,
      organizationId: json['organization_id'] as String? ?? 'default_org',
      scope: EnterprisePolicyScope.fromString(json['scope'] as String?),
      enforcementMode: PolicyEnforcementMode.fromString(json['enforcement_mode'] as String?),
      findings: (json['findings'] as List<dynamic>?)
              ?.map((f) => PolicyEvaluationFinding.fromJson(f as Map<String, dynamic>))
              .toList() ??
          const [],
      passedGates: (json['passed_gates'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      failedGates: (json['failed_gates'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      criticalCount: json['critical_count'] as int? ?? 0,
      highCount: json['high_count'] as int? ?? 0,
      mediumCount: json['medium_count'] as int? ?? 0,
      lowCount: json['low_count'] as int? ?? 0,
      summary: json['summary'] as String? ?? '',
      durationMs: json['duration_ms'] as int? ?? 0,
      timestamp: json['timestamp'] is String ? DateTime.parse(json['timestamp'] as String) : DateTime.now(),
    );
  }
}
