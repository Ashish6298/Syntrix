import 'dart:io' as io;
import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectGenerator & Path Security Tests', () {
    late ProjectGenerator generator;
    late Template template;

    setUp(() {
      generator = ProjectGenerator(fileUtils: const SystemFileUtils());
      template = BuiltinTemplates.flutterPackage;
    });

    test(
        'buildPlan creates inspectable GenerationPlan without mutating filesystem',
        () {
      final wizardCtx = WizardContext(
        packageName: 'sample_pkg',
        description: 'Sample package description',
      );
      final ctx = TemplateContext.fromWizardContext(wizardCtx);

      final plan = generator.buildPlan(
        template: template,
        context: ctx,
        outputDirectory: './sample_pkg',
      );

      expect(plan.templateId, equals('flutter_package'));
      expect(plan.fileCount, equals(7));
      expect(plan.directoryCount, equals(4));

      final pubspecAction =
          plan.actions.firstWhere((a) => a.relativePath == 'pubspec.yaml');
      expect(pubspecAction.textContent, contains('name: sample_pkg'));
    });

    test('execute dryRun returns simulation results without writing files',
        () async {
      final wizardCtx = WizardContext(packageName: 'dry_pkg');
      final ctx = TemplateContext.fromWizardContext(wizardCtx);

      final plan = generator.buildPlan(
        template: template,
        context: ctx,
        outputDirectory: './dry_pkg',
      );

      final result = await generator.execute(plan: plan, dryRun: true);

      expect(result.isSuccess, isTrue);
      expect(result.isDryRun, isTrue);
      expect(result.totalFiles, equals(7));
      expect(result.totalDirectories, equals(4));
    });

    test(
        'Path traversal attempt outside output directory throws TemplateException',
        () {
      final maliciousManifest = const TemplateManifest(
        id: 'malicious',
        name: 'Malicious',
        displayName: 'Malicious',
        description: '',
        version: '1.0.0',
        projectType: 'flutter_package',
        minimumDartSdk: '>=3.0.0',
        files: {
          '../../etc/passwd': 'hacked',
        },
      );

      final maliciousTemplate = Template(
        manifest: maliciousManifest,
        fileTemplates: const {'../../etc/passwd': 'hacked'},
      );

      final ctx = TemplateContext({'package_name': 'test'});

      expect(
        () => generator.buildPlan(
          template: maliciousTemplate,
          context: ctx,
          outputDirectory: './target_dir',
        ),
        throwsA(isA<TemplateException>()),
      );
    });

    test(
        'OverwritePolicy.fail throws TemplateException when directory/file exists',
        () async {
      final tempDir =
          io.Directory.systemTemp.createTempSync('fps_test_gen').path;
      final targetPath = '$tempDir/existing_pkg';

      // Pre-create directory and file
      SystemFileUtils().createDirectory(targetPath);
      SystemFileUtils()
          .writeString('$targetPath/pubspec.yaml', 'existing content');

      final wizardCtx = WizardContext(packageName: 'existing_pkg');
      final ctx = TemplateContext.fromWizardContext(wizardCtx);

      expect(
        () => generator.buildPlan(
          template: template,
          context: ctx,
          outputDirectory: targetPath,
          overwritePolicy: OverwritePolicy.fail,
        ),
        throwsA(isA<TemplateException>()),
      );

      // Clean up temp dir
      SystemFileUtils().delete(tempDir);
    });
  });
}
