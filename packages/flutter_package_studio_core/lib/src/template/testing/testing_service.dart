/// Higher-level template testing service.
library;

import 'package:flutter_package_studio_core/src/template/template_model.dart';
import 'package:flutter_package_studio_core/src/template/testing/test_engine.dart';
import 'package:flutter_package_studio_core/src/template/testing/test_report.dart';
import 'package:flutter_package_studio_core/src/template/testing/test_request.dart';
import 'package:flutter_package_studio_core/src/template/testing/test_status.dart';

/// Service providing clean testing workflows and verification decisions.
class TemplateTestingService {
  final TemplateTestEngine _engine;

  /// Creates a [TemplateTestingService].
  TemplateTestingService({
    TemplateTestEngine? engine,
  }) : _engine = engine ?? TemplateTestEngine();

  /// Runs automated test framework on [template].
  Future<TemplateTestReport> testTemplate(
    Template template, {
    TemplateTestProfile profile = TemplateTestProfile.standard,
  }) {
    final req = TemplateTestRequest(
      rawTemplate: template,
      profile: profile,
    );
    return _engine.execute(req);
  }

  /// Returns `true` if report indicates template is eligible for formal certification.
  bool isEligibleForCertification(TemplateTestReport report) {
    return report.isEligibleForCertification;
  }
}
