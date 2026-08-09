import 'dart:io' as io;

/// Abstract interface for resolving GitHub personal access tokens or credentials securely.
abstract interface class GitHubCredentialProvider {
  /// Resolves GitHub authentication token, or `null` if unauthenticated.
  Future<String?> getToken();

  /// Returns `true` if a non-empty token is present.
  Future<bool> hasCredential();
}

/// Environment variable-backed implementation (`GITHUB_TOKEN` or `GH_TOKEN`).
class EnvironmentGitHubCredentialProvider implements GitHubCredentialProvider {
  final Map<String, String> _environment;

  /// Creates an [EnvironmentGitHubCredentialProvider] with optional [_environment] override.
  EnvironmentGitHubCredentialProvider({Map<String, String>? environment})
      : _environment = environment ?? io.Platform.environment;

  @override
  Future<String?> getToken() async {
    final token = _environment['GITHUB_TOKEN'] ?? _environment['GH_TOKEN'];
    if (token != null && token.trim().isNotEmpty) {
      return token.trim();
    }
    return null;
  }

  @override
  Future<bool> hasCredential() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Utility to redact secret token occurrences from log strings or diagnostics.
  static String redactSecrets(String text, String? token) {
    if (token == null || token.isEmpty) return text;
    return text.replaceAll(token, '[REDACTED_GITHUB_TOKEN]');
  }
}
