/// Registry holding template tests.
library;

import 'package:flutter_package_studio_core/src/template/testing/rules/template_tests.dart';
import 'package:flutter_package_studio_core/src/template/testing/template_test_contract.dart';
import 'package:flutter_package_studio_core/src/template/testing/test_status.dart';

/// Registry holding registered [TemplateTest] cases.
class TemplateTestRegistry {
  final Map<String, TemplateTest> _tests = {};

  /// Creates a [TemplateTestRegistry] registering default tests.
  TemplateTestRegistry({bool registerDefaults = true}) {
    if (registerDefaults) {
      register(ManifestSchemaTest());
      register(SemverValidityTest());
      register(SdkCompatibilityTest());
      register(PathSecurityTest());
      register(QualityEngineVerificationTest());
      register(CertificationEligibilityTest());
    }
  }

  /// Registers a new [TemplateTest].
  void register(TemplateTest test) {
    _tests[test.id] = test;
  }

  /// Returns `true` if test with [id] is registered.
  bool contains(String id) => _tests.containsKey(id);

  /// Returns list of all registered tests sorted by ID.
  List<TemplateTest> listTests() {
    final list = _tests.values.toList();
    list.sort((a, b) => a.id.compareTo(b.id));
    return List.unmodifiable(list);
  }

  /// Returns list of tests supported under [profile].
  List<TemplateTest> listTestsForProfile(TemplateTestProfile profile) {
    final list = _tests.values
        .where((t) => t.supportedProfiles.contains(profile))
        .toList();
    list.sort((a, b) => a.id.compareTo(b.id));
    return List.unmodifiable(list);
  }
}
