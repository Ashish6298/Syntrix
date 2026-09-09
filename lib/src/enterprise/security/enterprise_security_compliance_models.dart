/// Domain models for Phase 9.7: Enterprise Security Policy & Compliance Engine.
library;

/// Standard Enterprise Compliance Profiles.
enum EnterpriseComplianceProfile {
  standard,
  enterprise,
  financial,
  healthcare,
  government,
  strict,
  custom;

  String get id => name;

  String get displayName {
    switch (this) {
      case EnterpriseComplianceProfile.standard:
        return 'Standard Compliance';
      case EnterpriseComplianceProfile.enterprise:
        return 'Enterprise Compliance';
      case EnterpriseComplianceProfile.financial:
        return 'Financial / Banking Compliance';
      case EnterpriseComplianceProfile.healthcare:
        return 'Healthcare (HIPAA) Compliance';
      case EnterpriseComplianceProfile.government:
        return 'Government / FedRAMP Compliance';
      case EnterpriseComplianceProfile.strict:
        return 'Strict Non-Negotiable Compliance';
      case EnterpriseComplianceProfile.custom:
        return 'Custom Organization Policy';
    }
  }

  static EnterpriseComplianceProfile fromString(String? val) {
    if (val == null) return EnterpriseComplianceProfile.standard;
    return EnterpriseComplianceProfile.values.firstWhere(
      (e) =>
          e.name.toLowerCase() == val.toLowerCase() ||
          e.displayName.toLowerCase() == val.toLowerCase(),
      orElse: () => EnterpriseComplianceProfile.custom,
    );
  }
}

/// Compliance Control Evaluation Status.
enum ComplianceStatus {
  passed,
  failed,
  warning,
  notApplicable;

  String get label => name.toUpperCase();
}

/// Single compliance control audit finding.
class ComplianceControlFinding {
  final String controlId;
  final String controlTitle;
  final String category;
  final ComplianceStatus status;
  final String description;
  final String? remediation;
  final String? affectedResource;
  final bool isBlocking;

  const ComplianceControlFinding({
    required this.controlId,
    required this.controlTitle,
    required this.category,
    required this.status,
    required this.description,
    this.remediation,
    this.affectedResource,
    this.isBlocking = false,
  });

  Map<String, dynamic> toJson() => {
        'control_id': controlId,
        'control_title': controlTitle,
        'category': category,
        'status': status.name,
        'description': description,
        'remediation': remediation,
        'affected_resource': affectedResource,
        'is_blocking': isBlocking,
      };

  factory ComplianceControlFinding.fromJson(Map<String, dynamic> json) {
    return ComplianceControlFinding(
      controlId: json['control_id'] as String? ?? 'UNKNOWN',
      controlTitle: json['control_title'] as String? ?? 'Unnamed Control',
      category: json['category'] as String? ?? 'General',
      status: ComplianceStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => ComplianceStatus.passed,
      ),
      description: json['description'] as String? ?? '',
      remediation: json['remediation'] as String?,
      affectedResource: json['affected_resource'] as String?,
      isBlocking: json['is_blocking'] as bool? ?? false,
    );
  }
}

/// Policy specification governing enterprise security compliance requirements.
class EnterpriseSecurityCompliancePolicy {
  final EnterpriseComplianceProfile profile;
  final bool requireZeroSecrets;
  final bool requireEncryptedArtifacts;
  final bool enforceSensitiveFileExclusion;
  final bool requireCredentialIsolation;
  final bool enforceSourceExposureRules;
  final bool requireFormalSecurityReview;
  final int maxAllowedCriticalFindings;
  final int maxAllowedHighFindings;
  final int maxAllowedMediumFindings;
  final List<String> mandatorySecurityGates;
  final List<String> prohibitedNetworkEndpoints;

  const EnterpriseSecurityCompliancePolicy({
    this.profile = EnterpriseComplianceProfile.standard,
    this.requireZeroSecrets = true,
    this.requireEncryptedArtifacts = false,
    this.enforceSensitiveFileExclusion = true,
    this.requireCredentialIsolation = true,
    this.enforceSourceExposureRules = true,
    this.requireFormalSecurityReview = false,
    this.maxAllowedCriticalFindings = 0,
    this.maxAllowedHighFindings = 0,
    this.maxAllowedMediumFindings = 5,
    this.mandatorySecurityGates = const [
      'secret_detection',
      'sensitive_file_filter',
      'dependency_security_audit',
    ],
    this.prohibitedNetworkEndpoints = const [],
  });

  /// Factory creating compliance policies by predefined profile presets.
  factory EnterpriseSecurityCompliancePolicy.fromProfile(
      EnterpriseComplianceProfile profile) {
    switch (profile) {
      case EnterpriseComplianceProfile.financial:
      case EnterpriseComplianceProfile.government:
      case EnterpriseComplianceProfile.strict:
        return EnterpriseSecurityCompliancePolicy(
          profile: profile,
          requireZeroSecrets: true,
          requireEncryptedArtifacts: true,
          enforceSensitiveFileExclusion: true,
          requireCredentialIsolation: true,
          enforceSourceExposureRules: true,
          requireFormalSecurityReview: true,
          maxAllowedCriticalFindings: 0,
          maxAllowedHighFindings: 0,
          maxAllowedMediumFindings: 0,
          mandatorySecurityGates: const [
            'secret_detection',
            'sensitive_file_filter',
            'dependency_security_audit',
            'encryption_verification',
            'formal_security_review',
          ],
        );

      case EnterpriseComplianceProfile.healthcare:
        return EnterpriseSecurityCompliancePolicy(
          profile: profile,
          requireZeroSecrets: true,
          requireEncryptedArtifacts: true,
          enforceSensitiveFileExclusion: true,
          requireCredentialIsolation: true,
          enforceSourceExposureRules: true,
          requireFormalSecurityReview: true,
          maxAllowedCriticalFindings: 0,
          maxAllowedHighFindings: 0,
          maxAllowedMediumFindings: 2,
        );

      case EnterpriseComplianceProfile.enterprise:
        return EnterpriseSecurityCompliancePolicy(
          profile: profile,
          requireZeroSecrets: true,
          requireEncryptedArtifacts: false,
          enforceSensitiveFileExclusion: true,
          requireCredentialIsolation: true,
          enforceSourceExposureRules: true,
          requireFormalSecurityReview: true,
          maxAllowedCriticalFindings: 0,
          maxAllowedHighFindings: 0,
          maxAllowedMediumFindings: 3,
        );

      case EnterpriseComplianceProfile.standard:
      case EnterpriseComplianceProfile.custom:
        return const EnterpriseSecurityCompliancePolicy(
          profile: EnterpriseComplianceProfile.standard,
        );
    }
  }

  Map<String, dynamic> toJson() => {
        'profile': profile.id,
        'require_zero_secrets': requireZeroSecrets,
        'require_encrypted_artifacts': requireEncryptedArtifacts,
        'enforce_sensitive_file_exclusion': enforceSensitiveFileExclusion,
        'require_credential_isolation': requireCredentialIsolation,
        'enforce_source_exposure_rules': enforceSourceExposureRules,
        'require_formal_security_review': requireFormalSecurityReview,
        'max_allowed_critical_findings': maxAllowedCriticalFindings,
        'max_allowed_high_findings': maxAllowedHighFindings,
        'max_allowed_medium_findings': maxAllowedMediumFindings,
        'mandatory_security_gates': mandatorySecurityGates,
        'prohibited_network_endpoints': prohibitedNetworkEndpoints,
      };

  factory EnterpriseSecurityCompliancePolicy.fromJson(
      Map<String, dynamic> json) {
    return EnterpriseSecurityCompliancePolicy(
      profile:
          EnterpriseComplianceProfile.fromString(json['profile'] as String?),
      requireZeroSecrets: json['require_zero_secrets'] as bool? ?? true,
      requireEncryptedArtifacts:
          json['require_encrypted_artifacts'] as bool? ?? false,
      enforceSensitiveFileExclusion:
          json['enforce_sensitive_file_exclusion'] as bool? ?? true,
      requireCredentialIsolation:
          json['require_credential_isolation'] as bool? ?? true,
      enforceSourceExposureRules:
          json['enforce_source_exposure_rules'] as bool? ?? true,
      requireFormalSecurityReview:
          json['require_formal_security_review'] as bool? ?? false,
      maxAllowedCriticalFindings:
          json['max_allowed_critical_findings'] as int? ?? 0,
      maxAllowedHighFindings: json['max_allowed_high_findings'] as int? ?? 0,
      maxAllowedMediumFindings:
          json['max_allowed_medium_findings'] as int? ?? 5,
      mandatorySecurityGates:
          (json['mandatory_security_gates'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              const [
                'secret_detection',
                'sensitive_file_filter',
                'dependency_security_audit'
              ],
      prohibitedNetworkEndpoints:
          (json['prohibited_network_endpoints'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              const [],
    );
  }
}

/// Comprehensive Compliance Audit Assessment Result.
class SecurityComplianceAssessmentResult {
  final bool isCompliant;
  final bool isBlocked;
  final String targetProject;
  final EnterpriseComplianceProfile profile;
  final List<ComplianceControlFinding> controlFindings;
  final List<String> passedGates;
  final List<String> failedGates;
  final int totalControlsEvaluated;
  final int criticalViolations;
  final int highViolations;
  final int mediumViolations;
  final String summary;
  final int durationMs;
  final DateTime timestamp;

  const SecurityComplianceAssessmentResult({
    required this.isCompliant,
    required this.isBlocked,
    required this.targetProject,
    required this.profile,
    required this.controlFindings,
    required this.passedGates,
    required this.failedGates,
    required this.totalControlsEvaluated,
    required this.criticalViolations,
    required this.highViolations,
    required this.mediumViolations,
    required this.summary,
    required this.durationMs,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'is_compliant': isCompliant,
        'is_blocked': isBlocked,
        'target_project': targetProject,
        'profile': profile.id,
        'control_findings': controlFindings.map((f) => f.toJson()).toList(),
        'passed_gates': passedGates,
        'failed_gates': failedGates,
        'total_controls_evaluated': totalControlsEvaluated,
        'critical_violations': criticalViolations,
        'high_violations': highViolations,
        'medium_violations': mediumViolations,
        'summary': summary,
        'duration_ms': durationMs,
        'timestamp': timestamp.toIso8601String(),
      };

  factory SecurityComplianceAssessmentResult.fromJson(
      Map<String, dynamic> json) {
    return SecurityComplianceAssessmentResult(
      isCompliant: json['is_compliant'] as bool? ?? false,
      isBlocked: json['is_blocked'] as bool? ?? true,
      targetProject: json['target_project'] as String? ?? 'unknown',
      profile:
          EnterpriseComplianceProfile.fromString(json['profile'] as String?),
      controlFindings: (json['control_findings'] as List<dynamic>?)
              ?.map((f) =>
                  ComplianceControlFinding.fromJson(f as Map<String, dynamic>))
              .toList() ??
          const [],
      passedGates: (json['passed_gates'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      failedGates: (json['failed_gates'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      totalControlsEvaluated: json['total_controls_evaluated'] as int? ?? 0,
      criticalViolations: json['critical_violations'] as int? ?? 0,
      highViolations: json['high_violations'] as int? ?? 0,
      mediumViolations: json['medium_violations'] as int? ?? 0,
      summary: json['summary'] as String? ?? '',
      durationMs: json['duration_ms'] as int? ?? 0,
      timestamp: json['timestamp'] is String
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
    );
  }
}
