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

/// Thrown when template catalog provider registration, discovery, or indexing fails.
class CatalogException extends PackageStudioException {
  /// Creates a [CatalogException] with the given [message] and details.
  CatalogException(super.message, [super.details, super.stackTrace]);
}

/// Thrown when GitHub options or configuration is invalid.
class GitHubConfigurationException extends GitHubException {
  /// Creates a [GitHubConfigurationException].
  GitHubConfigurationException(super.message,
      [super.details, super.stackTrace]);
}

// ── Remote Registry / Marketplace Exceptions ──────────────────────────────────

/// Base exception for all remote registry and marketplace errors.
///
/// All marketplace subsystem exceptions extend this class, allowing callers
/// to catch the broad category while still being able to specialize on
/// specific failure modes.
class RemoteRegistryException extends PackageStudioException {
  /// Creates a [RemoteRegistryException].
  RemoteRegistryException(super.message, [super.details, super.stackTrace]);
}

/// Thrown when a network connectivity, timeout, or transport-level failure
/// occurs while communicating with a remote registry.
class RegistryNetworkException extends RemoteRegistryException {
  /// Creates a [RegistryNetworkException].
  RegistryNetworkException(super.message, [super.details, super.stackTrace]);
}

/// Thrown when authentication with a remote registry fails (e.g., missing or
/// invalid credentials). Credentials must never appear in the exception message.
class RegistryAuthenticationException extends RemoteRegistryException {
  /// Creates a [RegistryAuthenticationException].
  RegistryAuthenticationException(super.message,
      [super.details, super.stackTrace]);
}

/// Thrown when the remote registry returns a response using an incompatible
/// or unrecognized protocol version.
class RegistryProtocolException extends RemoteRegistryException {
  /// Creates a [RegistryProtocolException].
  RegistryProtocolException(super.message, [super.details, super.stackTrace]);
}

/// Thrown when a remote template metadata record fails validation (malformed ID,
/// invalid semver, unsafe URL, unsupported project type, etc.).
class RegistryMetadataException extends RemoteRegistryException {
  /// Creates a [RegistryMetadataException].
  RegistryMetadataException(super.message, [super.details, super.stackTrace]);
}

/// Thrown when a remote registry rate-limits the client (HTTP 429 or
/// equivalent).
class RegistryRateLimitException extends RemoteRegistryException {
  /// Creates a [RegistryRateLimitException].
  RegistryRateLimitException(super.message, [super.details, super.stackTrace]);
}

/// Thrown when a registry metadata cache entry is corrupt, expired, or cannot
/// be read.
class RegistryCacheException extends RemoteRegistryException {
  /// Creates a [RegistryCacheException].
  RegistryCacheException(super.message, [super.details, super.stackTrace]);
}

/// Thrown when registry configuration (URL, identifier, options) is invalid.
class RegistryConfigurationException extends RemoteRegistryException {
  /// Creates a [RegistryConfigurationException].
  RegistryConfigurationException(super.message,
      [super.details, super.stackTrace]);
}

// ── Compatibility Engine Exceptions ───────────────────────────────────────────

/// Base exception for all Template Compatibility Engine errors.
///
/// Thrown when compatibility evaluation fails for reasons other than a simple
/// incompatibility (which is expressed as a [CompatibilityResult] with issues).
/// For example: malformed SDK constraint strings, unknown policy keys, or
/// corrupted compatibility metadata.
///
/// ## Security
/// Compatibility exceptions must never expose sensitive environment information
/// such as exact SDK install paths, build system internals, or user home
/// directories. Only version strings and constraint expressions are safe to
/// include.
class CompatibilityException extends PackageStudioException {
  /// Creates a [CompatibilityException].
  CompatibilityException(super.message, [super.details, super.stackTrace]);
}

/// Thrown when a Dart or Flutter SDK version constraint string is malformed
/// and cannot be parsed (e.g., `>=abc`, `^`, empty string after trimming).
class InvalidSdkConstraintException extends CompatibilityException {
  /// Creates an [InvalidSdkConstraintException].
  InvalidSdkConstraintException(super.message,
      [super.details, super.stackTrace]);
}

// ── Composition Engine Exceptions ─────────────────────────────────────────────

/// Base exception for all Template Composition Engine failures.
class TemplateCompositionException extends TemplateException {
  /// Creates a [TemplateCompositionException].
  TemplateCompositionException(super.message,
      [super.details, super.stackTrace]);
}

/// Thrown when an unresolved file collision occurs during template composition.
class CompositionConflictException extends TemplateCompositionException {
  /// Creates a [CompositionConflictException].
  CompositionConflictException(super.message,
      [super.details, super.stackTrace]);
}

/// Thrown when a template asset path contains invalid characters, path traversal
/// attempts (`..`), or absolute path references.
class PathSecurityException extends TemplateCompositionException {
  /// Creates a [PathSecurityException].
  PathSecurityException(super.message, [super.details, super.stackTrace]);
}

// ── Customization Engine Exceptions ───────────────────────────────────────────

/// Base exception for all Template Customization Engine failures.
class CustomizationException extends PackageStudioException {
  /// Creates a [CustomizationException].
  CustomizationException(super.message, [super.details, super.stackTrace]);
}

/// Thrown when user customization values fail schema validation (missing required value,
/// invalid type, value outside allowed choices, etc.).
class CustomizationValidationException extends CustomizationException {
  /// Creates a [CustomizationValidationException].
  CustomizationValidationException(super.message,
      [super.details, super.stackTrace]);
}

/// Thrown when customization rules or path overrides collide irreconcilably.
class CustomizationConflictException extends CustomizationException {
  /// Creates a [CustomizationConflictException].
  CustomizationConflictException(super.message,
      [super.details, super.stackTrace]);
}

/// Thrown when a customization path override attempts path traversal (`..`) or absolute pathing.
class CustomizationPathSecurityException extends CustomizationException {
  /// Creates a [CustomizationPathSecurityException].
  CustomizationPathSecurityException(super.message,
      [super.details, super.stackTrace]);
}

// ── Quality Engine Exceptions ─────────────────────────────────────────────────

/// Base exception for all Template Quality Assurance & Validation failures.
class TemplateQualityException extends TemplateException {
  /// Creates a [TemplateQualityException].
  TemplateQualityException(super.message, [super.details, super.stackTrace]);
}

/// Thrown when a template fails quality validation under a strict or release quality profile.
class TemplateQualityValidationException extends TemplateQualityException {
  /// Creates a [TemplateQualityValidationException].
  TemplateQualityValidationException(super.message,
      [super.details, super.stackTrace]);
}

// ── Hook & Lifecycle System Exceptions ────────────────────────────────────────

/// Base exception for all Template Hook & Lifecycle failures.
class TemplateHookException extends TemplateException {
  /// Creates a [TemplateHookException].
  TemplateHookException(super.message, [super.details, super.stackTrace]);
}

/// Thrown when hook execution fails or encounters an unhandled runtime error.
class TemplateHookExecutionException extends TemplateHookException {
  /// Creates a [TemplateHookExecutionException].
  TemplateHookExecutionException(super.message,
      [super.details, super.stackTrace]);
}

/// Thrown when a hook attempts unauthorized operations, path traversal, sandbox escape, or secret leak.
class TemplateHookSecurityException extends TemplateHookException {
  /// Creates a [TemplateHookSecurityException].
  TemplateHookSecurityException(super.message,
      [super.details, super.stackTrace]);
}

/// Thrown when hook metadata, registration, or phase assignment is invalid.
class TemplateHookValidationException extends TemplateHookException {
  /// Creates a [TemplateHookValidationException].
  TemplateHookValidationException(super.message,
      [super.details, super.stackTrace]);
}

/// Thrown when hook dependency resolution fails or circular dependencies are detected.
class TemplateHookDependencyException extends TemplateHookException {
  /// Creates a [TemplateHookDependencyException].
  TemplateHookDependencyException(super.message,
      [super.details, super.stackTrace]);
}

/// Thrown when a hook execution exceeds its maximum allowed duration.
class TemplateHookTimeoutException extends TemplateHookException {
  /// Creates a [TemplateHookTimeoutException].
  TemplateHookTimeoutException(super.message,
      [super.details, super.stackTrace]);
}

// ── Certification Engine Exceptions ──────────────────────────────────────────

/// Base exception for all Template Certification System failures.
class TemplateCertificationException extends TemplateException {
  /// Creates a [TemplateCertificationException].
  TemplateCertificationException(super.message,
      [super.details, super.stackTrace]);
}

/// Thrown when template certification validation fails or certification gates are violated.
class TemplateCertificationValidationException
    extends TemplateCertificationException {
  /// Creates a [TemplateCertificationValidationException].
  TemplateCertificationValidationException(super.message,
      [super.details, super.stackTrace]);
}

// ── Testing Framework Exceptions ──────────────────────────────────────────────

/// Base exception for all Template Testing Framework failures.
class TemplateTestingException extends TemplateException {
  /// Creates a [TemplateTestingException].
  TemplateTestingException(super.message, [super.details, super.stackTrace]);
}

/// Thrown when template test configuration or test case definition is invalid.
class TemplateTestConfigurationException extends TemplateTestingException {
  /// Creates a [TemplateTestConfigurationException].
  TemplateTestConfigurationException(super.message,
      [super.details, super.stackTrace]);
}

/// Thrown when a template test fails during execution unexpectedly.
class TemplateTestExecutionException extends TemplateTestingException {
  /// Creates a [TemplateTestExecutionException].
  TemplateTestExecutionException(super.message,
      [super.details, super.stackTrace]);
}

/// Thrown when a template test assertion expectation fails.
class TemplateTestAssertionException extends TemplateTestingException {
  /// Creates a [TemplateTestAssertionException].
  TemplateTestAssertionException(super.message,
      [super.details, super.stackTrace]);
}

// ── Migration System Exceptions ───────────────────────────────────────────────

/// Base exception for all Template Upgrade & Migration System failures.
class TemplateMigrationException extends PackageStudioException {
  /// Creates a [TemplateMigrationException].
  TemplateMigrationException(super.message, [super.details, super.stackTrace]);
}

/// Thrown when migration configuration or request parameters are invalid.
class TemplateMigrationConfigurationException
    extends TemplateMigrationException {
  /// Creates a [TemplateMigrationConfigurationException].
  TemplateMigrationConfigurationException(super.message,
      [super.details, super.stackTrace]);
}

/// Thrown when no valid migration path can be resolved or planning fails.
class TemplateMigrationPlanningException extends TemplateMigrationException {
  /// Creates a [TemplateMigrationPlanningException].
  TemplateMigrationPlanningException(super.message,
      [super.details, super.stackTrace]);
}

/// Thrown when a file or metadata conflict occurs during migration.
class TemplateMigrationConflictException extends TemplateMigrationException {
  /// Creates a [TemplateMigrationConflictException].
  TemplateMigrationConflictException(super.message,
      [super.details, super.stackTrace]);
}

/// Thrown when a migration action violates path security boundaries (absolute path, traversal).
class TemplateMigrationSecurityException extends TemplateMigrationException {
  /// Creates a [TemplateMigrationSecurityException].
  TemplateMigrationSecurityException(super.message,
      [super.details, super.stackTrace]);
}

/// Thrown when a migration execution operation fails at runtime.
class TemplateMigrationExecutionException extends TemplateMigrationException {
  /// Creates a [TemplateMigrationExecutionException].
  TemplateMigrationExecutionException(super.message,
      [super.details, super.stackTrace]);
}

/// Thrown when a migration rollback operation fails.
class TemplateMigrationRollbackException extends TemplateMigrationException {
  /// Creates a [TemplateMigrationRollbackException].
  TemplateMigrationRollbackException(super.message,
      [super.details, super.stackTrace]);
}

// ── Documentation Subsystem Exceptions ────────────────────────────────────────

/// Base exception for all README Generation subsystem failures.
class ReadmeGenerationException extends PackageStudioException {
  /// Creates a [ReadmeGenerationException].
  ReadmeGenerationException(super.message, [super.details, super.stackTrace]);
}

/// Base exception for all API Documentation Generation subsystem failures.
class ApiDocGenerationException extends PackageStudioException {
  /// Creates a [ApiDocGenerationException].
  ApiDocGenerationException(super.message, [super.details, super.stackTrace]);
}

/// Base exception for all Architecture Documentation Generation subsystem failures.
class ArchitectureDocGenerationException extends PackageStudioException {
  /// Creates a [ArchitectureDocGenerationException].
  ArchitectureDocGenerationException(super.message,
      [super.details, super.stackTrace]);
}

/// Base exception for all Mermaid Diagram Generation subsystem failures.
class MermaidGenerationException extends PackageStudioException {
  /// Creates a [MermaidGenerationException].
  MermaidGenerationException(super.message, [super.details, super.stackTrace]);
}

/// Base exception for all Code Example Generation subsystem failures.
class CodeExampleGenerationException extends PackageStudioException {
  /// Creates a [CodeExampleGenerationException].
  CodeExampleGenerationException(super.message,
      [super.details, super.stackTrace]);
}

/// Base exception for all Screenshot Management subsystem failures.
class ScreenshotManagementException extends PackageStudioException {
  /// Creates a [ScreenshotManagementException].
  ScreenshotManagementException(super.message,
      [super.details, super.stackTrace]);
}

/// Base exception for all GIF Pipeline subsystem failures.
class GifPipelineException extends PackageStudioException {
  /// Creates a [GifPipelineException].
  GifPipelineException(super.message, [super.details, super.stackTrace]);
}
