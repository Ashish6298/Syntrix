import 'package:flutter_package_studio_core/src/error/exceptions.dart';
import 'package:flutter_package_studio_core/src/testing/project/test_project_models.dart';

/// Validates package names, relative paths, and security constraints for test project generation.
class TestProjectValidator {
  static final RegExp _validPkgRegExp = RegExp(r'^[a-z][a-z0-9_]*$');

  /// Validates [options] for test project generation.
  static void validate(TestProjectOptions options) {
    if (options.packageName.isEmpty) {
      throw TestProjectGenerationException('Package name must not be empty.');
    }

    if (!_validPkgRegExp.hasMatch(options.packageName)) {
      throw TestProjectGenerationException(
          'Invalid package name "${options.packageName}". Package names must start with a lowercase letter and contain only lowercase alphanumeric characters and underscores.');
    }

    final lowerTarget = options.targetDir.toLowerCase();
    if (lowerTarget.startsWith('/') ||
        lowerTarget.startsWith(RegExp(r'^[a-z]:', caseSensitive: false))) {
      throw TestProjectGenerationException(
          'Absolute target directory paths are forbidden: "${options.targetDir}". Relative path required.');
    }

    if (lowerTarget.contains('..')) {
      throw TestProjectGenerationException(
          'Path traversal ("..") is forbidden in target directory path: "${options.targetDir}".');
    }
  }
}
