import 'package:flutter_package_studio_core/src/template/quality/quality_rule.dart';
import 'package:flutter_package_studio_core/src/template/quality/rules/quality_rules.dart';

/// Registry holding executable template quality rules.
class QualityRuleRegistry {
  final Map<String, TemplateQualityRule> _rules = {};

  QualityRuleRegistry() {
    register(ManifestIntegrityRule());
    register(PathSecurityRule());
    register(PlaceholderSyntaxRule());
    register(ConflictCheckRule());
  }

  void register(TemplateQualityRule rule) {
    _rules[rule.id] = rule;
  }

  List<TemplateQualityRule> get allRules => List.unmodifiable(_rules.values);
}
