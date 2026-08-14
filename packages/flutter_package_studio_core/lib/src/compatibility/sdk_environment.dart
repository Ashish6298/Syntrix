/// Abstract provider for the current SDK/runtime environment.
///
/// All fields return **safe, redacted** information — no file paths, home
/// directories, process environment variables, or credentials.
///
/// ## Design
///
/// [SdkEnvironment] is the single seam that makes compatibility evaluation
/// fully testable without depending on the developer's installed SDK. All
/// production code that needs SDK information must inject [SdkEnvironment]
/// rather than calling `Platform.*`, `dart:io`, or executing processes.
///
/// ## Security
///
/// Implementations must never expose:
/// - Absolute SDK install paths
/// - Home directory or user paths
/// - Environment variables (beyond safe version strings)
/// - Process credentials or tokens
///
/// The only information permitted is:
/// - Dart SDK version (e.g., "3.5.0")
/// - Flutter SDK version or null (e.g., "3.22.0")
/// - Operating system name (e.g., "windows", "linux", "macos")
/// - Whether Flutter is available
abstract class SdkEnvironment {
  const SdkEnvironment();

  /// The currently active Dart SDK version string (e.g., `"3.5.0"`).
  ///
  /// Must be a valid semantic version (major.minor.patch).
  String get dartVersion;

  /// The currently active Flutter SDK version string, or `null` if Flutter
  /// is not installed or not in scope.
  String? get flutterVersion;

  /// The current operating system identifier.
  ///
  /// One of: `"android"`, `"ios"`, `"linux"`, `"macos"`, `"windows"`,
  /// `"web"`, `"fuchsia"`. Defaults to `"linux"` in unknown environments.
  String get operatingSystem;

  /// Whether Flutter SDK is available and queryable in this environment.
  bool get isFlutterAvailable => flutterVersion != null;

  /// Returns `true` if [platform] is the current [operatingSystem].
  bool supportsPlatform(String platform) =>
      platform.toLowerCase() == operatingSystem.toLowerCase();
}

/// A concrete, fully configurable [SdkEnvironment] for use in tests and
/// dependency injection.
///
/// All values are provided at construction time and never read from the
/// runtime environment, making tests fully deterministic.
class MockSdkEnvironment extends SdkEnvironment {
  @override
  final String dartVersion;

  @override
  final String? flutterVersion;

  @override
  final String operatingSystem;

  /// Creates a mock environment with explicit version values.
  ///
  /// Example:
  /// ```dart
  /// final env = MockSdkEnvironment(
  ///   dartVersion: '3.5.0',
  ///   flutterVersion: '3.22.0',
  ///   operatingSystem: 'linux',
  /// );
  /// ```
  const MockSdkEnvironment({
    required this.dartVersion,
    this.flutterVersion,
    this.operatingSystem = 'linux',
  });

  /// A standard modern Flutter/Dart environment for testing.
  static const MockSdkEnvironment standard = MockSdkEnvironment(
    dartVersion: '3.5.0',
    flutterVersion: '3.22.0',
    operatingSystem: 'linux',
  );

  /// An old Dart environment without Flutter (Dart-only package testing).
  static const MockSdkEnvironment dartOnly = MockSdkEnvironment(
    dartVersion: '3.0.0',
    operatingSystem: 'linux',
  );

  /// A minimal environment representing only the bare minimum SDK.
  static const MockSdkEnvironment minimal = MockSdkEnvironment(
    dartVersion: '2.19.0',
    operatingSystem: 'linux',
  );

  @override
  String toString() =>
      'MockSdkEnvironment(dart: $dartVersion, flutter: $flutterVersion, '
      'os: $operatingSystem)';
}
