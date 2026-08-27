import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:test/test.dart';

void main() {
  group('AutomatedChangelogGenerator Unit Tests', () {
    late AutomatedChangelogGenerator generator;

    setUp(() {
      generator = AutomatedChangelogGenerator();
    });

    test('Plans automated changelog entry generation correctly', () {
      const options = AutomatedChangelogOptions(
        packageName: 'awesome_pkg',
        version: '1.2.0',
        date: '2026-08-27',
      );

      final plan = generator.planChangelog(options);
      expect(plan.packageName, equals('awesome_pkg'));
      expect(plan.version, equals('1.2.0'));
      expect(plan.date, equals('2026-08-27'));
      expect(plan.sections, isNotEmpty);

      final markdown = plan.toMarkdownEntry();
      expect(markdown, contains('## [1.2.0] - 2026-08-27'));
      expect(markdown, contains('🚀 Features'));
      expect(markdown, contains('✨ Improvements'));
      expect(markdown, contains('🔒 Security'));
    });

    test('Generates result with preview status when writeDisk is false', () {
      const options = AutomatedChangelogOptions(
        packageName: 'awesome_pkg',
        version: '1.2.0',
        date: '2026-08-27',
      );

      final plan = generator.planChangelog(options);
      final result = generator.generateChangelog(plan, writeDisk: false);

      expect(result.isApplied, isFalse);
      expect(
          result.toMarkdownReport(), contains('PREVIEW DRY-RUN (NOT APPLIED)'));
    });

    test('Rejects absolute output and changelog paths', () {
      const absOptions = AutomatedChangelogOptions(
        packageName: 'pkg',
        changelogPath: '/etc/CHANGELOG.md',
      );
      expect(() => generator.planChangelog(absOptions),
          throwsA(isA<AutomatedChangelogException>()));
    });

    test('Rejects path traversal ".." in paths', () {
      const travOptions = AutomatedChangelogOptions(
        packageName: 'pkg',
        outputDir: '../doc/release',
      );
      expect(() => generator.planChangelog(travOptions),
          throwsA(isA<AutomatedChangelogException>()));
    });
  });
}
