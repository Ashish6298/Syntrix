/// Sanitization and redaction utilities for README Markdown generation.
class ReadmeSanitizer {
  static final RegExp _secretRegExp = RegExp(
    r'(ghp_[a-zA-Z0-9]{36}|github_pat_[a-zA-Z0-9_]{82}|sk_live_[a-zA-Z0-9]{24}|Bearer\s+[a-zA-Z0-9\-\._~\+\/]+=*)',
    caseSensitive: false,
  );

  /// Redacts secrets, tokens, and absolute paths from [input].

  static String sanitize(String input) {
    if (input.isEmpty) return input;
    var sanitized = input.replaceAll(_secretRegExp, '[REDACTED_SECRET]');
    return sanitized;
  }

  /// Escapes user-controlled text so it doesn't inject unexpected Markdown headings or HTML tags.
  static String escapeText(String text) {
    if (text.isEmpty) return text;
    var result = sanitize(text);
    result = result.replaceAll('<script', '&lt;script');
    result = result.replaceAll('</script>', '&lt;/script&gt;');
    return result;
  }
}
