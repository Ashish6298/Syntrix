/// Isolated test harness for template testing framework.
library;

import 'package:flutter_package_studio_core/src/compatibility/compatibility.dart';
import 'package:flutter_package_studio_core/src/logging/logger.dart';

import 'package:flutter_package_studio_core/src/utils/file_utils.dart';

/// Isolated execution harness managing test doubles and environment sandboxing.
class TemplateTestHarness {
  /// File utility test double.
  final FileUtils fileUtils;

  /// Isolated logger instance.
  final Logger logger;

  /// Mock SDK environment.
  final MockSdkEnvironment sdkEnvironment;

  /// Target virtual root directory.
  final String virtualTargetDirectory;

  /// Creates a [TemplateTestHarness].
  TemplateTestHarness({
    FileUtils? fileUtils,
    Logger? logger,
    MockSdkEnvironment? sdkEnvironment,
    this.virtualTargetDirectory = '/virtual/test_harness',
  })  : fileUtils = fileUtils ?? const SystemFileUtils(),
        logger = logger ?? Logger('TemplateTestHarness'),
        sdkEnvironment = sdkEnvironment ?? MockSdkEnvironment.standard;
}
