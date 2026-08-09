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

/// Thrown when input validation fails.
class ValidationException extends PackageStudioException {
  /// Creates a [ValidationException] with the given [message] and details.
  ValidationException(super.message, [super.details, super.stackTrace]);
}

/// Thrown when a validation rule execution fails unexpectedly.
class ValidationRuleException extends ValidationException {
  /// Creates a [ValidationRuleException] with the given [message] and details.
  ValidationRuleException(super.message, [super.details, super.stackTrace]);
}

/// Thrown when external validation tooling process fails.
class ValidationToolException extends ValidationException {
  /// Creates a [ValidationToolException] with the given [message] and details.
  ValidationToolException(super.message, [super.details, super.stackTrace]);
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

/// Thrown when template manifest parsing, template loading, placeholder rendering, or generation fails.
class TemplateException extends PackageStudioException {
  /// Creates a [TemplateException] with the given [message] and details.
  TemplateException(super.message, [super.details, super.stackTrace]);
}

/// Thrown when repository options resolution or generation fails.
class RepositoryException extends PackageStudioException {
  /// Creates a [RepositoryException] with the given [message] and details.
  RepositoryException(super.message, [super.details, super.stackTrace]);
}

/// Thrown when Git verification, command execution, or initialization fails.
class GitException extends PackageStudioException {
  /// Creates a [GitException] with the given [message] and details.
  GitException(super.message, [super.details, super.stackTrace]);
}

/// Thrown when license resolution or rendering fails.
class LicenseException extends PackageStudioException {
  /// Creates a [LicenseException] with the given [message] and details.
  LicenseException(super.message, [super.details, super.stackTrace]);
}

/// Thrown when example application configuration, planning, or generation fails.
class ExampleGenerationException extends PackageStudioException {
  /// Creates an [ExampleGenerationException] with the given [message] and details.
  ExampleGenerationException(super.message, [super.details, super.stackTrace]);
}

/// Thrown when example template loading or rendering fails.
class ExampleTemplateException extends PackageStudioException {
  /// Creates an [ExampleTemplateException] with the given [message] and details.
  ExampleTemplateException(super.message, [super.details, super.stackTrace]);
}

/// Base exception for GitHub API, credential, or remote execution errors.
class GitHubException extends PackageStudioException {
  /// Creates a [GitHubException] with the given [message] and details.
  GitHubException(super.message, [super.details, super.stackTrace]);
}

/// Thrown when GitHub credentials or tokens are missing or invalid.
class GitHubAuthenticationException extends GitHubException {
  /// Creates a [GitHubAuthenticationException].
  GitHubAuthenticationException(super.message,
      [super.details, super.stackTrace]);
}

/// Thrown when authorization or scope permissions fail on GitHub.
class GitHubAuthorizationException extends GitHubException {
  /// Creates a [GitHubAuthorizationException].
  GitHubAuthorizationException(super.message,
      [super.details, super.stackTrace]);
}

/// Thrown when network connectivity to GitHub API fails.
class GitHubNetworkException extends GitHubException {
  /// Creates a [GitHubNetworkException].
  GitHubNetworkException(super.message, [super.details, super.stackTrace]);
}

/// Thrown when a remote GitHub repository already exists on conflict.
class GitHubRepositoryExistsException extends GitHubException {
  /// Creates a [GitHubRepositoryExistsException].
  GitHubRepositoryExistsException(super.message,
      [super.details, super.stackTrace]);
}

/// Thrown when GitHub options or configuration is invalid.
class GitHubConfigurationException extends GitHubException {
  /// Creates a [GitHubConfigurationException].
  GitHubConfigurationException(super.message,
      [super.details, super.stackTrace]);
}
