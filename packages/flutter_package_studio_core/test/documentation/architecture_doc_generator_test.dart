import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:test/test.dart';

void main() {
  group('ArchitectureDocGenerator Unit Tests', () {
    late ArchitectureDocGenerator generator;

    setUp(() {
      generator = ArchitectureDocGenerator();
    });

    test('Plans and generates valid Markdown with Mermaid diagrams', () {
      final plan = generator.planArchitectureDoc(const ArchDocOptions());
      expect(plan.title, contains('Architecture'));
      expect(plan.components.length, greaterThanOrEqualTo(5));

      final result = generator.generateArchitectureDoc(plan);
      expect(result.markdown,
          contains('# Flutter Package Studio — System Architecture'));
      expect(result.markdown, contains('```mermaid'));
      expect(result.markdown, contains('graph TD'));
      expect(result.markdown, contains('Template Discovery & Catalog'));
      expect(result.componentCount, equals(plan.components.length));
    });

    test('Output is 100% deterministic across repeated runs', () {
      final plan1 = generator.planArchitectureDoc(const ArchDocOptions());
      final res1 = generator.generateArchitectureDoc(plan1);

      final plan2 = generator.planArchitectureDoc(const ArchDocOptions());
      final res2 = generator.generateArchitectureDoc(plan2);

      expect(res1.markdown, equals(res2.markdown));
    });

    test('ArchDocResult produces valid JSON map', () {
      final plan = generator.planArchitectureDoc(const ArchDocOptions());
      final result = generator.generateArchitectureDoc(plan);
      final json = result.toJson();

      expect(json['title'], isA<String>());
      expect(json['markdown'], isA<String>());
      expect(json['componentCount'], isA<int>());
    });
  });
}
