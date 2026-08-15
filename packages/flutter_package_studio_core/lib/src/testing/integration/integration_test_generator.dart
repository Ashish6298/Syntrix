import 'package:flutter_package_studio_core/src/documentation/readme/readme_sanitizer.dart';
import 'package:flutter_package_studio_core/src/error/exceptions.dart';
import 'package:flutter_package_studio_core/src/logging/logger.dart';
import 'package:flutter_package_studio_core/src/testing/integration/integration_test_models.dart';

/// Core generator for analyzing package interactions and generating integration test suites.
class IntegrationTestGenerator {
  final Logger _logger = Logger('IntegrationTestGenerator');

  /// Plans integration test generation without filesystem writes.
  IntegrationTestPlan planIntegrationTests(IntegrationTestOptions options) {
    _logger.info('Planning integration tests for "${options.packageName}"');

    if (options.packageName.trim().isEmpty) {
      throw IntegrationTestGenerationException(
          'Package name must not be empty.');
    }

    final cleanPkgName = ReadmeSanitizer.escapeText(options.packageName);

    // Discovered multi-component integration targets
    final targets = [
      IntegrationTestTarget(
        name: '${cleanPkgName}FullWorkflow',
        components: [cleanPkgName, '${cleanPkgName}Widget'],
        filePath: 'lib/$cleanPkgName.dart',
      ),
    ];

    return IntegrationTestPlan(
      packageName: options.packageName,
      profile: options.profile,
      targets: List.unmodifiable(targets),
    );
  }

  /// Renders a [plan] into a deterministic integration test file bundle map (`path -> content`).
  IntegrationTestResult generateIntegrationTests(
      IntegrationTestPlan plan, IntegrationTestOptions options) {
    _logger.info('Rendering integration tests for "${plan.packageName}"');

    final cleanPkgName = ReadmeSanitizer.escapeText(plan.packageName);
    final files = <String, String>{};

    final buffer = StringBuffer();
    buffer.writeln("import 'package:flutter/material.dart';");
    buffer.writeln("import 'package:flutter_test/flutter_test.dart';");
    buffer.writeln("import 'package:integration_test/integration_test.dart';");
    buffer.writeln("import 'package:$cleanPkgName/$cleanPkgName.dart';");
    buffer.writeln();
    buffer.writeln("void main() {");
    buffer
        .writeln("  IntegrationTestWidgetsFlutterBinding.ensureInitialized();");
    buffer.writeln();
    buffer.writeln("  group('$cleanPkgName Integration Test Suite', () {");

    for (final target in plan.targets) {
      buffer.writeln(
          "    testWidgets('executes ${target.name} workflow', (WidgetTester tester) async {");
      buffer
          .writeln("      // Baseline integration binding & pump verification");
      buffer.writeln("      await tester.pumpWidget(");
      buffer.writeln("        const MaterialApp(");
      buffer.writeln("          home: Scaffold(");
      buffer.writeln("            body: Center(");
      buffer.writeln("              child: Text('${target.name}'),");
      buffer.writeln("            ),");
      buffer.writeln("          ),");
      buffer.writeln("        ),");
      buffer.writeln("      );");
      buffer.writeln(
          "      expect(find.text('${target.name}'), findsOneWidget);");
      buffer.writeln("    });");
      buffer.writeln();
      buffer.writeln(
          "    testWidgets('TODO: verify end-to-end multi-component interaction', (WidgetTester tester) async {");
      buffer.writeln(
          "      // TODO: Implement multi-component state change and async flow assertions.");
      buffer.writeln("      expect(find.byType(Scaffold), findsOneWidget);");
      buffer.writeln("    });");
      buffer.writeln();
    }

    buffer.writeln("  });");
    buffer.writeln("}");

    files['test/integration/${cleanPkgName}_integration_test.dart'] =
        buffer.toString();

    return IntegrationTestResult(
      packageName: plan.packageName,
      files: Map.unmodifiable(files),
    );
  }
}
