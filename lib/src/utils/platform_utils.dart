import 'dart:io' as io;

/// Interface for platform-specific queries, enabling unit tests to mock execution environment.
abstract interface class PlatformUtils {
  /// Whether the current OS is Windows.
  bool get isWindows;

  /// Whether the current OS is macOS.
  bool get isMac;

  /// Whether the current OS is Linux.
  bool get isLinux;

  /// The character used to separate path segments (e.g. '/' or '\').
  String get pathSeparator;

  /// Retrieves an environment variable by name.
  String? getEnv(String name);

  /// Retrieves all environment variables.
  Map<String, String> get environment;
}

/// Production implementation of [PlatformUtils] delegating to [io.Platform].
class SystemPlatformUtils implements PlatformUtils {
  /// Creates a [SystemPlatformUtils] instance.
  const SystemPlatformUtils();

  @override
  bool get isWindows => io.Platform.isWindows;

  @override
  bool get isMac => io.Platform.isMacOS;

  @override
  bool get isLinux => io.Platform.isLinux;

  @override
  String get pathSeparator => io.Platform.pathSeparator;

  @override
  String? getEnv(String name) => io.Platform.environment[name];

  @override
  Map<String, String> get environment => io.Platform.environment;
}
