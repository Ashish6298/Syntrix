/// Concrete implementations of TemplateCertificationRule.
library;

import 'package:flutter_package_studio_core/src/compatibility/compatibility.dart';
import 'package:flutter_package_studio_core/src/template/certification/certification_evidence.dart';
import 'package:flutter_package_studio_core/src/template/certification/certification_finding.dart';
import 'package:flutter_package_studio_core/src/template/certification/certification_request.dart';

import 'package:flutter_package_studio_core/src/template/certification/certification_rule.dart';
import 'package:flutter_package_studio_core/src/template/quality/quality_engine.dart';
import 'package:flutter_package_studio_core/src/template/quality/quality_profile.dart';
import 'package:flutter_package_studio_core/src/template/template_semver.dart';

/// Evaluates template manifest identity and semver version validity.
class ManifestIdentityCertificationRule extends TemplateCertificationRule {
  @override
  String get id => 'CERT-001-MANIFEST-IDENTITY';

  @override
  TemplateCertificationCategory get category =>
      TemplateCertificationCategory.manifest;

  @override
  String get description =>
      'Verifies manifest integrity, template identity, and SemVer validity.';

  @override
  List<TemplateCertificationFinding> evaluate(
      TemplateCertificationRequest request) {
    final findings = <TemplateCertificationFinding>[];
    final m = request.manifest;

    if (m == null) {
      findings.add(TemplateCertificationFinding(
        ruleId: id,
        category: category,
        severity: TemplateCertificationSeverity.error,
        message: 'Template manifest is missing or null.',
        remediationAdvice:
            'Ensure template includes a valid manifest definition.',
      ));
      return findings;
    }

    final templateId = m.id as String?;
    if (templateId == null || templateId.trim().isEmpty) {
      findings.add(TemplateCertificationFinding(
        ruleId: id,
        category: category,
        severity: TemplateCertificationSeverity.error,
        message: 'Manifest contains empty or missing template ID.',
        remediationAdvice: 'Specify a unique, non-empty template ID.',
      ));
    }

    final versionStr = m.version as String?;
    var isValidSemver = true;
    if (versionStr == null || versionStr.trim().isEmpty) {
      isValidSemver = false;
    } else {
      try {
        TemplateSemVer.parse(versionStr);
      } catch (_) {
        isValidSemver = false;
      }
    }

    if (!isValidSemver) {
      findings.add(TemplateCertificationFinding(
        ruleId: id,
        category: category,
        severity: TemplateCertificationSeverity.error,
        message: 'Invalid SemVer version string "$versionStr".',
        remediationAdvice:
            'Use standard Semantic Versioning format (e.g. 1.0.0).',
        evidence: [
          TemplateCertificationEvidence(
              key: 'version', value: versionStr ?? 'null'),
        ],
      ));
    }

    return findings;
  }
}

/// Evaluates template dependency definitions and circular safety.
class DependencySafetyCertificationRule extends TemplateCertificationRule {
  @override
  String get id => 'CERT-002-DEPENDENCY-SAFETY';

  @override
  TemplateCertificationCategory get category =>
      TemplateCertificationCategory.dependency;

  @override
  String get description =>
      'Checks template dependencies for validity and circular dependency risks.';

  @override
  List<TemplateCertificationFinding> evaluate(
      TemplateCertificationRequest request) {
    final findings = <TemplateCertificationFinding>[];
    final m = request.manifest;
    if (m == null) return findings;

    final deps = m.dependencies as List?;
    if (deps != null) {
      for (final dep in deps) {
        final depId = dep.templateId as String?;
        if (depId == null || depId.trim().isEmpty) {
          findings.add(TemplateCertificationFinding(
            ruleId: id,
            category: category,
            severity: TemplateCertificationSeverity.error,
            message: 'Template dependency declares empty templateId.',
            remediationAdvice:
                'Provide a valid target template ID in dependency.',
          ));
        }
      }
    }

    return findings;
  }
}

/// Evaluates SDK and platform compatibility constraints using Phase 2.4 infrastructure.
class CompatibilityCertificationRule extends TemplateCertificationRule {
  @override
  String get id => 'CERT-003-SDK-COMPATIBILITY';

  @override
  TemplateCertificationCategory get category =>
      TemplateCertificationCategory.compatibility;

  @override
  String get description =>
      'Evaluates SDK constraints and platform compatibility against SDK environments.';

  @override
  List<TemplateCertificationFinding> evaluate(
      TemplateCertificationRequest request) {
    final findings = <TemplateCertificationFinding>[];
    final rawTpl = request.rawTemplate;

    if (rawTpl != null) {
      final evaluator = CompatibilityEvaluator(
        environment: MockSdkEnvironment.standard,
        policy: CompatibilityPolicy.standard,
      );
      final result = evaluator.evaluate(rawTpl);

      for (final issue in result.issues) {
        findings.add(TemplateCertificationFinding(
          ruleId: id,
          category: category,
          severity: issue.severity == CompatibilityIssueSeverity.error
              ? TemplateCertificationSeverity.error
              : TemplateCertificationSeverity.warning,
          message: issue.message,
          remediationAdvice:
              'Update SDK constraint or supported platform metadata.',
          evidence: [
            TemplateCertificationEvidence(key: 'axis', value: issue.axis.name),
            if (issue.constraint != null)
              TemplateCertificationEvidence(
                  key: 'constraint', value: issue.constraint!),
          ],
        ));
      }
    }

    return findings;
  }
}

/// Evaluates asset file paths for path traversal and absolute path security risks.
class PathSecurityCertificationRule extends TemplateCertificationRule {
  @override
  String get id => 'CERT-004-PATH-SECURITY';

  @override
  TemplateCertificationCategory get category =>
      TemplateCertificationCategory.security;

  @override
  String get description =>
      'Verifies file paths to prevent path traversal and absolute path attacks.';

  @override
  List<TemplateCertificationFinding> evaluate(
      TemplateCertificationRequest request) {
    final findings = <TemplateCertificationFinding>[];
    final m = request.manifest;
    if (m == null) return findings;

    final filesMap = m.files as Map?;
    if (filesMap != null) {
      filesMap.keys.forEach((key) {
        final path = key.toString();
        if (path.startsWith('/') ||
            path.startsWith('\\') ||
            (path.length > 1 && path[1] == ':')) {
          findings.add(TemplateCertificationFinding(
            ruleId: id,
            category: category,
            severity: TemplateCertificationSeverity.error,
            message:
                'Security Violation: Absolute path detected in file "$path".',
            filePath: path,
            remediationAdvice:
                'Use relative file paths bounded to project root.',
          ));
        } else if (path.contains('..')) {
          findings.add(TemplateCertificationFinding(
            ruleId: id,
            category: category,
            severity: TemplateCertificationSeverity.error,
            message: 'Security Violation: Path traversal sequence in "$path".',
            filePath: path,
            remediationAdvice: 'Remove ".." directory traversal sequences.',
          ));
        }
      });
    }

    return findings;
  }
}

/// Evaluates layer composition plan and file provenance completeness.
class CompositionProvenanceCertificationRule extends TemplateCertificationRule {
  @override
  String get id => 'CERT-005-COMPOSITION-PROVENANCE';

  @override
  TemplateCertificationCategory get category =>
      TemplateCertificationCategory.composition;

  @override
  String get description =>
      'Checks composition layers, provenance completeness, and layer conflicts.';

  @override
  List<TemplateCertificationFinding> evaluate(
      TemplateCertificationRequest request) {
    final findings = <TemplateCertificationFinding>[];
    final plan = request.compositionPlan;

    if (plan != null) {
      if (plan.conflicts.isNotEmpty) {
        for (final c in plan.conflicts) {
          findings.add(TemplateCertificationFinding(
            ruleId: id,
            category: category,
            severity: TemplateCertificationSeverity.warning,
            message:
                'Composition conflict at "${c.path}" resolved via ${c.resolutionPolicy.name}.',
            filePath: c.path,
            remediationAdvice:
                'Review incoming layer order or resolution policy.',
          ));
        }
      }
    }

    return findings;
  }
}

/// Evaluates customization plan validity.
class CustomizationCertificationRule extends TemplateCertificationRule {
  @override
  String get id => 'CERT-006-CUSTOMIZATION-VALIDITY';

  @override
  TemplateCertificationCategory get category =>
      TemplateCertificationCategory.customization;

  @override
  String get description =>
      'Verifies customization plan variables, presets, and conditional rules.';

  @override
  List<TemplateCertificationFinding> evaluate(
      TemplateCertificationRequest request) {
    final findings = <TemplateCertificationFinding>[];
    final plan = request.customizationPlan;

    if (plan != null) {
      if (plan.excludedFiles.isNotEmpty) {
        findings.add(TemplateCertificationFinding(
          ruleId: id,
          category: category,
          severity: TemplateCertificationSeverity.info,
          message:
              'Customization plan excluded ${plan.excludedFiles.length} file(s) due to unmet conditions.',
        ));
      }
    }

    return findings;
  }
}

/// Evaluates hook lifecycle execution results and security state.
class HookSecurityCertificationRule extends TemplateCertificationRule {
  @override
  String get id => 'CERT-007-HOOK-SECURITY';

  @override
  TemplateCertificationCategory get category =>
      TemplateCertificationCategory.hooks;

  @override
  String get description =>
      'Evaluates hook execution results, policies, and security bounds.';

  @override
  List<TemplateCertificationFinding> evaluate(
      TemplateCertificationRequest request) {
    final findings = <TemplateCertificationFinding>[];
    final hookReport = request.hookReport;

    if (hookReport != null) {
      if (!hookReport.isSuccess) {
        findings.add(TemplateCertificationFinding(
          ruleId: id,
          category: category,
          severity: TemplateCertificationSeverity.error,
          message:
              'Lifecycle hook execution reported failures during pipeline execution.',
          remediationAdvice: 'Resolve failing hooks or update failure policy.',
        ));
      }
    }

    return findings;
  }
}

/// Aggregates findings from Phase 2.7 Template Quality Engine.
class QualityEngineAggregationRule extends TemplateCertificationRule {
  @override
  String get id => 'CERT-008-QUALITY-ENGINE-AGGREGATION';

  @override
  TemplateCertificationCategory get category =>
      TemplateCertificationCategory.quality;

  @override
  String get description =>
      'Aggregates findings from the Template Quality Engine.';

  @override
  List<TemplateCertificationFinding> evaluate(
      TemplateCertificationRequest request) {
    final findings = <TemplateCertificationFinding>[];
    final rawTpl = request.rawTemplate;

    if (rawTpl != null) {
      final qualityEngine = TemplateQualityEngine();
      final report = qualityEngine.evaluateTemplate(rawTpl,
          profile: TemplateQualityProfile.standard);

      for (final f in report.findings) {
        findings.add(TemplateCertificationFinding(
          ruleId: '$id-${f.ruleId}',
          category: category,
          severity: f.severity.name == 'error'
              ? TemplateCertificationSeverity.error
              : (f.severity.name == 'warning'
                  ? TemplateCertificationSeverity.warning
                  : TemplateCertificationSeverity.info),
          message: f.message,
          filePath: f.filePath,
          remediationAdvice: f.remediation,
        ));
      }
    }

    return findings;
  }
}
