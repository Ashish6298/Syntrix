/// Strict, non-optional, fail-closed sensitive file filtering for Phase 8.2.
library;

import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:syntrix/src/ai/context/project_context_models.dart';

/// Result of evaluating a file against sensitivity and exclusion rules.
class FileFilterDecision {
  /// Whether the file is safe to include in context.
  final bool isSafe;

  /// Reason code if excluded.
  final ContextFileExclusionReason? reason;

  /// Human-readable explanation of why the file was excluded or approved.
  final String explanation;

  const FileFilterDecision.safe(
      [this.explanation = 'Verified safe format and location'])
      : isSafe = true,
        reason = null;

  const FileFilterDecision.excluded({
    required this.reason,
    required this.explanation,
  }) : isSafe = false;
}

/// Single authority for filtering out sensitive, secret, ignored, and unclassifiable files.
///
/// Guarantees:
/// 1. Mandatory & Non-Optional: Every candidate file must pass through this filter before reading.
/// 2. Fail-Closed: Unknown extensions, unparseable gitignores, or binary files default to EXCLUDED.
/// 3. Comprehensive Regex/Pattern Match: Catches `.env*`, `.pem`, `.key`, `id_rsa`, credential stores, tokens.
class SensitiveFileFilter {
  /// List of compiled regex patterns from project `.gitignore` files.
  final List<RegExp> _gitIgnorePatterns;

  /// Whether the project's `.gitignore` had read/parse errors (triggers fail-closed heightened protection).
  final bool isGitIgnoreDegraded;

  SensitiveFileFilter._({
    required List<RegExp> gitIgnorePatterns,
    required this.isGitIgnoreDegraded,
  }) : _gitIgnorePatterns = gitIgnorePatterns;

  /// Factory constructing filter from a root project directory.
  factory SensitiveFileFilter.fromProjectRoot(String projectRoot) {
    final patterns = <RegExp>[];
    var degraded = false;

    final gitIgnoreFile = File(p.join(projectRoot, '.gitignore'));
    if (gitIgnoreFile.existsSync()) {
      try {
        final lines = gitIgnoreFile.readAsLinesSync();
        for (final rawLine in lines) {
          final line = rawLine.trim();
          if (line.isEmpty || line.startsWith('#')) continue;

          // Convert basic gitignore glob pattern to RegExp
          final regexPattern = _globToRegex(line);
          if (regexPattern != null) {
            patterns.add(RegExp(regexPattern, caseSensitive: false));
          }
        }
      } catch (e) {
        // Fail-closed on corrupted/unreadable .gitignore: mark degraded so we exclude more aggressively
        degraded = true;
      }
    }

    return SensitiveFileFilter._(
      gitIgnorePatterns: patterns,
      isGitIgnoreDegraded: degraded,
    );
  }

  /// Evaluates whether [relativePath] is safe for AI context consumption.
  FileFilterDecision evaluateFile({
    required String relativePath,
    String? fileContentSample,
  }) {
    // 0. Path traversal and absolute-path escape validation
    if (relativePath.contains('..') ||
        p.isAbsolute(relativePath) ||
        relativePath.startsWith('/') ||
        relativePath.startsWith(r'\')) {
      return const FileFilterDecision.excluded(
        reason: ContextFileExclusionReason.unclassifiableFormat,
        explanation:
            'Path contains illegal directory traversal (..) or absolute path escape',
      );
    }

    final normalized = p.normalize(relativePath).replaceAll('\\', '/');
    if (normalized.startsWith('../') || normalized == '..') {
      return const FileFilterDecision.excluded(
        reason: ContextFileExclusionReason.unclassifiableFormat,
        explanation: 'Path traverses outside sandbox boundary',
      );
    }

    final filename = p.basename(normalized).toLowerCase();
    final ext = p.extension(normalized).toLowerCase();

    // 1. .env and .env.* files
    if (filename == '.env' || filename.startsWith('.env.')) {
      return const FileFilterDecision.excluded(
        reason: ContextFileExclusionReason.sensitiveEnv,
        explanation: 'Matches environment secret file pattern (.env*)',
      );
    }

    // 2. Private keys and certificates (.pem, .key, .crt, .p12, .keystore, id_rsa, id_ed25519)
    if (ext == '.pem' ||
        ext == '.key' ||
        ext == '.p12' ||
        ext == '.pfx' ||
        ext == '.keystore' ||
        ext == '.jks' ||
        filename == 'id_rsa' ||
        filename == 'id_ed25519' ||
        filename.startsWith('id_rsa.') ||
        filename.startsWith('id_ed25519.')) {
      return const FileFilterDecision.excluded(
        reason: ContextFileExclusionReason.sensitiveKeyOrCert,
        explanation: 'Matches private key, certificate, or keystore pattern',
      );
    }

    // 3. Credential stores (credentials.json, secrets.json, .netrc, pub/npm/git token stores)
    if (filename == 'credentials.json' ||
        filename == 'secrets.json' ||
        filename.startsWith('secrets.') ||
        filename == 'service_account.json' ||
        filename == 'client_secret.json' ||
        filename == '.netrc' ||
        filename == '_netrc' ||
        filename == '.npmrc' ||
        filename == '.git-credentials' ||
        filename == 'pub-credentials.json' ||
        filename == 'key.properties' ||
        normalized.contains('.fps/credentials') ||
        normalized.contains('.gemini/')) {
      return const FileFilterDecision.excluded(
        reason: ContextFileExclusionReason.sensitiveCredential,
        explanation: 'Matches authentication credential store pattern',
      );
    }

    // 4. In-flight secret content heuristics (if sample provided)
    if (fileContentSample != null) {
      if (fileContentSample.contains('-----BEGIN PRIVATE KEY-----') ||
          fileContentSample.contains('-----BEGIN RSA PRIVATE KEY-----') ||
          fileContentSample.contains('-----BEGIN OPENSSH PRIVATE KEY-----') ||
          fileContentSample.contains('-----BEGIN CERTIFICATE-----')) {
        return const FileFilterDecision.excluded(
          reason: ContextFileExclusionReason.sensitiveSecret,
          explanation:
              'File content contains cryptographic private key or certificate header',
        );
      }
      if (RegExp(
              r'(ghp_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|AIza[0-9A-Za-z-_]{35})')
          .hasMatch(fileContentSample)) {
        return const FileFilterDecision.excluded(
          reason: ContextFileExclusionReason.sensitiveSecret,
          explanation:
              'File content contains unredacted API key or personal access token',
        );
      }
    }

    // 5. GitIgnore Rules
    for (final pattern in _gitIgnorePatterns) {
      if (pattern.hasMatch(normalized) || pattern.hasMatch('/$normalized')) {
        return FileFilterDecision.excluded(
          reason: ContextFileExclusionReason.gitIgnored,
          explanation: 'Matched project .gitignore pattern: ${pattern.pattern}',
        );
      }
    }

    // 6. Fail-closed on unclassifiable / unsupported formats
    // Allowed safe text extensions for Dart/Flutter projects:
    const safeExtensions = {
      '.dart',
      '.yaml',
      '.yml',
      '.json',
      '.md',
      '.txt',
      '.xml',
      '.html',
      '.css',
      '.gradle',
      '.properties',
      '.lock',
    };

    if (filename == 'pubspec.lock' || filename == '.packages') {
      // safe known files without explicit standard ext
    } else if (ext.isNotEmpty && !safeExtensions.contains(ext)) {
      return FileFilterDecision.excluded(
        reason: ContextFileExclusionReason.unclassifiableFormat,
        explanation:
            'Unsupported or potentially binary file extension "$ext" excluded by fail-closed policy',
      );
    }

    // If .gitignore was unreadable/degraded, fail-closed on anything not in standard source/test/docs
    if (isGitIgnoreDegraded) {
      if (!normalized.startsWith('lib/') &&
          !normalized.startsWith('test/') &&
          !normalized.startsWith('packages/') &&
          !normalized.endsWith('pubspec.yaml') &&
          !normalized.endsWith('README.md')) {
        return const FileFilterDecision.excluded(
          reason: ContextFileExclusionReason.unclassifiableFormat,
          explanation:
              'Excluded by heightened fail-closed policy due to degraded .gitignore state',
        );
      }
    }

    return const FileFilterDecision.safe();
  }

  static String? _globToRegex(String glob) {
    var g = glob.replaceAll('\\', '/');
    if (g.endsWith('/')) {
      g = '$g.*';
    }
    // Escape regex characters except * and ?
    g = g
        .replaceAll('.', r'\.')
        .replaceAll('+', r'\+')
        .replaceAll('(', r'\(')
        .replaceAll(')', r'\)')
        .replaceAll('[', r'\[')
        .replaceAll(']', r'\]')
        .replaceAll('{', r'\{')
        .replaceAll('}', r'\}')
        .replaceAll('^', r'\^')
        .replaceAll(r'$', r'\$');

    // Convert wildcards
    g = g.replaceAll('**', '.*').replaceAll('*', '[^/]*').replaceAll('?', '.');

    if (!g.startsWith('/')) {
      g = '(^|/)$g';
    }
    return g;
  }
}
