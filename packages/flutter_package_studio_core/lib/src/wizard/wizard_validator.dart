import 'package:flutter_package_studio_core/src/utils/file_utils.dart';
import 'package:flutter_package_studio_core/src/validation/validators.dart';

/// Custom validators for numeric ranges, paths, non-empty text, and URL validation.
class WizardValidator {
  /// Ensures string input is non-empty after trimming.
  static Validator<String> requiredString([String fieldName = 'Value']) {
    return _LambdaValidator<String>((value) {
      if (value.trim().isEmpty) {
        return ValidationResult.failure(['$fieldName cannot be empty.']);
      }
      return ValidationResult.success();
    });
  }

  /// Ensures numeric input falls within [min] and [max].
  static Validator<num> numberRange({num? min, num? max}) {
    return _LambdaValidator<num>((value) {
      final errors = <String>[];
      if (min != null && value < min) {
        errors.add('Value must be greater than or equal to $min.');
      }
      if (max != null && value > max) {
        errors.add('Value must be less than or equal to $max.');
      }
      return errors.isEmpty
          ? ValidationResult.success()
          : ValidationResult.failure(errors);
    });
  }

  /// Validates optional or required URL formatting.
  static Validator<String> url({bool required = false}) {
    return _LambdaValidator<String>((value) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) {
        if (required) {
          return ValidationResult.failure(['URL is required.']);
        }
        return ValidationResult.success();
      }
      final uri = Uri.tryParse(trimmed);
      if (uri == null ||
          (uri.scheme != 'http' && uri.scheme != 'https') ||
          uri.host.isEmpty) {
        return ValidationResult.failure(
            ['"$trimmed" is not a valid HTTP/HTTPS URL.']);
      }
      return ValidationResult.success();
    });
  }

  /// Validates that input is a valid file path that exists.
  static Validator<String> fileExists(FileUtils fileUtils) {
    return _LambdaValidator<String>((value) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) {
        return ValidationResult.failure(['File path cannot be empty.']);
      }
      if (!fileUtils.exists(trimmed)) {
        return ValidationResult.failure(['File at "$trimmed" does not exist.']);
      }
      if (!fileUtils.isFile(trimmed)) {
        return ValidationResult.failure(
            ['Path "$trimmed" is not a regular file.']);
      }
      return ValidationResult.success();
    });
  }

  /// Validates email formatting.
  static Validator<String> email({bool required = false}) {
    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return _LambdaValidator<String>((value) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) {
        if (required) {
          return ValidationResult.failure(['Email address is required.']);
        }
        return ValidationResult.success();
      }
      if (!emailRegExp.hasMatch(trimmed)) {
        return ValidationResult.failure(
            ['"$trimmed" is not a valid email address.']);
      }
      return ValidationResult.success();
    });
  }
}

class _LambdaValidator<T> implements Validator<T> {
  final ValidationResult Function(T value) _fn;

  _LambdaValidator(this._fn);

  @override
  ValidationResult validate(T value) => _fn(value);
}
