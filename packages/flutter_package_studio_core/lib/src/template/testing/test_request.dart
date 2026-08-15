/// Template test request model.
library;

import 'package:flutter_package_studio_core/src/template/resolved_template.dart';
import 'package:flutter_package_studio_core/src/template/template_context.dart';
import 'package:flutter_package_studio_core/src/template/template_model.dart';
import 'package:flutter_package_studio_core/src/template/testing/test_status.dart';

/// Input request specifying the template and target test profile.
class TemplateTestRequest {
  /// Raw template target (if testing a single raw template).
  final Template? rawTemplate;

  /// Composed resolved template target (if testing a resolved template).
  final ResolvedTemplate? resolvedTemplate;

  /// Target testing profile.
  final TemplateTestProfile profile;

  /// Optional context variables.
  final TemplateContext? context;

  /// Flag specifying if execution is dry-run preview mode.
  final bool dryRun;

  /// Creates a [TemplateTestRequest].
  const TemplateTestRequest({
    this.rawTemplate,
    this.resolvedTemplate,
    this.profile = TemplateTestProfile.standard,
    this.context,
    this.dryRun = true,
  });

  /// Target template identifier.
  String get templateId =>
      resolvedTemplate?.id ?? rawTemplate?.id ?? 'unknown_template';

  /// Target template version.
  String get version =>
      resolvedTemplate?.version ?? rawTemplate?.version ?? '1.0.0';

  /// Primary manifest.
  dynamic get manifest =>
      resolvedTemplate?.effectiveManifest ?? rawTemplate?.manifest;
}
