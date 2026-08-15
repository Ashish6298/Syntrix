/// Test fixture generator for template testing framework.
library;

import 'package:flutter_package_studio_core/src/template/template_manifest.dart';
import 'package:flutter_package_studio_core/src/template/template_model.dart';

/// Helper factory constructing isolated in-memory [Template] fixtures for tests.
class TemplateTestFixture {
  /// Creates a valid standard template fixture.
  static Template validTemplate({String id = 'fixture_valid'}) {
    final manifest = TemplateManifest(
      id: id,
      name: 'Valid Fixture Template',
      displayName: 'Valid Fixture Template',
      description: 'A valid production-ready template fixture.',
      version: '1.0.0',
      projectType: 'flutter_package',
      minimumDartSdk: '>=3.5.0 <4.0.0',
      files: {'lib/fixture.dart': '// Valid content'},
    );
    return Template(manifest: manifest);
  }

  /// Creates a template fixture with invalid SemVer version.
  static Template invalidSemverTemplate(
      {String id = 'fixture_invalid_semver'}) {
    final manifest = TemplateManifest(
      id: id,
      name: 'Invalid SemVer Fixture',
      displayName: 'Invalid SemVer Fixture',
      description: 'Template with malformed semver.',
      version: 'v1.0-invalid',
      projectType: 'flutter_package',
      minimumDartSdk: '>=3.5.0 <4.0.0',
    );
    return Template(manifest: manifest);
  }

  /// Creates a template fixture with absolute path security violation.
  static Template unsafePathTemplate({String id = 'fixture_unsafe_path'}) {
    final manifest = TemplateManifest(
      id: id,
      name: 'Unsafe Path Fixture',
      displayName: 'Unsafe Path Fixture',
      description: 'Template declaring an absolute target file path.',
      version: '1.0.0',
      projectType: 'flutter_package',
      minimumDartSdk: '>=3.5.0 <4.0.0',
      files: {'/etc/passwd': 'root'},
    );
    return Template(manifest: manifest);
  }
}
