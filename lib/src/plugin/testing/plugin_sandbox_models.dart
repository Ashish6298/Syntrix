/// Domain models and boundary controls for the Plugin Testing & Sandbox Framework (Phase 7.13).
library;

import 'dart:io' as io;
import 'package:syntrix/src/error/exceptions.dart';
import 'package:syntrix/src/release/git/git_process_runner.dart';
import 'package:syntrix/src/release/github/github_api_client.dart';
import 'package:path/path.dart' as p;

/// Controlled sandbox filesystem strictly bounding operations to a designated disposable temporary root.
class SandboxFileSystem {
  final io.Directory sandboxRoot;
  final String _canonicalRootPath;

  SandboxFileSystem(this.sandboxRoot)
      : _canonicalRootPath = p.canonicalize(sandboxRoot.path);

  /// Resolves and validates that [targetPath] does not escape the sandbox root.
  /// Throws [PluginSandboxSecurityException] on path traversal outside root.
  String resolveSafePath(String targetPath) {
    final combined = p.isAbsolute(targetPath)
        ? targetPath
        : p.join(_canonicalRootPath, targetPath);
    final canonical = p.canonicalize(combined);

    if (!p.isWithin(_canonicalRootPath, canonical) &&
        canonical != _canonicalRootPath) {
      throw PluginSandboxSecurityException(
          'Sandbox Violation: Path "$targetPath" traverses outside the sandboxed directory root "$_canonicalRootPath".');
    }
    return canonical;
  }

  /// Writes text content safely inside the sandbox.
  io.File writeSafeFile(String relativeOrSafePath, String content) {
    final safePath = resolveSafePath(relativeOrSafePath);
    final file = io.File(safePath);
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(content);
    return file;
  }

  /// Reads text content safely inside the sandbox.
  String readSafeFile(String relativeOrSafePath) {
    final safePath = resolveSafePath(relativeOrSafePath);
    final file = io.File(safePath);
    if (!file.existsSync()) {
      throw PluginSandboxSecurityException(
          'Sandbox File Missing: File "$safePath" does not exist in sandbox.');
    }
    return file.readAsStringSync();
  }

  /// Creates a directory safely inside the sandbox.
  io.Directory createSafeDirectory(String relativeOrSafePath) {
    final safePath = resolveSafePath(relativeOrSafePath);
    final dir = io.Directory(safePath);
    dir.createSync(recursive: true);
    return dir;
  }

  /// Cleans up and deletes the sandbox root directory and all its contents.
  void dispose() {
    if (sandboxRoot.existsSync()) {
      try {
        sandboxRoot.deleteSync(recursive: true);
      } catch (_) {}
    }
  }
}

/// Strict network transport block guaranteeing zero outbound socket/HTTP requests.
class MockNetworkTransport {
  const MockNetworkTransport();

  /// Intercepts any outbound request attempt and unconditionally throws a security exception.
  Never sendRequest(String url, {Map<String, dynamic>? headers, dynamic body}) {
    throw PluginSandboxSecurityException(
        'Sandbox Violation: Plugin attempted real outbound network request to "$url". Network access is hard-blocked in test sandbox.');
  }
}

/// Test context passed into sandboxed test actions providing safe fakes and verified doubles.
class PluginTestContext {
  final SandboxFileSystem fileSystem;
  final MockGitProcessRunner gitRunner;
  final MockGitHubApiClient gitHubClient;
  final MockNetworkTransport network;
  final Map<String, dynamic> testState;

  PluginTestContext({
    required this.fileSystem,
    MockGitProcessRunner? gitRunner,
    MockGitHubApiClient? gitHubClient,
    this.network = const MockNetworkTransport(),
    Map<String, dynamic>? testState,
  })  : gitRunner = gitRunner ?? MockGitProcessRunner(),
        gitHubClient = gitHubClient ?? MockGitHubApiClient(),
        testState = testState ?? {};

  /// Resolves a path strictly within the sandbox filesystem.
  String path(String relativePath) => fileSystem.resolveSafePath(relativePath);

  /// Helper to safely write a plugin manifest file into the sandbox.
  io.File writePluginManifest({
    required String pluginDirectoryName,
    required String manifestContent,
    String manifestFilename = 'plugin.json',
  }) {
    return fileSystem.writeSafeFile(
        '$pluginDirectoryName/$manifestFilename', manifestContent);
  }
}
