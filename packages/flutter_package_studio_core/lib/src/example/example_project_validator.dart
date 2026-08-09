import 'package:flutter_package_studio_core/src/utils/file_utils.dart';
import 'package:flutter_package_studio_core/src/validation/validators.dart';

/// Inspects a generated or existing Flutter example application and verifies structural integrity.
class ExampleProjectValidator {
  final FileUtils _fileUtils;

  /// Creates an [ExampleProjectValidator] with dependency on [_fileUtils].
  const ExampleProjectValidator({FileUtils fileUtils = const SystemFileUtils()})
      : _fileUtils = fileUtils;

  /// Validates structural integrity of an example application at [exampleDirPath].
  ValidationResult validate(String exampleDirPath,
      {required String expectedPackageName}) {
    final errors = <String>[];

    if (!_fileUtils.exists(exampleDirPath)) {
      return ValidationResult.failure(
          ['Example directory does not exist at "$exampleDirPath".']);
    }

    final pubspecPath = '$exampleDirPath/pubspec.yaml';
    if (!_fileUtils.exists(pubspecPath)) {
      errors.add('Missing pubspec.yaml in example application directory.');
    } else {
      final pubspecContent = _fileUtils.readAsString(pubspecPath);
      if (!pubspecContent.contains('$expectedPackageName:')) {
        errors.add(
            'pubspec.yaml does not contain dependency on parent package "$expectedPackageName".');
      }
      if (!pubspecContent.contains('path: ../')) {
        errors.add(
            'pubspec.yaml does not contain safe relative path dependency "path: ../".');
      }
    }

    final mainDartPath = '$exampleDirPath/lib/main.dart';
    if (!_fileUtils.exists(mainDartPath)) {
      errors.add('Missing entry point lib/main.dart in example application.');
    }

    if (errors.isNotEmpty) {
      return ValidationResult.failure(errors);
    }
    return ValidationResult.success();
  }
}
