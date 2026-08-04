import 'package:flutter_package_studio_core/src/utils/file_utils.dart';
import 'package:flutter_package_studio_core/src/utils/version_utils.dart';

/// The result of executing a validation operation.
class ValidationResult {
  /// Whether the validation succeeded.
  final bool isValid;

  /// List of human-readable error messages if validation failed.
  final List<String> errors;

  /// Creates a [ValidationResult] manually.
  const ValidationResult({required this.isValid, required this.errors});

  /// Creates a successful [ValidationResult].
  factory ValidationResult.success() =>
      const ValidationResult(isValid: true, errors: []);

  /// Creates a failed [ValidationResult] with the given [errors].
  factory ValidationResult.failure(List<String> errors) =>
      ValidationResult(isValid: false, errors: errors);

  /// Combines this result with [other].
  ValidationResult merge(ValidationResult other) {
    if (isValid && other.isValid) return this;
    return ValidationResult(
      isValid: false,
      errors: [...errors, ...other.errors],
    );
  }
}

/// Interface for executing validation rules.
abstract interface class Validator<T> {
  /// Validates [value] and returns a [ValidationResult].
  ValidationResult validate(T value);
}

/// Chains multiple validators of the same type sequentially.
class CompositeValidator<T> implements Validator<T> {
  final List<Validator<T>> _validators;

  /// Creates a [CompositeValidator] wrapping [_validators].
  CompositeValidator(this._validators);

  @override
  ValidationResult validate(T value) {
    var result = ValidationResult.success();
    for (final validator in _validators) {
      result = result.merge(validator.validate(value));
    }
    return result;
  }
}

/// Validates that a string is a valid Dart/Flutter package name.
class PackageNameValidator implements Validator<String> {
  static final RegExp _validPackageNameRegExp = RegExp(r'^[a-z][a-z0-9_]*$');

  // Reserved keywords in Dart.
  static const Set<String> _reservedKeywords = {
    'abstract',
    'as',
    'assert',
    'async',
    'await',
    'break',
    'case',
    'catch',
    'class',
    'const',
    'continue',
    'covariant',
    'default',
    'deferred',
    'do',
    'dynamic',
    'else',
    'enum',
    'export',
    'extends',
    'extension',
    'external',
    'factory',
    'false',
    'final',
    'finally',
    'for',
    'function',
    'get',
    'hide',
    'if',
    'implements',
    'import',
    'in',
    'inherited',
    'inline',
    'interface',
    'is',
    'late',
    'library',
    'mixin',
    'native',
    'new',
    'next',
    'null',
    'of',
    'on',
    'operator',
    'out',
    'part',
    'patch',
    'required',
    'rethrow',
    'return',
    'set',
    'show',
    'source',
    'static',
    'super',
    'switch',
    'sync',
    'this',
    'throw',
    'true',
    'try',
    'typedef',
    'var',
    'void',
    'while',
    'with',
    'yield',
  };

  /// Creates a [PackageNameValidator] instance.
  const PackageNameValidator();

  @override
  ValidationResult validate(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return ValidationResult.failure(['Package name cannot be empty.']);
    }

    if (!_validPackageNameRegExp.hasMatch(trimmed)) {
      return ValidationResult.failure([
        'Package name "$trimmed" must consist of only lowercase letters, numbers, and underscores, and start with a letter.'
      ]);
    }

    if (_reservedKeywords.contains(trimmed)) {
      return ValidationResult.failure([
        'Package name "$trimmed" is a reserved Dart keyword and cannot be used.'
      ]);
    }

    return ValidationResult.success();
  }
}

/// Validates that a string is a valid Semantic Version (SemVer).
class SemVerValidator implements Validator<String> {
  /// Creates a [SemVerValidator] instance.
  const SemVerValidator();

  @override
  ValidationResult validate(String value) {
    if (VersionUtils.isValid(value)) {
      return ValidationResult.success();
    }
    return ValidationResult.failure(
        ['Version "$value" is not a valid semantic version (SemVer).']);
  }
}

/// Validates that a directory path exists and is a directory.
class DirectoryExistsValidator implements Validator<String> {
  final FileUtils _fileUtils;

  /// Creates a [DirectoryExistsValidator] with dependency on [_fileUtils].
  const DirectoryExistsValidator(this._fileUtils);

  @override
  ValidationResult validate(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return ValidationResult.failure(['Directory path cannot be empty.']);
    }
    if (!_fileUtils.exists(trimmed)) {
      return ValidationResult.failure(
          ['Directory at "$trimmed" does not exist.']);
    }
    if (!_fileUtils.isDirectory(trimmed)) {
      return ValidationResult.failure(['Path "$trimmed" is not a directory.']);
    }
    return ValidationResult.success();
  }
}
