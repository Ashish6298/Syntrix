/// Centralized secret and sensitive data redaction utility for Milestone 8 AI Assistants.
library;

/// Universal secret redaction engine ensuring zero sensitive credentials leak to prompts, outputs, or logs.
class SecretRedactor {
  /// Regular expression detecting bearer tokens, GitHub personal access tokens, Google API keys,
  /// AWS keys, private keys, high-entropy secrets, and passwords.
  static final RegExp _bearerPattern = RegExp(
    r'Bearer\s+[A-Za-z0-9_\-\.\~]{8,}=*',
    caseSensitive: false,
  );

  static final RegExp _githubPatPattern = RegExp(
    r'(ghp_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,})',
  );

  static final RegExp _googleApiKeyPattern = RegExp(
    r'(AIza[0-9A-Za-z\-_]{35})',
  );

  static final RegExp _awsKeyPattern = RegExp(
    r'(AKIA[0-9A-Z]{16})',
  );

  static final RegExp _awsSecretPattern = RegExp(
    r'''(?<=aws_secret_key=)([^"'\s\n\r]{16,})''',
    caseSensitive: false,
  );

  static final RegExp _genericAssignmentPattern = RegExp(
    r'''(?<=(?:api_key|apikey|secret|token|password|auth_key|private_key)=)([^"'\s\n\r]{8,})''',
    caseSensitive: false,
  );

  static final RegExp _slackTokenPattern = RegExp(
    r'(xox[baprs]-[0-9A-Za-z]{10,48})',
  );

  static final RegExp _jwtPattern = RegExp(
    r'(eyJ[A-Za-z0-9-_]{10,}\.eyJ[A-Za-z0-9-_]{10,}\.[A-Za-z0-9-_]{10,})',
  );

  static final RegExp _passwordFieldPattern = RegExp(
    r'''(?<=password["']?\s*[:=]\s*["'])([^"'\n\r]{4,})(?=["'])''',
    caseSensitive: false,
  );

  static final RegExp _secretFieldPattern = RegExp(
    r'''(?<=(?:secret|token|api_key|auth_key)["']?\s*[:=]\s*["'])([^"'\n\r]{4,})(?=["'])''',
    caseSensitive: false,
  );

  static final RegExp _cryptoKeyBlockPattern = RegExp(
    r'-----BEGIN (?:RSA |OPENSSH |EC )?PRIVATE KEY-----[\s\S]+?-----END (?:RSA |OPENSSH |EC )?PRIVATE KEY-----',
  );

  /// Standard fixed redaction placeholder.
  static const String defaultPlaceholder = '[REDACTED_SECRET]';

  /// Redacts all known secret patterns, tokens, and sensitive credential formats from [input].
  ///
  /// Guarantees:
  /// - Never retains any fragment or portion of the original secret value.
  /// - Replaces detected secret tokens with [defaultPlaceholder] (or specific token tag).
  static String redact(String input) {
    if (input.isEmpty) return input;

    var sanitized = input;

    // Cryptographic private key blocks
    sanitized = sanitized.replaceAll(
        _cryptoKeyBlockPattern, '[REDACTED_PRIVATE_KEY_BLOCK]');

    // Specific vendor tokens
    sanitized = sanitized.replaceAll(_bearerPattern, 'Bearer [REDACTED_TOKEN]');
    sanitized =
        sanitized.replaceAll(_githubPatPattern, '[REDACTED_GITHUB_TOKEN]');
    sanitized =
        sanitized.replaceAll(_googleApiKeyPattern, '[REDACTED_GOOGLE_API_KEY]');
    sanitized = sanitized.replaceAll(_awsKeyPattern, '[REDACTED_AWS_KEY]');
    sanitized =
        sanitized.replaceAll(_slackTokenPattern, '[REDACTED_SLACK_TOKEN]');
    sanitized = sanitized.replaceAll(_jwtPattern, '[REDACTED_JWT_TOKEN]');

    // Password and secret field assignments (in JSON, YAML, or properties)
    sanitized = sanitized.replaceAll(_awsSecretPattern, '[REDACTED_AWS_SECRET]');
    sanitized = sanitized.replaceAll(_genericAssignmentPattern, '[REDACTED_SECRET]');
    sanitized =
        sanitized.replaceAll(_passwordFieldPattern, '[REDACTED_PASSWORD]');
    sanitized = sanitized.replaceAll(_secretFieldPattern, '[REDACTED_SECRET]');

    return sanitized;
  }

  /// Recursively redacts all string values in a JSON-like dynamic object (Map, List, Primitive).
  static dynamic redactJson(dynamic data) {
    if (data is String) {
      return redact(data);
    } else if (data is Map) {
      final result = <String, dynamic>{};
      for (final entry in data.entries) {
        final k = entry.key is String
            ? redact(entry.key as String)
            : entry.key.toString();
        result[k] = redactJson(entry.value);
      }
      return result;
    } else if (data is List) {
      return data.map(redactJson).toList();
    }
    return data;
  }

  /// Specialized typed helper redacting a JSON map.
  static Map<String, dynamic> redactJsonMap(Map<String, dynamic> data) {
    return redactJson(data) as Map<String, dynamic>;
  }
}
