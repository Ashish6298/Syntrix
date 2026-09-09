/// Higher-level certification service orchestrator.
library;

import 'package:syntrix/src/template/certification/certification_engine.dart';
import 'package:syntrix/src/template/certification/certification_profile.dart';
import 'package:syntrix/src/template/certification/certification_report.dart';
import 'package:syntrix/src/template/certification/certification_request.dart';
import 'package:syntrix/src/template/template_model.dart';

/// Service interface providing certification gates and pipeline certification workflows.
class TemplateCertificationService {
  final TemplateCertificationEngine _engine;

  /// Creates a [TemplateCertificationService].
  TemplateCertificationService({
    TemplateCertificationEngine? engine,
  }) : _engine = engine ?? TemplateCertificationEngine();

  /// Certifies a raw [Template] instance.
  TemplateCertificationReport certifyTemplate(
    Template template, {
    TemplateCertificationProfile profile =
        TemplateCertificationProfile.standard,
  }) {
    final req = TemplateCertificationRequest(
      rawTemplate: template,
      profile: profile,
    );
    return _engine.evaluate(req);
  }

  /// Determines whether a template is eligible for project generation based on its report.
  bool isGenerationEligible(TemplateCertificationReport report) {
    return report.isGenerationEligible;
  }
}
