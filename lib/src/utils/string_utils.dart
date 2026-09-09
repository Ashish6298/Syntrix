/// Foundational string utilities for casing conversions and validations.
class StringUtils {
  /// Capitalizes the first character of the given [text].
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  /// Splits a string into words based on common delimiters (spaces, underscores, hyphens, and camelCase changes).
  static List<String> splitWords(String text) {
    if (text.isEmpty) return [];

    // Replace transitions between lowercase/uppercase with a delimiter
    final regex = RegExp(r'(?<=[a-z0-9])(?=[A-Z])|(?<=[A-Z])(?=[A-Z][a-z])');
    final formatted = text.replaceAll(regex, '_');

    return formatted
        .split(RegExp(r'[\s_\-]+'))
        .where((word) => word.isNotEmpty)
        .toList();
  }

  /// Converts the given [text] to `camelCase`.
  static String toCamelCase(String text) {
    final words = splitWords(text);
    if (words.isEmpty) return '';

    final buffer = StringBuffer()..write(words.first.toLowerCase());
    for (var i = 1; i < words.length; i++) {
      buffer.write(capitalize(words[i].toLowerCase()));
    }
    return buffer.toString();
  }

  /// Converts the given [text] to `snake_case`.
  static String toSnakeCase(String text) {
    return splitWords(text).map((w) => w.toLowerCase()).join('_');
  }

  /// Converts the given [text] to `kebab-case`.
  static String toKebabCase(String text) {
    return splitWords(text).map((w) => w.toLowerCase()).join('-');
  }

  /// Converts the given [text] to `PascalCase`.
  static String toPascalCase(String text) {
    return splitWords(text).map((w) => capitalize(w.toLowerCase())).join();
  }
}
