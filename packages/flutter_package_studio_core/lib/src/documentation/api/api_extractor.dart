import 'package:flutter_package_studio_core/src/documentation/api/api_models.dart';
import 'package:flutter_package_studio_core/src/documentation/readme/readme_sanitizer.dart';

/// Extractor for extracting public API symbols from Dart source code.
class ApiExtractor {
  /// Extracts public symbols from Dart file templates map (`path -> content`).
  List<ApiSymbol> extractFromFiles(Map<String, String> files) {
    final symbols = <ApiSymbol>[];

    files.forEach((path, content) {
      if (path.endsWith('.dart') && !path.contains('/src/')) {
        symbols.addAll(extractFromSource(content));
      }
    });

    return List.unmodifiable(symbols);
  }

  /// Extracts public symbols from a single Dart source string.
  List<ApiSymbol> extractFromSource(String source) {
    final symbols = <ApiSymbol>[];
    final lines = source.split('\n');

    var currentDoc = StringBuffer();

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      if (line.startsWith('///')) {
        currentDoc.writeln(line.substring(3).trim());
        continue;
      }

      final docStr = ReadmeSanitizer.escapeText(currentDoc.toString().trim());

      // Extract class
      final classMatch =
          RegExp(r'^class\s+([A-Z][a-zA-Z0-9_]*)\s*').firstMatch(line);
      if (classMatch != null) {
        final className = classMatch.group(1)!;
        if (!className.startsWith('_')) {
          final isDeprecated =
              docStr.contains('@deprecated') || line.contains('@deprecated');
          symbols.add(ApiSymbol(
            name: className,
            kind: ApiSymbolKind.classSymbol,
            typeSignature: 'class $className',
            docComment: docStr,
            isDeprecated: isDeprecated,
          ));
        }
        currentDoc.clear();
        continue;
      }

      // Extract function
      final fnMatch =
          RegExp(r'^(void|[A-Z][a-zA-Z0-9_<>\?]*)\s+([a-z][a-zA-Z0-9_]*)\s*\(')
              .firstMatch(line);
      if (fnMatch != null) {
        final fnName = fnMatch.group(2)!;
        final returnType = fnMatch.group(1)!;
        if (!fnName.startsWith('_')) {
          final isDeprecated =
              docStr.contains('@deprecated') || line.contains('@deprecated');
          symbols.add(ApiSymbol(
            name: fnName,
            kind: ApiSymbolKind.functionSymbol,
            typeSignature: '$returnType $fnName()',
            docComment: docStr,
            isDeprecated: isDeprecated,
          ));
        }
        currentDoc.clear();
        continue;
      }

      // Extract enum
      final enumMatch =
          RegExp(r'^enum\s+([A-Z][a-zA-Z0-9_]*)\s*').firstMatch(line);
      if (enumMatch != null) {
        final enumName = enumMatch.group(1)!;
        if (!enumName.startsWith('_')) {
          symbols.add(ApiSymbol(
            name: enumName,
            kind: ApiSymbolKind.enumSymbol,
            typeSignature: 'enum $enumName',
            docComment: docStr,
          ));
        }
        currentDoc.clear();
        continue;
      }

      currentDoc.clear();
    }

    return symbols;
  }
}
