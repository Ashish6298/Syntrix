/// Abstract contract for individual template test cases.
library;

import 'dart:async';
import 'package:flutter_package_studio_core/src/template/testing/test_finding.dart';
import 'package:flutter_package_studio_core/src/template/testing/test_harness.dart';
import 'package:flutter_package_studio_core/src/template/testing/test_request.dart';
import 'package:flutter_package_studio_core/src/template/testing/test_result.dart';
import 'package:flutter_package_studio_core/src/template/testing/test_status.dart';

/// Contract for individual test implementations within the Template Testing Framework.
abstract class TemplateTest {
  /// Unique test identifier.
  String get id;

  /// Human-readable test name.
  String get name;

  /// Test category.
  TemplateTestCategory get category;

  /// Test description.
  String get description;

  /// Profiles under which this test should be executed.
  List<TemplateTestProfile> get supportedProfiles => [
        TemplateTestProfile.basic,
        TemplateTestProfile.standard,
        TemplateTestProfile.strict,
        TemplateTestProfile.release,
      ];

  /// Executes test logic using [harness] against [request].
  FutureOr<TemplateTestResult> run(
    TemplateTestHarness harness,
    TemplateTestRequest request,
  );
}
