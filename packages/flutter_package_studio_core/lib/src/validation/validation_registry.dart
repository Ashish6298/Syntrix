import 'package:flutter_package_studio_core/src/validation/validation_models.dart';
import 'package:flutter_package_studio_core/src/validation/validation_rule.dart';
import 'package:flutter_package_studio_core/src/validation/rules/structure_rules.dart';
import 'package:flutter_package_studio_core/src/validation/rules/pubspec_rules.dart';
import 'package:flutter_package_studio_core/src/validation/rules/security_rules.dart';
import 'package:flutter_package_studio_core/src/validation/rules/example_rules.dart';
import 'package:flutter_package_studio_core/src/validation/rules/repository_rules.dart';

/// Registry managing injectable composable validation rules and profiles.
class ValidationRuleRegistry {
  final Map<String, ValidationRule> _rules = {};

  /// Creates a [ValidationRuleRegistry] initialized with built-in default rules.
  ValidationRuleRegistry() {
    register(PackageStructureRule());
    register(PubspecValidationRule());
    register(SecurityValidationRule());
    register(ExampleValidationRule());
    register(RepositoryAssetRule());
  }

  /// Registers a [rule].
  void register(ValidationRule rule) {
    _rules[rule.id] = rule;
  }

  /// Returns rule by [id] or `null` if un-registered.
  ValidationRule? getRule(String id) => _rules[id];

  /// Resolves rules for profile (`basic`, `standard`, `strict`, `release`).
  List<ValidationRule> resolveProfile(String profile) {
    switch (profile.toLowerCase()) {
      case 'basic':
        return _rules.values
            .where((r) =>
                r.category == ValidationCategory.structure ||
                r.category == ValidationCategory.pubspec)
            .toList();
      case 'strict':
      case 'release':
        return _rules.values.toList();
      case 'standard':
      default:
        return _rules.values.toList();
    }
  }
}
