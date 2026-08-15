import 'package:flutter_package_studio_core/src/documentation/api/api_extractor.dart';
import 'package:flutter_package_studio_core/src/documentation/api/api_models.dart';
import 'package:flutter_package_studio_core/src/documentation/readme/readme_sanitizer.dart';
import 'package:flutter_package_studio_core/src/logging/logger.dart';
import 'package:flutter_package_studio_core/src/template/template_model.dart';

/// Core generator for API reference documentation.
class ApiDocGenerator {
  final ApiExtractor extractor;
  final Logger _logger = Logger('ApiDocGenerator');

  ApiDocGenerator({ApiExtractor? extractor})
      : extractor = extractor ?? ApiExtractor();

  /// Plans API documentation from options.
  ApiDocPlan planApiDoc(ApiDocOptions options) {
    _logger.info('Planning API documentation for "${options.packageName}"');
    return ApiDocPlan(
      packageName: options.packageName,
      symbols: options.symbols,
    );
  }

  /// Plans API documentation by extracting symbols from a [Template].
  ApiDocPlan planFromTemplate(Template template) {
    _logger.info('Extracting API symbols from template "${template.id}"');
    final symbols = extractor.extractFromFiles(template.fileTemplates);
    final options = ApiDocOptions(
      packageName: template.manifest.name,
      version: template.version,
      symbols: symbols,
    );

    return planApiDoc(options);
  }

  /// Renders a plan into deterministic Markdown API reference documentation.
  ApiDocResult generateApiDoc(ApiDocPlan plan) {
    _logger
        .info('Rendering API documentation markdown for "${plan.packageName}"');

    final buffer = StringBuffer();
    final cleanPkgName = ReadmeSanitizer.escapeText(plan.packageName);

    buffer.writeln('# API Reference — $cleanPkgName\n');

    if (plan.symbols.isEmpty) {
      buffer.writeln('No public API symbols documented.\n');
    } else {
      buffer.writeln('## Public Symbols\n');

      for (final s in plan.symbols) {
        final deprecationTag = s.isDeprecated ? ' `[DEPRECATED]`' : '';
        buffer.writeln('### `${s.name}`$deprecationTag\n');
        buffer.writeln('**Signature**: `${s.typeSignature}`\n');

        if (s.docComment.isNotEmpty) {
          buffer.writeln('${s.docComment}\n');
        }

        if (s.parameters.isNotEmpty) {
          buffer.writeln('**Parameters:**');
          for (final p in s.parameters) {
            buffer.writeln('- `${p.name}` (`${p.type}`)');
          }
          buffer.writeln('');
        }
      }
    }

    final markdown = buffer.toString().trimRight();

    return ApiDocResult(
      packageName: plan.packageName,
      markdown: '$markdown\n',
      symbolCount: plan.symbols.length,
    );
  }
}
