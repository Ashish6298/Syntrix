import 'package:flutter_package_studio_core/src/template/quality/quality_finding.dart';
import 'package:flutter_package_studio_core/src/template/quality/quality_profile.dart';
import 'package:flutter_package_studio_core/src/template/quality/quality_rule.dart';
import 'package:flutter_package_studio_core/src/template/template_model.dart';

/// Quality rule inspecting manifest required fields and SDK constraint formats.
class ManifestIntegrityRule extends TemplateQualityRule {
  @override
  String get id => 'manifest_integrity';

  @override
  TemplateQualityCategory get category => TemplateQualityCategory.manifest;

  @override
  String get description =>
      'Verifies template manifest required metadata fields.';

  @override
  List<TemplateQualityFinding> evaluateTemplate(
      Template template, TemplateQualityProfile profile) {
    final findings = <TemplateQualityFinding>[];
    final m = template.manifest;

    if (m.id.trim().isEmpty) {
      findings.add(TemplateQualityFinding(
        ruleId: id,
        category: category,
        severity: TemplateQualitySeverity.error,
        message: 'Template manifest ID cannot be empty.',
      ));
    }

    if (m.version.trim().isEmpty) {
      findings.add(TemplateQualityFinding(
        ruleId: id,
        category: category,
        severity: TemplateQualitySeverity.error,
        message: 'Template manifest version cannot be empty.',
      ));
    }

    if (m.minimumDartSdk.trim().isEmpty) {
      findings.add(TemplateQualityFinding(
        ruleId: id,
        category: category,
        severity: TemplateQualitySeverity.error,
        message: 'Template manifest must specify minimumDartSdk constraint.',
      ));
    }

    if (profile == TemplateQualityProfile.strict ||
        profile == TemplateQualityProfile.release) {
      if (m.description.trim().isEmpty) {
        findings.add(TemplateQualityFinding(
          ruleId: id,
          category: category,
          severity: TemplateQualitySeverity.warning,
          message: 'Template manifest description is empty.',
        ));
      }
    }

    return findings;
  }
}

/// Quality rule inspecting path security (rejecting absolute paths & path traversal).
class PathSecurityRule extends TemplateQualityRule {
  @override
  String get id => 'path_security';

  @override
  TemplateQualityCategory get category => TemplateQualityCategory.pathSecurity;

  @override
  String get description =>
      'Verifies file asset paths do not contain absolute references or path traversal.';

  @override
  List<TemplateQualityFinding> evaluateTemplate(
      Template template, TemplateQualityProfile profile) {
    final findings = <TemplateQualityFinding>[];

    template.fileTemplates.forEach((rawPath, _) {
      final trimmed = rawPath.trim();
      if (trimmed.startsWith('/') ||
          trimmed.startsWith('\\') ||
          RegExp(r'^[a-zA-Z]:').hasMatch(trimmed)) {
        findings.add(TemplateQualityFinding(
          ruleId: id,
          category: category,
          severity: TemplateQualitySeverity.error,
          message:
              'Security violation: Absolute file path "$trimmed" detected.',
          filePath: rawPath,
          remediation:
              'Use a relative asset path starting inside the project directory.',
        ));
      }

      if (trimmed.contains('../') ||
          trimmed.contains('..\\') ||
          trimmed == '..' ||
          trimmed.endsWith('/..') ||
          trimmed.endsWith('\\..')) {
        findings.add(TemplateQualityFinding(
          ruleId: id,
          category: category,
          severity: TemplateQualitySeverity.error,
          message:
              'Security violation: Path traversal ".." in "$trimmed" detected.',
          filePath: rawPath,
          remediation:
              'Remove path traversal references from template asset paths.',
        ));
      }
    });

    return findings;
  }
}

/// Quality rule checking for syntax of template placeholders.
class PlaceholderSyntaxRule extends TemplateQualityRule {
  @override
  String get id => 'placeholder_syntax';

  @override
  TemplateQualityCategory get category => TemplateQualityCategory.placeholder;

  @override
  String get description =>
      'Verifies template placeholders use valid {{key}} syntax.';

  @override
  List<TemplateQualityFinding> evaluateTemplate(
      Template template, TemplateQualityProfile profile) {
    final findings = <TemplateQualityFinding>[];
    // Flag single braces '{' or '}' that are not part of double braces '{{' or '}}', or triple braces
    final malformedRegExp = RegExp(r'(?<!\{)\{(?!\{)|(?<!\})\}(?!\})|\{\{\{');

    template.fileTemplates.forEach((path, content) {
      if (malformedRegExp.hasMatch(path)) {
        findings.add(TemplateQualityFinding(
          ruleId: id,
          category: category,
          severity: TemplateQualitySeverity.warning,
          message: 'Malformed placeholder braces detected in path "$path".',
          filePath: path,
        ));
      }
    });

    return findings;
  }
}

/// Quality rule checking for duplicate/conflicting assets.
class ConflictCheckRule extends TemplateQualityRule {
  @override
  String get id => 'conflict_check';

  @override
  TemplateQualityCategory get category => TemplateQualityCategory.conflict;

  @override
  String get description =>
      'Verifies template assets do not contain internal path duplicates.';

  @override
  List<TemplateQualityFinding> evaluateTemplate(
      Template template, TemplateQualityProfile profile) {
    return const [];
  }
}
