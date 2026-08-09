import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:test/test.dart';

void main() {
  group('LicenseProvider & RepositoryFileGenerator Tests', () {
    late TemplateContext context;

    setUp(() {
      final wizardCtx = WizardContext(
        packageName: 'my_test_pkg',
        author: 'Jane Maintenance',
        email: 'jane@test.org',
      );
      context = TemplateContext.fromWizardContext(wizardCtx);
    });

    test(
        'LicenseProvider resolves supported licenses with author/year substitution',
        () {
      final mitText = LicenseProvider.getLicenseTemplate('MIT');
      final renderedMit = TemplateRenderer().renderText(mitText, context);

      expect(renderedMit, contains('Jane Maintenance'));
      expect(renderedMit, contains('MIT License'));

      final apacheText = LicenseProvider.getLicenseTemplate('Apache-2.0');
      final renderedApache = TemplateRenderer().renderText(apacheText, context);

      expect(renderedApache, contains('Copyright 2026 Jane Maintenance'));
    });

    test('LicenseProvider throws LicenseException for unsupported license', () {
      expect(
        () => LicenseProvider.getLicenseTemplate('UNSUPPORTED_LICENSE'),
        throwsA(isA<LicenseException>()),
      );
    });

    test(
        'RepositoryFileGenerator renders README.md, CHANGELOG.md, and CI workflow',
        () {
      final fileGen = RepositoryFileGenerator();
      const options = RepositoryOptions(
        repositoryName: 'my_test_pkg',
        description: 'Test description',
        author: 'Jane Maintenance',
        license: 'MIT',
        generateContributing: true,
      );

      final readme = fileGen.generateReadme(options, context);
      expect(readme, contains('# my_test_pkg'));
      expect(
          readme, contains('import \'package:my_test_pkg/my_test_pkg.dart\';'));
      expect(readme, contains('## Contributing'));

      final changelog = fileGen.generateChangelog(options, context);
      expect(changelog, contains('# Changelog'));
      expect(changelog, contains('Initial release of my_test_pkg.'));

      final gitignore = GitignoreBuilder.buildGitignore(isFlutter: true);
      expect(gitignore, contains('.dart_tool/'));
      expect(gitignore, contains('build/'));

      final ci = CiWorkflowBuilder.buildGitHubWorkflow(
          packageName: 'my_test_pkg', isFlutter: true);
      expect(ci, contains('name: CI'));
      expect(ci, contains('subosito/flutter-action@v2'));
    });
  });
}
