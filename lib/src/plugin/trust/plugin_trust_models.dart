/// Domain models and structured findings for Plugin Security & Trust Verification (Phase 7.14).
library;

import 'dart:convert';
import 'package:crypto/crypto.dart' as crypto;
import 'package:syntrix/src/release/versioning/semver_models.dart';

/// 5-Level formal trust classification scale for Flutter Package Studio plugins.
enum PluginTrustLevel {
  /// Passes all checks with zero risk signals and verified provenance.
  trusted,

  /// Passes all hard contract & security checks with no unsafe findings, without verified provenance.
  validated,

  /// Passes hard checks but has heuristic risk signals (unsafe configuration, suspicious resources).
  /// Requires explicit operator acknowledgment to activate.
  restricted,

  /// Fails a hard security check (manifest integrity failure, untrusted/blocked dependency, permission refusal).
  /// Forbidden from reaching Active.
  blocked,

  /// Fails basic Phase 7.1 contract validation before trust evaluation is meaningful.
  /// Forbidden from reaching Active.
  invalid,
}

/// Category of trust/security signal evaluated by the Trust Gate.
enum TrustSignalType {
  manifestIntegrity,
  contractValidation,
  capabilityGating,
  permissionAuthorization,
  dependencyTrust,
  configurationSafety,
  resourceSafety,
  provenance,
}

/// Status of an individual trust check signal.
enum TrustSignalStatus {
  passed,
  riskWarning,
  failed,
  skipped,
}

/// Structured finding for an individual check evaluated during trust verification.
class TrustFinding {
  final TrustSignalType signalType;
  final TrustSignalStatus status;
  final String checkName;
  final String description;
  final String? remediation;

  const TrustFinding({
    required this.signalType,
    required this.status,
    required this.checkName,
    required this.description,
    this.remediation,
  });

  Map<String, dynamic> toJson() => {
        'signalType': signalType.name,
        'status': status.name,
        'checkName': checkName,
        'description': description,
        if (remediation != null) 'remediation': remediation,
      };

  @override
  String toString() =>
      '[${signalType.name}] ${checkName} (${status.name}): $description';
}

/// Comprehensive, auditable classification result for a plugin instance.
class PluginTrustClassification {
  final String pluginId;
  final SemVer version;
  final PluginTrustLevel trustLevel;
  final List<TrustFinding> findings;
  final String summary;
  final DateTime evaluatedAt;

  PluginTrustClassification({
    required this.pluginId,
    required this.version,
    required this.trustLevel,
    required List<TrustFinding> findings,
    required this.summary,
    DateTime? evaluatedAt,
  })  : findings = List.unmodifiable(findings),
        evaluatedAt = evaluatedAt ?? DateTime.now();

  /// Whether the plugin is allowed to reach Active state (requires operator ack if restricted).
  bool get isEligibleForActivation =>
      trustLevel == PluginTrustLevel.trusted ||
      trustLevel == PluginTrustLevel.validated ||
      trustLevel == PluginTrustLevel.restricted;

  /// Whether reaching Active requires explicit operator acknowledgment.
  bool get requiresOperatorAcknowledgment =>
      trustLevel == PluginTrustLevel.restricted;

  /// Whether reaching Active can proceed directly on the normal path.
  bool get canActivateDirectly =>
      trustLevel == PluginTrustLevel.trusted ||
      trustLevel == PluginTrustLevel.validated;

  /// Whether the plugin is completely blocked or invalid.
  bool get isHardBlocked =>
      trustLevel == PluginTrustLevel.blocked ||
      trustLevel == PluginTrustLevel.invalid;

  Map<String, dynamic> toJson() => {
        'pluginId': pluginId,
        'version': version.toString(),
        'trustLevel': trustLevel.name,
        'isEligibleForActivation': isEligibleForActivation,
        'requiresOperatorAcknowledgment': requiresOperatorAcknowledgment,
        'summary': summary,
        'evaluatedAt': evaluatedAt.toIso8601String(),
        'findings': findings.map((f) => f.toJson()).toList(),
      };

  static String computeManifestChecksum(String content) {
    return crypto.sha256.convert(utf8.encode(content.trim())).toString();
  }
}
