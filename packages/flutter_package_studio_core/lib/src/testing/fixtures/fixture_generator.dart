import 'package:flutter_package_studio_core/src/documentation/readme/readme_sanitizer.dart';
import 'package:flutter_package_studio_core/src/error/exceptions.dart';
import 'package:flutter_package_studio_core/src/logging/logger.dart';
import 'package:flutter_package_studio_core/src/testing/fixtures/fixture_models.dart';

/// Core generator for analyzing package APIs and generating test fixtures & mocks.
class TestFixtureGenerator {
  final Logger _logger = Logger('TestFixtureGenerator');

  /// Plans fixture generation without filesystem writes.
  FixturePlan planFixtures(FixtureOptions options) {
    _logger.info('Planning test fixtures for "${options.packageName}"');

    if (options.packageName.trim().isEmpty) {
      throw TestFixtureGenerationException('Package name must not be empty.');
    }

    final cleanPkgName = ReadmeSanitizer.escapeText(options.packageName);

    final fixtureTargets = [
      FixtureTarget(
        name: '${cleanPkgName}Config',
        category: 'config',
        filePath: 'lib/src/${cleanPkgName}_config.dart',
      ),
    ];

    final mockTargets = [
      MockTarget(
        name: '${cleanPkgName}Service',
        serviceKind: 'service',
        filePath: 'lib/src/${cleanPkgName}_service.dart',
      ),
    ];

    return FixturePlan(
      packageName: options.packageName,
      profile: options.profile,
      fixtureTargets: List.unmodifiable(fixtureTargets),
      mockTargets: List.unmodifiable(mockTargets),
    );
  }

  /// Renders a [plan] into a deterministic fixture/mock file bundle map (`path -> content`).
  FixtureResult generateFixtures(FixturePlan plan, FixtureOptions options) {
    _logger.info('Rendering test fixtures and mocks for "${plan.packageName}"');

    final cleanPkgName = ReadmeSanitizer.escapeText(plan.packageName);
    final files = <String, String>{};

    // Fixtures file
    final fixBuffer = StringBuffer();
    fixBuffer.writeln("// Test fixture factories for $cleanPkgName");
    fixBuffer.writeln("import 'package:$cleanPkgName/$cleanPkgName.dart';");
    fixBuffer.writeln();
    fixBuffer.writeln("class ${cleanPkgName}TestFixtures {");

    for (final fix in plan.fixtureTargets) {
      fixBuffer.writeln(
          "  static Map<String, dynamic> sample${fix.name}Json() => {");
      fixBuffer.writeln("    'id': 'fixture_sample_1',");
      fixBuffer.writeln("    'name': '${fix.name} Sample Data',");
      fixBuffer.writeln("  };");
      fixBuffer.writeln();
    }

    fixBuffer.writeln("}");
    files['test/fixtures/${cleanPkgName}_fixtures.dart'] = fixBuffer.toString();

    // Mocks file
    final mockBuffer = StringBuffer();
    mockBuffer
        .writeln("// Controlled dependency mocks and stubs for $cleanPkgName");
    mockBuffer.writeln("import 'package:$cleanPkgName/$cleanPkgName.dart';");
    mockBuffer.writeln();

    for (final mock in plan.mockTargets) {
      mockBuffer.writeln("class Mock${mock.name} {");
      mockBuffer.writeln("  // Controlled mock stub double");
      mockBuffer.writeln("  Future<bool> initialize() async => true;");
      mockBuffer.writeln("  // TODO: Add custom stub behavior overrides");
      mockBuffer.writeln("}");
      mockBuffer.writeln();
    }

    files['test/mocks/${cleanPkgName}_mocks.dart'] = mockBuffer.toString();

    return FixtureResult(
      packageName: plan.packageName,
      files: Map.unmodifiable(files),
    );
  }
}
