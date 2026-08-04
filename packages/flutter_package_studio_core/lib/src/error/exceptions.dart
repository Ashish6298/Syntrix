/// Contains the centralized exception hierarchy for the Flutter Package Studio.
library;

/// Base exception class for all errors in the application.
abstract class PackageStudioException implements Exception {
  /// The user-facing error message.
  final String message;

  /// Optional diagnostic details for debugging.
  final Object? details;

  /// Optional stack trace associated with this exception.
  final StackTrace? stackTrace;

  /// Creates a new [PackageStudioException] with the given [message], optional [details], and optional [stackTrace].
  PackageStudioException(this.message, [this.details, this.stackTrace]);

  @override
  String toString() {
    if (details != null) {
      return '$message\nDetails: $details';
    }
    return message;
  }
}

/// Thrown when configuration loading, parsing, or validation fails.
class ConfigurationException extends PackageStudioException {
  /// Creates a [ConfigurationException] with the given [message] and details.
  ConfigurationException(super.message, [super.details, super.stackTrace]);
}

/// Thrown when validation of parameters, inputs, or models fails.
class ValidationException extends PackageStudioException {
  /// Creates a [ValidationException] with the given [message] and details.
  ValidationException(super.message, [super.details, super.stackTrace]);
}

/// Thrown when command execution or CLI argument parsing fails.
class CommandException extends PackageStudioException {
  /// Creates a [CommandException] with the given [message] and details.
  CommandException(super.message, [super.details, super.stackTrace]);
}

/// Thrown when a dependency cannot be resolved or registered.
class DependencyException extends PackageStudioException {
  /// Creates a [DependencyException] with the given [message] and details.
  DependencyException(super.message, [super.details, super.stackTrace]);
}

/// Thrown when file system or I/O operations fail.
class StudioFileSystemException extends PackageStudioException {
  /// Creates a [StudioFileSystemException] with the given [message] and details.
  StudioFileSystemException(super.message, [super.details, super.stackTrace]);
}
