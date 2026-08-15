/// Restricted context passed to template hooks during lifecycle execution.
library;

import 'package:path/path.dart' as p;
import 'package:flutter_package_studio_core/src/error/exceptions.dart';
import 'package:flutter_package_studio_core/src/template/hooks/hook_action.dart';
import 'package:flutter_package_studio_core/src/template/hooks/hook_phase.dart';
import 'package:flutter_package_studio_core/src/utils/file_utils.dart';

/// Injectable sandboxed file system interface restricted to the target directory.
abstract class HookSandboxFileSystem {
  /// Checks if a relative path exists within the sandbox.
  bool exists(String relativePath);

  /// Reads text content from a relative path within the sandbox.
  String readString(String relativePath);

  /// Lists files within a relative directory in the sandbox.
  List<String> listDirectory(String relativePath);

  /// Enforces sandbox boundary for a given relative path and returns the sanitized path.
  String sanitizePath(String relativePath);
}

/// Default implementation of [HookSandboxFileSystem] operating on real/mock FileUtils.
class SystemHookSandboxFileSystem implements HookSandboxFileSystem {
  final String rootDirectory;
  final FileUtils fileUtils;

  /// Creates a [SystemHookSandboxFileSystem] bounded to [rootDirectory].
  SystemHookSandboxFileSystem({
    required String rootDirectory,
    FileUtils fileUtils = const SystemFileUtils(),
  })  : rootDirectory = p.normalize(p.absolute(rootDirectory)),
        fileUtils = fileUtils;

  @override
  String sanitizePath(String relativePath) {
    if (relativePath.startsWith('/') ||
        relativePath.startsWith('\\') ||
        (relativePath.length > 1 && relativePath[1] == ':')) {
      throw TemplateHookSecurityException(
        'Security Violation: Absolute path "$relativePath" is not allowed in hook operations.',
      );
    }
    final joined = p.normalize(p.join(rootDirectory, relativePath));
    if (!joined.startsWith(rootDirectory)) {
      throw TemplateHookSecurityException(
        'Security Violation: Path "$relativePath" attempts sandbox escape outside target directory "$rootDirectory".',
      );
    }
    return joined;
  }

  @override
  bool exists(String relativePath) {
    final abs = sanitizePath(relativePath);
    return fileUtils.exists(abs);
  }

  @override
  String readString(String relativePath) {
    final abs = sanitizePath(relativePath);
    return fileUtils.readAsString(abs);
  }

  @override
  List<String> listDirectory(String relativePath) {
    final abs = sanitizePath(relativePath);
    if (!fileUtils.isDirectory(abs)) return const [];
    return [abs];
  }
}

/// Restricted, sandboxed execution context provided to [TemplateHook]s.
class TemplateHookContext {
  /// Target output directory bounded for project generation.
  final String targetDirectory;

  /// Active lifecycle phase currently executing.
  final TemplateHookPhase activePhase;

  /// Read-only snapshot of resolved context variables.
  final Map<String, dynamic> _variables;

  /// Read-only snapshot of metadata associated with the target template.
  final Map<String, dynamic> metadata;

  /// Flag indicating whether the current run is a dry-run / non-mutating preview.
  final bool dryRun;

  /// Injectable sandboxed file system interface.
  final HookSandboxFileSystem sandboxFileSystem;

  /// List of proposed actions accumulated during hook execution.
  final List<TemplateHookAction> proposedActions = [];

  /// Creates a [TemplateHookContext].
  TemplateHookContext({
    required this.targetDirectory,
    required this.activePhase,
    Map<String, dynamic> variables = const {},
    Map<String, dynamic> metadata = const {},
    this.dryRun = false,
    HookSandboxFileSystem? sandboxFileSystem,
  })  : _variables = Map.unmodifiable(Map.from(variables)),
        metadata = Map.unmodifiable(Map.from(metadata)),
        sandboxFileSystem = sandboxFileSystem ??
            SystemHookSandboxFileSystem(rootDirectory: targetDirectory);

  /// Returns read-only copy of template variables.
  Map<String, dynamic> get variables => Map.unmodifiable(_variables);

  /// Proposes a new file to be generated.
  void proposeAddFile(String relativePath, String content,
      {String description = 'Hook proposed file'}) {
    sandboxFileSystem.sanitizePath(relativePath);
    proposedActions.add(TemplateHookAction.addFile(
      relativePath: relativePath,
      content: content,
      description: description,
    ));
  }

  /// Proposes modifying or introducing a variable.
  void proposeVariable(String key, Object value,
      {String description = 'Hook proposed variable'}) {
    proposedActions.add(TemplateHookAction.modifyVariable(
      key: key,
      value: value,
      description: description,
    ));
  }

  /// Proposes adding a validation requirement.
  void proposeValidationRequirement(String requirement,
      {String description = 'Hook proposed requirement'}) {
    proposedActions.add(TemplateHookAction.addValidationRequirement(
      requirement: requirement,
      description: description,
    ));
  }

  /// Redacts sensitive strings (tokens, keys, passwords) from diagnostic message.
  static String redactSecrets(String text) {
    var result = text;
    final secretPatterns = <RegExp>[
      RegExp(r'(ghp_[A-Za-z0-9_]{36,})'),
      RegExp(r'(github_pat_[A-Za-z0-9_]{22,})'),
      RegExp(r'(bearer\s+[A-Za-z0-9_\-\.=]+)', caseSensitive: false),
      RegExp(r'(password|secret|token|api_key)\s*[:=]\s*[^\s]+',
          caseSensitive: false),
    ];
    for (final pattern in secretPatterns) {
      result = result.replaceAllMapped(pattern, (match) {
        final str = match.group(0)!;
        if (str.contains('=')) {
          final parts = str.split('=');
          return '${parts[0]}=[REDACTED]';
        } else if (str.contains(':')) {
          final parts = str.split(':');
          return '${parts[0]}: [REDACTED]';
        }
        return '[REDACTED_SECRET]';
      });
    }
    return result;
  }
}
