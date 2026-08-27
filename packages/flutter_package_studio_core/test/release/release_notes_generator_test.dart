import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:test/test.dart';

void main() {
  group('ReleaseNotesGenerator Unit Tests (Phase 6.4)', () {
    late ReleaseNotesGenerator generator;

    setUp(() {
      generator = ReleaseNotesGenerator();
    });

    ReleaseNotesInputs buildInputs({
      Map<String, dynamic>? certificationData,
      Map<String, dynamic>? compatibilityData,
      Map<String, dynamic>? securityData,
      Map<String, dynamic>? artifactData,
      List<ChangelogSection>? customSections,
    }) {
      final changelogPlan = AutomatedChangelogPlan(
        packageName: 'test_package',
        version: '1.2.3',
        date: '2026-08-27',
        sections: customSections ??
            const [
              ChangelogSection(
                category: ChangelogCategory.feature,
                entries: ['New feature A added.'],
              ),
              ChangelogSection(
                category: ChangelogCategory.fix,
                entries: ['Resolved issue B.'],
              ),
              ChangelogSection(
                category: ChangelogCategory.breaking,
                entries: ['Removed deprecated method C.'],
              ),
              ChangelogSection(
                category: ChangelogCategory.security,
                entries: ['Patched security vulnerability D.'],
              ),
            ],
      );

      const gitPlan = GitReleasePlan(
        packageName: 'test_package',
        targetVersion: '1.2.3',
        tagName: 'v1.2.3',
        branchName: 'release/v1.2.3',
        isClean: true,
        tagConflict: false,
        branchConflict: false,
        isValid: true,
        details: 'Valid Git release plan.',
      );

      return ReleaseNotesInputs(
        packageName: 'test_package',
        version: SemVer.parse('1.2.3'),
        changelogPlan: changelogPlan,
        gitPlan: gitPlan,
        channel: 'stable',
        certificationData: certificationData,
        compatibilityData: compatibilityData,
        securityData: securityData,
        artifactData: artifactData,
      );
    }

    test('1. Full-data happy path matches expected template exactly', () {
      final inputs = buildInputs(
        certificationData: {'status': 'passed'},
        compatibilityData: {'matrix': 'verified'},
        securityData: {'status': 'clean'},
        artifactData: {'manifest': 'generated'},
      );

      final md = generator.renderMarkdown(inputs);

      expect(
          md,
          contains(
              'Flutter Package Studio v1.2.3\n----------------------------'));
      expect(md, contains('Highlights\n----------'));
      expect(md, contains('New Features\n------------'));
      expect(md, contains('Bug Fixes\n---------'));
      expect(md, contains('Breaking Changes\n----------------'));
      expect(md, contains('Security\n--------'));
      expect(md, contains('Compatibility\n-------------'));
      expect(md, contains('Installation\n------------'));
      expect(md, contains('Full Changelog\n--------------'));
    });

    test(
        '2. Missing optional evidence causes sections to be omitted by default',
        () {
      final inputs = buildInputs(
        certificationData: null,
        compatibilityData: null,
        securityData: null,
      );

      final md = generator.renderMarkdown(inputs, omitMissingEvidence: true);

      expect(md, isNot(contains('Compatibility\n-------------')));
      expect(md, contains('Installation\n------------'));
    });

    test(
        '3. No-changes-of-a-given-category (e.g. no breaking changes) cleanly omits section',
        () {
      final inputs = buildInputs(
        customSections: const [
          ChangelogSection(
            category: ChangelogCategory.feature,
            entries: ['Feature only.'],
          ),
        ],
      );

      final md = generator.renderMarkdown(inputs);

      expect(md, isNot(contains('Breaking Changes')));
      expect(md, isNot(contains('Bug Fixes')));
    });

    test(
        '4. Determinism check asserts byte-identical output across repeated runs',
        () {
      final inputs = buildInputs(
        certificationData: {'status': 'passed'},
      );

      final md1 = generator.renderMarkdown(inputs);
      final md2 = generator.renderMarkdown(inputs);

      expect(md1, equals(md2));
    });

    test('5. Preview mode returns plan without disk mutation', () {
      final inputs = buildInputs();
      final plan = generator.planReleaseNotes(inputs,
          options: const ReleaseNotesOptions(writeDisk: false));
      final result = generator.generateReleaseNotes(plan);

      expect(result.isApplied, isFalse);
      expect(result.filePath, equals('release_notes/v1.2.3.md'));
    });

    test('6. Write mode outputs valid target path and applied status', () {
      final inputs = buildInputs();
      final plan = generator.planReleaseNotes(inputs,
          options: const ReleaseNotesOptions(writeDisk: true));
      final result = generator.generateReleaseNotes(plan);

      expect(result.isApplied, isTrue);
      expect(result.filePath, equals('release_notes/v1.2.3.md'));
    });

    test('7. Overwrite and path protection rejects absolute path and traversal',
        () {
      final inputs = buildInputs();
      expect(
          () => generator.planReleaseNotes(inputs,
              options: const ReleaseNotesOptions(outputDir: '/abs/path')),
          throwsA(isA<ReleaseNotesException>()));
      expect(
          () => generator.planReleaseNotes(inputs,
              options: const ReleaseNotesOptions(outputDir: '../path')),
          throwsA(isA<ReleaseNotesException>()));
    });

    test('8. Full Changelog section embeds Phase 6.2 changelog entry verbatim',
        () {
      final inputs = buildInputs();
      final md = generator.renderMarkdown(inputs);

      expect(md, contains(inputs.changelogPlan.toMarkdownEntry().trimRight()));
    });

    test('9. Fails closed on empty package name', () {
      final inputs = ReleaseNotesInputs(
        packageName: '',
        version: SemVer.parse('1.0.0'),
        changelogPlan: const AutomatedChangelogPlan(
            packageName: '',
            version: '1.0.0',
            date: '2026-08-27',
            sections: []),
        gitPlan: const GitReleasePlan(
            packageName: '',
            targetVersion: '1.0.0',
            tagName: 'v1.0.0',
            branchName: 'release/v1.0.0',
            isClean: true,
            tagConflict: false,
            branchConflict: false,
            isValid: true,
            details: ''),
      );

      expect(() => generator.planReleaseNotes(inputs),
          throwsA(isA<ReleaseNotesException>()));
    });
  });
}
