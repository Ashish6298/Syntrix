import 'package:flutter_package_studio_core/src/error/exceptions.dart';
import 'package:flutter_package_studio_core/src/template/template_semver.dart';

/// Evaluates compatibility bounds for Dart SDK, Flutter SDK, platforms, and project types.
class TemplateCompatibility {
  final String minimumDartSdk;
  final String minimumFlutterSdk;
  final List<String> supportedPlatforms;
  final String projectType;

  const TemplateCompatibility({
    this.minimumDartSdk = '>=3.5.0 <4.0.0',
    this.minimumFlutterSdk = '>=3.22.0',
    this.supportedPlatforms = const [
      'android',
      'ios',
      'web',
      'windows',
      'macos',
      'linux'
    ],
    this.projectType = 'flutter_package',
  });

  /// Evaluates compatibility against current runtime environment.
  void validateCompatibility({
    String currentDartVersion = '3.5.0',
    String currentFlutterVersion = '3.22.0',
    String? targetProjectType,
  }) {
    if (targetProjectType != null && targetProjectType != projectType) {
      throw TemplateException(
          'Template project type "$projectType" does not match target project type "$targetProjectType".');
    }

    try {
      final dartVer = TemplateSemVer.parse(currentDartVersion);
      if (!dartVer.satisfies(minimumDartSdk)) {
        throw TemplateException(
            'Current Dart SDK $currentDartVersion does not satisfy template constraint $minimumDartSdk.');
      }
    } catch (e) {
      if (e is TemplateException) rethrow;
    }
  }
}
