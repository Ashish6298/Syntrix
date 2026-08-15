/// Built-in concrete implementations of TemplateTest.
library;

import 'package:flutter_package_studio_core/src/compatibility/compatibility.dart';
import 'package:flutter_package_studio_core/src/template/certification/certification_engine.dart';
import 'package:flutter_package_studio_core/src/template/certification/certification_profile.dart';
import 'package:flutter_package_studio_core/src/template/certification/certification_request.dart';
import 'package:flutter_package_studio_core/src/template/quality/quality_engine.dart';
import 'package:flutter_package_studio_core/src/template/quality/quality_profile.dart';
import 'package:flutter_package_studio_core/src/template/template_semver.dart';
import 'package:flutter_package_studio_core/src/template/testing/template_test_contract.dart';
import 'package:flutter_package_studio_core/src/template/testing/test_assertion.dart';

import 'package:flutter_package_studio_core/src/template/testing/test_finding.dart';
import 'package:flutter_package_studio_core/src/template/testing/test_harness.dart';
import 'package:flutter_package_studio_core/src/template/testing/test_request.dart';
import 'package:flutter_package_studio_core/src/template/testing/test_result.dart';
import 'package:flutter_package_studio_core/src/template/testing/test_status.dart';

/// Verifies template manifest structure and identity parameters.
class ManifestSchemaTest extends TemplateTest {
  @override
  String get id => 'TEST-001-MANIFEST-SCHEMA';

  @override
  String get name => 'Manifest Schema Test';

  @override
  TemplateTestCategory get category => TemplateTestCategory.manifest;

  @override
  String get description => 'Verifies template manifest schema and identity.';

  @override
  TemplateTestResult run(
      TemplateTestHarness harness, TemplateTestRequest request) {
    final stopwatch = Stopwatch()..start();
    final assertions = <TemplateTestAssertionResult>[];
    final findings = <TemplateTestFinding>[];

    final m = request.manifest;
    if (m == null) {
      stopwatch.stop();
      return TemplateTestResult.failed(
        testId: id,
        testName: name,
        duration: stopwatch.elapsed,
        error: 'Missing manifest',
      );
    }

    final templateId = m.id as String?;
    final hasValidId = templateId != null && templateId.trim().isNotEmpty;
    assertions.add(hasValidId
        ? TemplateTestAssertionResult.pass('Valid Template ID')
        : TemplateTestAssertionResult.fail('Valid Template ID',
            message: 'Template ID is empty or null'));

    if (!hasValidId) {
      findings.add(TemplateTestFinding(
        testId: id,
        category: category,
        severity: TemplateTestSeverity.error,
        message: 'Manifest contains empty or null template ID.',
      ));
    }

    stopwatch.stop();
    return TemplateTestResult(
      testId: id,
      testName: name,
      status: findings.any((f) => f.isError)
          ? TemplateTestStatus.failed
          : TemplateTestStatus.passed,
      duration: stopwatch.elapsed,
      assertions: assertions,
      findings: findings,
    );
  }
}

/// Verifies template SemVer version string validity.
class SemverValidityTest extends TemplateTest {
  @override
  String get id => 'TEST-002-SEMVER-VALIDITY';

  @override
  String get name => 'SemVer Validity Test';

  @override
  TemplateTestCategory get category => TemplateTestCategory.manifest;

  @override
  String get description => 'Verifies SemVer version syntax compliance.';

  @override
  TemplateTestResult run(
      TemplateTestHarness harness, TemplateTestRequest request) {
    final stopwatch = Stopwatch()..start();
    final assertions = <TemplateTestAssertionResult>[];
    final findings = <TemplateTestFinding>[];

    final m = request.manifest;
    final versionStr = m?.version as String?;

    var isValid = true;
    if (versionStr == null || versionStr.trim().isEmpty) {
      isValid = false;
    } else {
      try {
        TemplateSemVer.parse(versionStr);
      } catch (_) {
        isValid = false;
      }
    }

    assertions.add(isValid
        ? TemplateTestAssertionResult.pass('Valid SemVer')
        : TemplateTestAssertionResult.fail('Valid SemVer',
            message: 'Invalid semver version string "$versionStr"',
            actual: versionStr));

    if (!isValid) {
      findings.add(TemplateTestFinding(
        testId: id,
        category: category,
        severity: TemplateTestSeverity.error,
        message: 'Invalid SemVer format "$versionStr".',
      ));
    }

    stopwatch.stop();
    return TemplateTestResult(
      testId: id,
      testName: name,
      status: isValid ? TemplateTestStatus.passed : TemplateTestStatus.failed,
      duration: stopwatch.elapsed,
      assertions: assertions,
      findings: findings,
    );
  }
}

/// Verifies SDK and platform compatibility requirements.
class SdkCompatibilityTest extends TemplateTest {
  @override
  String get id => 'TEST-003-SDK-COMPATIBILITY';

  @override
  String get name => 'SDK Compatibility Test';

  @override
  TemplateTestCategory get category => TemplateTestCategory.compatibility;

  @override
  String get description =>
      'Evaluates SDK version constraints against environment.';

  @override
  TemplateTestResult run(
      TemplateTestHarness harness, TemplateTestRequest request) {
    final stopwatch = Stopwatch()..start();
    final assertions = <TemplateTestAssertionResult>[];
    final findings = <TemplateTestFinding>[];

    final rawTpl = request.rawTemplate;
    if (rawTpl != null) {
      final evaluator = CompatibilityEvaluator(
        environment: harness.sdkEnvironment,
        policy: CompatibilityPolicy.standard,
      );
      final result = evaluator.evaluate(rawTpl);

      assertions.add(result.isCompatible
          ? TemplateTestAssertionResult.pass('SDK Compatibility')
          : TemplateTestAssertionResult.fail('SDK Compatibility',
              message: 'Template is incompatible with SDK environment'));

      for (final issue in result.issues) {
        findings.add(TemplateTestFinding(
          testId: id,
          category: category,
          severity: issue.severity == CompatibilityIssueSeverity.error
              ? TemplateTestSeverity.error
              : TemplateTestSeverity.warning,
          message: issue.message,
        ));
      }
    }

    stopwatch.stop();
    return TemplateTestResult(
      testId: id,
      testName: name,
      status: findings.any((f) => f.isError)
          ? TemplateTestStatus.failed
          : TemplateTestStatus.passed,
      duration: stopwatch.elapsed,
      assertions: assertions,
      findings: findings,
    );
  }
}

/// Verifies path security bounds preventing absolute path and path traversal attacks.
class PathSecurityTest extends TemplateTest {
  @override
  String get id => 'TEST-004-PATH-SECURITY';

  @override
  String get name => 'Path Security Test';

  @override
  TemplateTestCategory get category => TemplateTestCategory.security;

  @override
  String get description =>
      'Checks asset relative paths for path security violations.';

  @override
  TemplateTestResult run(
      TemplateTestHarness harness, TemplateTestRequest request) {
    final stopwatch = Stopwatch()..start();
    final assertions = <TemplateTestAssertionResult>[];
    final findings = <TemplateTestFinding>[];

    final m = request.manifest;
    final filesMap = m?.files as Map?;

    var hasSecurityViolation = false;
    if (filesMap != null) {
      filesMap.keys.forEach((key) {
        final path = key.toString();
        if (path.startsWith('/') ||
            path.startsWith('\\') ||
            (path.length > 1 && path[1] == ':')) {
          hasSecurityViolation = true;
          findings.add(TemplateTestFinding(
            testId: id,
            category: category,
            severity: TemplateTestSeverity.error,
            message: 'Absolute path security violation in "$path".',
            filePath: path,
          ));
        } else if (path.contains('..')) {
          hasSecurityViolation = true;
          findings.add(TemplateTestFinding(
            testId: id,
            category: category,
            severity: TemplateTestSeverity.error,
            message: 'Path traversal sequence security violation in "$path".',
            filePath: path,
          ));
        }
      });
    }

    assertions.add(!hasSecurityViolation
        ? TemplateTestAssertionResult.pass('Path Security Sandbox')
        : TemplateTestAssertionResult.fail('Path Security Sandbox',
            message: 'Security violation detected in asset paths'));

    stopwatch.stop();
    return TemplateTestResult(
      testId: id,
      testName: name,
      status: hasSecurityViolation
          ? TemplateTestStatus.failed
          : TemplateTestStatus.passed,
      duration: stopwatch.elapsed,
      assertions: assertions,
      findings: findings,
    );
  }
}

/// Evaluates quality engine findings.
class QualityEngineVerificationTest extends TemplateTest {
  @override
  String get id => 'TEST-005-QUALITY-ENGINE';

  @override
  String get name => 'Quality Engine Verification Test';

  @override
  TemplateTestCategory get category => TemplateTestCategory.quality;

  @override
  String get description =>
      'Evaluates template quality rules via TemplateQualityEngine.';

  @override
  TemplateTestResult run(
      TemplateTestHarness harness, TemplateTestRequest request) {
    final stopwatch = Stopwatch()..start();
    final assertions = <TemplateTestAssertionResult>[];
    final findings = <TemplateTestFinding>[];

    final rawTpl = request.rawTemplate;
    if (rawTpl != null) {
      final qualityEngine = TemplateQualityEngine();
      final report = qualityEngine.evaluateTemplate(rawTpl,
          profile: TemplateQualityProfile.standard);

      assertions.add(report.isPassed
          ? TemplateTestAssertionResult.pass('Quality Engine Evaluation')
          : TemplateTestAssertionResult.fail('Quality Engine Evaluation',
              message: 'Quality engine evaluation failed'));

      for (final f in report.findings) {
        findings.add(TemplateTestFinding(
          testId: id,
          category: category,
          severity: f.severity.name == 'error'
              ? TemplateTestSeverity.error
              : (f.severity.name == 'warning'
                  ? TemplateTestSeverity.warning
                  : TemplateTestSeverity.info),
          message: f.message,
          filePath: f.filePath,
        ));
      }
    }

    stopwatch.stop();
    return TemplateTestResult(
      testId: id,
      testName: name,
      status: findings.any((f) => f.isError)
          ? TemplateTestStatus.failed
          : TemplateTestStatus.passed,
      duration: stopwatch.elapsed,
      assertions: assertions,
      findings: findings,
    );
  }
}

/// Evaluates certification eligibility.
class CertificationEligibilityTest extends TemplateTest {
  @override
  String get id => 'TEST-006-CERTIFICATION-ELIGIBILITY';

  @override
  String get name => 'Certification Eligibility Test';

  @override
  TemplateTestCategory get category => TemplateTestCategory.certification;

  @override
  String get description =>
      'Evaluates template certification readiness via TemplateCertificationEngine.';

  @override
  TemplateTestResult run(
      TemplateTestHarness harness, TemplateTestRequest request) {
    final stopwatch = Stopwatch()..start();
    final assertions = <TemplateTestAssertionResult>[];
    final findings = <TemplateTestFinding>[];

    final rawTpl = request.rawTemplate;
    if (rawTpl != null) {
      final certEngine = TemplateCertificationEngine();
      final certReq = TemplateCertificationRequest(
        rawTemplate: rawTpl,
        profile: request.profile == TemplateTestProfile.release
            ? TemplateCertificationProfile.release
            : TemplateCertificationProfile.standard,
      );
      final report = certEngine.evaluate(certReq);

      assertions.add(report.isGenerationEligible
          ? TemplateTestAssertionResult.pass('Certification Eligibility')
          : TemplateTestAssertionResult.fail('Certification Eligibility',
              message: 'Template is ineligible for certification'));

      for (final f in report.findings) {
        findings.add(TemplateTestFinding(
          testId: id,
          category: category,
          severity: f.severity.name == 'error'
              ? TemplateTestSeverity.error
              : (f.severity.name == 'warning'
                  ? TemplateTestSeverity.warning
                  : TemplateTestSeverity.info),
          message: f.message,
          filePath: f.filePath,
        ));
      }
    }

    stopwatch.stop();
    return TemplateTestResult(
      testId: id,
      testName: name,
      status: findings.any((f) => f.isError)
          ? TemplateTestStatus.failed
          : TemplateTestStatus.passed,
      duration: stopwatch.elapsed,
      assertions: assertions,
      findings: findings,
    );
  }
}
