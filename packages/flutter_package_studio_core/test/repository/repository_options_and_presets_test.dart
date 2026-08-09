import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:test/test.dart';

void main() {
  group('RepositoryOptions & RepositoryPresets Tests', () {
    test('RepositoryOptions initializes with expected default values', () {
      const options = RepositoryOptions(
        repositoryName: 'my_repo',
        description: 'Test repository description',
      );

      expect(options.repositoryName, equals('my_repo'));
      expect(options.license, equals('MIT'));
      expect(options.branchName, equals('main'));
      expect(options.preset, equals('standard'));
      expect(options.gitInit, isTrue);
      expect(options.generateReadme, isTrue);
      expect(options.generateChangelog, isTrue);
      expect(options.generateCi, isTrue);
    });

    test(
        'RepositoryOptions.fromWizardContext converts WizardContext properties',
        () {
      final wizardCtx = WizardContext(
        packageName: 'super_pkg',
        description: 'Awesome package',
        author: 'Jane Doe',
        email: 'jane@example.com',
        repoUrl: 'https://github.com/janedoe/super_pkg',
        license: 'Apache-2.0',
      );

      final options = RepositoryOptions.fromWizardContext(wizardCtx);

      expect(options.repositoryName, equals('super_pkg'));
      expect(options.description, equals('Awesome package'));
      expect(options.author, equals('Jane Doe'));
      expect(options.email, equals('jane@example.com'));
      expect(options.license, equals('Apache-2.0'));
      expect(options.repositoryUrl,
          equals('https://github.com/janedoe/super_pkg'));
    });

    test(
        'RepositoryPreset resolve returns correct preset or defaults to standard',
        () {
      final minimal = RepositoryPreset.resolve('minimal');
      expect(minimal.id, equals('minimal'));
      expect(minimal.options.generateChangelog, isFalse);

      final openSource = RepositoryPreset.resolve('open_source');
      expect(openSource.id, equals('open_source'));
      expect(openSource.options.generateContributing, isTrue);

      final unknown = RepositoryPreset.resolve('unknown_preset_id');
      expect(unknown.id, equals('standard'));
    });
  });
}
