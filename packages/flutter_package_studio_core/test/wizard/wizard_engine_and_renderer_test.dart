import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:test/test.dart';

void main() {
  group('WizardEngine & WizardRenderer Integration Tests', () {
    test('WizardEngine runs successfully with mocked inputs', () async {
      final inputBuffer = [
        'my_test_package', // Package name
        '1', // Project type (Flutter Package)
        'A cool test package', // Description
        'com.example', // Org
        'Test Developer', // Author
        'dev@example.com', // Email
        '1', // License (MIT)
        'https://github.com/example/pkg', // Repo URL
        '', // Homepage
        '', // Issue tracker
        '', // Doc URL
        '>=3.5.0 <4.0.0', // Dart SDK
        '>=3.22.0', // Flutter SDK
        '1, 2', // Platforms (Android, iOS)
        '1', // Architecture (Feature-first)
        '1', // Testing (Unit)
        '1', // CI/CD (GitHub Actions)
        '1', // Linter (Very Good Analysis)
        '1', // Docs (DartDoc)
        '1', // Visibility (Public)
        '1', // Template (Standard)
        '.', // Output directory
        'y', // Confirm generation
      ];

      int inputIndex = 0;
      final outSink = StringBuffer();

      final renderer = WizardRenderer(
        theme: const WizardTheme(enableAnsi: false),
        output: outSink,
        inputReader: () {
          if (inputIndex < inputBuffer.length) {
            return inputBuffer[inputIndex++];
          }
          return null;
        },
      );

      final engine = WizardEngine(renderer: renderer);
      final flow = WizardFlow.standard();
      final session = WizardSession(sessionId: 'engine_test');
      final result = await engine.run(flow: flow, session: session);

      if (result is WizardFailure) {
        print('FAILURE REASON: ${result.message}');
        print('FAILURE ERROR: ${result.error}');
      }

      expect(result, isA<WizardSuccess>());

      final success = result as WizardSuccess;
      expect(success.context.packageName, equals('my_test_package'));
      expect(success.context.projectType, equals('flutter_package'));
      expect(outSink.toString(), contains('PROJECT GENERATION SUMMARY'));
    });

    test('WizardEngine handles user cancellation on input EOF', () async {
      final outSink = StringBuffer();
      final renderer = WizardRenderer(
        theme: const WizardTheme(enableAnsi: false),
        output: outSink,
        inputReader: () => null, // Immediate EOF
      );

      final engine = WizardEngine(renderer: renderer);
      final flow = WizardFlow.standard();
      final session = WizardSession(sessionId: 'cancel_test');

      final result = await engine.run(flow: flow, session: session);

      expect(result, isA<WizardCancelled>());
    });

    test('WizardEngine handles user decline on summary page', () async {
      final inputBuffer = [
        'my_test_package', // Package name
        '1', // Project type
        'Desc', // Description
        'com.example', // Org
        'Author', // Author
        'author@example.com', // Email
        '1', // License
        '', // Repo
        '', // Homepage
        '', // Issues
        '', // Docs
        '>=3.5.0 <4.0.0', // Dart SDK
        '>=3.22.0', // Flutter SDK
        '1', // Platforms
        '1', // Arch
        '1', // Testing
        '1', // CI/CD
        '1', // Quality
        '1', // Docs
        '1', // Visibility
        '1', // Template
        '.', // Output
        'n', // Decline summary confirmation!
      ];

      int inputIndex = 0;
      final renderer = WizardRenderer(
        theme: const WizardTheme(enableAnsi: false),
        output: StringBuffer(),
        inputReader: () {
          if (inputIndex < inputBuffer.length) {
            return inputBuffer[inputIndex++];
          }
          return null;
        },
      );

      final engine = WizardEngine(renderer: renderer);
      final flow = WizardFlow.standard();
      final session = WizardSession(sessionId: 'decline_test');

      final result = await engine.run(flow: flow, session: session);

      expect(result, isA<WizardCancelled>());
      expect((result as WizardCancelled).message,
          contains('cancelled on summary'));
    });
  });
}
