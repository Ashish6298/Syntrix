import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:test/test.dart';

void main() {
  group('ApiDocGenerator Unit Tests', () {
    late ApiExtractor extractor;
    late ApiDocGenerator generator;

    setUp(() {
      extractor = ApiExtractor();
      generator = ApiDocGenerator(extractor: extractor);
    });

    test(
        'Extracts public classes, methods, and doc comments correctly while ignoring private symbols',
        () {
      const source = '''
/// Primary calculator utility.
class Calculator {
  /// Adds two numbers.
  int add(int a, int b) => a + b;
}

/// Private helper class.
class _PrivateHelper {}

/// Standalone utility function.
void calculateAll() {}
''';

      final symbols = extractor.extractFromSource(source);
      expect(symbols.length, equals(2));
      expect(symbols[0].name, equals('Calculator'));
      expect(symbols[0].kind, equals(ApiSymbolKind.classSymbol));
      expect(symbols[0].docComment, equals('Primary calculator utility.'));
      expect(symbols[1].name, equals('calculateAll'));
      expect(symbols[1].kind, equals(ApiSymbolKind.functionSymbol));
    });

    test('Generates deterministic Markdown output for API reference', () {
      const options = ApiDocOptions(
        packageName: 'test_api_pkg',
        symbols: [
          ApiSymbol(
            name: 'WidgetA',
            kind: ApiSymbolKind.classSymbol,
            typeSignature: 'class WidgetA',
            docComment: 'First test widget.',
          ),
          ApiSymbol(
            name: 'WidgetB',
            kind: ApiSymbolKind.classSymbol,
            typeSignature: 'class WidgetB',
            docComment: 'Second test widget.',
          ),
        ],
      );

      final plan = generator.planApiDoc(options);
      final result1 = generator.generateApiDoc(plan);
      final result2 = generator.generateApiDoc(plan);

      expect(result1.markdown, equals(result2.markdown));
      expect(result1.markdown, contains('# API Reference — test_api_pkg'));
      expect(result1.markdown, contains('### `WidgetA`'));
      expect(result1.markdown, contains('### `WidgetB`'));
    });

    test('Handles deprecated symbols correctly with DEPRECATED tags', () {
      const options = ApiDocOptions(
        packageName: 'deprecated_pkg',
        symbols: [
          ApiSymbol(
            name: 'OldApi',
            kind: ApiSymbolKind.classSymbol,
            typeSignature: 'class OldApi',
            docComment: 'Use NewApi instead. @deprecated',
            isDeprecated: true,
          ),
        ],
      );

      final plan = generator.planApiDoc(options);
      final result = generator.generateApiDoc(plan);

      expect(result.markdown, contains('### `OldApi` `[DEPRECATED]`'));
    });
  });
}
