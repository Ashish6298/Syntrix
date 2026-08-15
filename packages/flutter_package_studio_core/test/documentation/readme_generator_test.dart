import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:test/test.dart';

void main() {
  group('ReadmeGenerator Unit Tests', () {
    late ReadmeGenerator generator;

    setUp(() {
      generator = ReadmeGenerator();
    });

    test('Plans and generates valid Markdown with default sections', () {
      const options = ReadmeGenerationOptions(
        packageName: 'my_flutter_pkg',
        description: 'A great widget package for Flutter apps.',
        version: '1.2.0',
        features: ['Fast rendering', 'Clean API'],
      );

      final plan = generator.planReadme(options);
      expect(plan.packageName, equals('my_flutter_pkg'));
      expect(plan.sections.length, greaterThanOrEqualTo(5));

      final result = generator.generateReadme(plan);
      expect(result.markdown, contains('# my_flutter_pkg'));
      expect(result.markdown,
          contains('A great widget package for Flutter apps.'));
      expect(result.markdown, contains('## Features'));
      expect(result.markdown, contains('- Fast rendering'));
      expect(result.markdown, contains('## Installation'));
      expect(result.markdown, contains('flutter pub add my_flutter_pkg'));
      expect(result.sectionCount, equals(plan.sections.length));
    });

    test('Output is 100% deterministic across repeated runs', () {
      const options = ReadmeGenerationOptions(
        packageName: 'deterministic_pkg',
        description: 'Deterministic test package.',
      );

      final plan1 = generator.planReadme(options);
      final res1 = generator.generateReadme(plan1);

      final plan2 = generator.planReadme(options);
      final res2 = generator.generateReadme(plan2);

      expect(res1.markdown, equals(res2.markdown));
    });

    test('Sanitizes HTML script tags and redacts secret tokens', () {
      const options = ReadmeGenerationOptions(
        packageName: 'secure_pkg',
        description:
            'Test <script>alert(1)</script> token ghp_123456789012345678901234567890123456',
      );

      final plan = generator.planReadme(options);
      final result = generator.generateReadme(plan);

      expect(result.markdown, contains('&lt;script'));
      expect(result.markdown, contains('[REDACTED_SECRET]'));
      expect(result.markdown,
          isNot(contains('ghp_123456789012345678901234567890123456')));
    });

    test('ReadmeGenerationResult produces valid JSON map', () {
      const options = ReadmeGenerationOptions(
        packageName: 'json_pkg',
        description: 'JSON export test.',
      );

      final plan = generator.planReadme(options);
      final result = generator.generateReadme(plan);
      final json = result.toJson();

      expect(json['packageName'], equals('json_pkg'));
      expect(json['markdown'], isA<String>());
      expect(json['sectionCount'], isA<int>());
    });
  });
}
