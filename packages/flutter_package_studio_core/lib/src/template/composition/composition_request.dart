import 'package:flutter_package_studio_core/src/compatibility/compatibility_policy.dart';
import 'package:flutter_package_studio_core/src/template/template_composition.dart';

/// Request model encapsulating all parameters for template composition.
class CompositionRequest {
  /// Primary base template ID identifier.
  final String baseTemplateId;

  /// Optional version constraint for base template.
  final String baseVersionConstraint;

  /// Ordered list of feature/extension template IDs to compose onto base.
  final List<String> extensionIds;

  /// File path conflict resolution policy.
  final OverrideStrategy conflictPolicy;

  /// Compatibility policy to apply during resolution.
  final CompatibilityPolicy compatibilityPolicy;

  /// Optional target project archetype requested.
  final String? targetProjectType;

  /// Required capability tags that must be provided by the composite template.
  final List<String> requiredCapabilities;

  const CompositionRequest({
    required this.baseTemplateId,
    this.baseVersionConstraint = '*',
    this.extensionIds = const [],
    this.conflictPolicy = OverrideStrategy.fail,
    this.compatibilityPolicy = CompatibilityPolicy.standard,
    this.targetProjectType,
    this.requiredCapabilities = const [],
  });

  @override
  String toString() =>
      'CompositionRequest(base: $baseTemplateId@$baseVersionConstraint, '
      'extensions: $extensionIds, policy: ${conflictPolicy.name})';
}
