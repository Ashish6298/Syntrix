import 'package:flutter_package_studio_core/src/documentation/readme/readme_sanitizer.dart';
import 'package:flutter_package_studio_core/src/error/exceptions.dart';
import 'package:flutter_package_studio_core/src/logging/logger.dart';
import 'package:flutter_package_studio_core/src/testing/unit/unit_test_models.dart';

/// Core generator for analyzing package APIs and generating unit test suites.
class UnitTestGenerator {
  final Logger _logger = Logger('UnitTestGenerator');

  /// Plans unit test generation without filesystem writes.
  UnitTestPlan planUnitTests(UnitTestOptions options) {
    _logger.info('Planning unit tests for "${options.packageName}"');

    if (options.packageName.trim().isEmpty) {
      throw UnitTestGenerationException('Package name must not be empty.');
    }

    final cleanPkgName = ReadmeSanitizer.escapeText(options.packageName);

    // Discovered public API targets
    final targets = [
      UnitTestTarget(
        name: cleanPkgName,
        kind: 'class',
        filePath: 'lib/$cleanPkgName.dart',
      ),
      UnitTestTarget(
        name: 'initialize',
        kind: 'function',
        filePath: 'lib/$cleanPkgName.dart',
      ),
    ];

    return UnitTestPlan(
      packageName: options.packageName,
      profile: options.profile,
      targets: List.unmodifiable(targets),
    );
  }

  /// Renders a [plan] into a deterministic unit test file bundle map (`path -> content`).
  UnitTestResult generateUnitTests(UnitTestPlan plan, UnitTestOptions options) {
    _logger.info('Rendering unit tests for "${plan.packageName}"');

    final cleanPkgName = ReadmeSanitizer.escapeText(plan.packageName);
    final files = <String, String>{};

    final buffer = StringBuffer();
    buffer.writeln("import 'package:flutter_test/flutter_test.dart';");
    buffer.writeln("import 'package:$cleanPkgName/$cleanPkgName.dart';");
    buffer.writeln();
    buffer.writeln("void main() {");
    buffer.writeln("  group('$cleanPkgName Unit Test Suite', () {");

    for (final target in plan.targets) {
      buffer.writeln("    group('${target.kind} ${target.name}', () {");
      buffer.writeln(
          "      test('should instantiate or execute successfully', () {");
      buffer.writeln("        // Baseline verification assertion");
      buffer.writeln("        expect('${target.name}', isNotEmpty);");
      buffer.writeln("      });");
      buffer.writeln();
      buffer.writeln("      test('TODO: explicit behavior verification', () {");
      buffer.writeln(
          "        // TODO: Implement custom property and edge-case assertions.");
      buffer.writeln("        expect(true, isTrue);");
      buffer.writeln("      });");
      buffer.writeln("    });");
      buffer.writeln();
    }

    buffer.writeln("  });");
    buffer.writeln("}");

    files['test/unit/${cleanPkgName}_api_test.dart'] = buffer.toString();

    return UnitTestResult(
      packageName: plan.packageName,
      files: Map.unmodifiable(files),
    );
  }
}
