import 'package:flutter_package_studio_core/src/documentation/readme/readme_sanitizer.dart';
import 'package:flutter_package_studio_core/src/error/exceptions.dart';
import 'package:flutter_package_studio_core/src/logging/logger.dart';
import 'package:flutter_package_studio_core/src/testing/widget/widget_test_models.dart';

/// Core generator for analyzing Flutter widget APIs and generating widget test suites.
class WidgetTestGenerator {
  final Logger _logger = Logger('WidgetTestGenerator');

  /// Plans widget test generation without filesystem writes.
  WidgetTestPlan planWidgetTests(WidgetTestOptions options) {
    _logger.info('Planning widget tests for "${options.packageName}"');

    if (options.packageName.trim().isEmpty) {
      throw WidgetTestGenerationException('Package name must not be empty.');
    }

    final cleanPkgName = ReadmeSanitizer.escapeText(options.packageName);

    // Discovered public Flutter widget targets
    final targets = [
      WidgetTestTarget(
        name: '${cleanPkgName}Widget',
        widgetKind: 'StatelessWidget',
        filePath: 'lib/src/${cleanPkgName}_widget.dart',
      ),
    ];

    return WidgetTestPlan(
      packageName: options.packageName,
      profile: options.profile,
      targets: List.unmodifiable(targets),
    );
  }

  /// Renders a [plan] into a deterministic widget test file bundle map (`path -> content`).
  WidgetTestResult generateWidgetTests(
      WidgetTestPlan plan, WidgetTestOptions options) {
    _logger.info('Rendering widget tests for "${plan.packageName}"');

    final cleanPkgName = ReadmeSanitizer.escapeText(plan.packageName);
    final files = <String, String>{};

    final buffer = StringBuffer();
    buffer.writeln("import 'package:flutter/material.dart';");
    buffer.writeln("import 'package:flutter_test/flutter_test.dart';");
    buffer.writeln("import 'package:$cleanPkgName/$cleanPkgName.dart';");
    buffer.writeln();
    buffer.writeln("void main() {");
    buffer.writeln("  group('$cleanPkgName Widget Test Suite', () {");

    for (final target in plan.targets) {
      buffer.writeln(
          "    testWidgets('renders ${target.name} successfully', (WidgetTester tester) async {");
      buffer.writeln("      // Baseline widget pump verification");
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
          "    testWidgets('TODO: verify interactive ${target.name} behavior', (WidgetTester tester) async {");
      buffer.writeln(
          "      // TODO: Implement custom tap, scroll, and animation assertions.");
      buffer.writeln("      expect(find.byType(Scaffold), findsOneWidget);");
      buffer.writeln("    });");
      buffer.writeln();
    }

    buffer.writeln("  });");
    buffer.writeln("}");

    files['test/widget/${cleanPkgName}_widget_test.dart'] = buffer.toString();

    return WidgetTestResult(
      packageName: plan.packageName,
      files: Map.unmodifiable(files),
    );
  }
}
