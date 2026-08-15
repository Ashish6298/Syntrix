/// Central registry for template certification rules.
library;

import 'package:flutter_package_studio_core/src/template/certification/certification_rule.dart';
import 'package:flutter_package_studio_core/src/template/certification/rules/certification_rules.dart';

/// Maintains registered [TemplateCertificationRule] instances.
class TemplateCertificationRuleRegistry {
  final Map<String, TemplateCertificationRule> _rules = {};

  /// Creates a [TemplateCertificationRuleRegistry] with default built-in rules.
  TemplateCertificationRuleRegistry({bool registerDefaults = true}) {
    if (registerDefaults) {
      register(ManifestIdentityCertificationRule());
      register(DependencySafetyCertificationRule());
      register(CompatibilityCertificationRule());
      register(PathSecurityCertificationRule());
      register(CompositionProvenanceCertificationRule());
      register(CustomizationCertificationRule());
      register(HookSecurityCertificationRule());
      register(QualityEngineAggregationRule());
    }
  }

  /// Registers a new [TemplateCertificationRule].
  void register(TemplateCertificationRule rule) {
    _rules[rule.id] = rule;
  }

  /// Returns `true` if rule with [id] is registered.
  bool contains(String id) => _rules.containsKey(id);

  /// Returns list of all registered rules sorted by rule ID.
  List<TemplateCertificationRule> listRules() {
    final list = _rules.values.toList();
    list.sort((a, b) => a.id.compareTo(b.id));
    return List.unmodifiable(list);
  }
}
