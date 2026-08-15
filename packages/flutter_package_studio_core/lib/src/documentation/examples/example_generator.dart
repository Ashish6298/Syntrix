import 'package:flutter_package_studio_core/src/documentation/examples/example_models.dart';
import 'package:flutter_package_studio_core/src/documentation/readme/readme_sanitizer.dart';
import 'package:flutter_package_studio_core/src/logging/logger.dart';

/// Core generator for creating deterministic Dart code examples.
class CodeExampleGenerator {
  final Logger _logger = Logger('CodeExampleGenerator');

  /// Plans a code example without rendering source code.
  CodeExamplePlan planExample(CodeExampleOptions options) {
    _logger.info('Planning code example for "${options.packageName}"');

    final cleanPkgName = ReadmeSanitizer.escapeText(options.packageName);
    final defaultImport =
        'import \'package:$cleanPkgName/$cleanPkgName.dart\';';

    final imports =
        options.imports.isNotEmpty ? options.imports : [defaultImport];

    String setup = '';
    String usage = '';
    String? comments;

    switch (options.exampleType) {
      case CodeExampleType.basicUsage:
        setup = 'final client = ${cleanPkgName.pascalCase()}Client();';
        usage =
            'await client.initialize();\nfinal result = await client.execute();';
        comments = 'Basic usage example for $cleanPkgName.';
        break;
      case CodeExampleType.initialization:
        setup =
            'final config = ${cleanPkgName.pascalCase()}Config(\n  apiKey: "YOUR_API_KEY",\n);';
        usage = 'await ${cleanPkgName.pascalCase()}.init(config);';
        comments = 'Initialization example with configuration options.';
        break;
      case CodeExampleType.configuration:
        setup =
            'final options = ${cleanPkgName.pascalCase()}Options(\n  enableLogging: true,\n  timeout: Duration(seconds: 30),\n);';
        usage = 'final service = ${cleanPkgName.pascalCase()}Service(options);';
        comments = 'Custom configuration example.';
        break;
      case CodeExampleType.fullExample:
        setup =
            'void main() async {\n  WidgetsFlutterBinding.ensureInitialized();';
        usage =
            '  final app = ${cleanPkgName.pascalCase()}App();\n  runApp(app);\n}';
        comments = 'Complete minimal working Flutter application example.';
        break;
    }

    final snippet = CodeExampleSnippet(
      imports: imports,
      setup: setup,
      usage: usage,
      comments: comments,
    );

    return CodeExamplePlan(
      packageName: options.packageName,
      exampleType: options.exampleType,
      snippet: snippet,
    );
  }

  /// Renders a [plan] into deterministic Dart source code string.
  CodeExampleResult generateExample(CodeExamplePlan plan) {
    _logger.info('Rendering code example for "${plan.packageName}"');

    final buffer = StringBuffer();

    if (plan.snippet.comments != null) {
      buffer.writeln('/// ${plan.snippet.comments}');
    }

    for (final imp in plan.snippet.imports) {
      buffer.writeln(imp);
    }
    buffer.writeln('');

    if (plan.exampleType == CodeExampleType.fullExample) {
      buffer.writeln(plan.snippet.setup);
      buffer.writeln(plan.snippet.usage);
    } else {
      buffer.writeln('void main() async {');
      buffer.writeln('  // Setup');
      for (final line in plan.snippet.setup.split('\n')) {
        buffer.writeln('  $line');
      }
      buffer.writeln('');
      buffer.writeln('  // Usage');
      for (final line in plan.snippet.usage.split('\n')) {
        buffer.writeln('  $line');
      }
      buffer.writeln('}');
    }

    final code = buffer.toString().trimRight();

    return CodeExampleResult(
      packageName: plan.packageName,
      code: '$code\n',
    );
  }
}

extension on String {
  String pascalCase() {
    return split('_')
        .map((s) => s.isNotEmpty ? s[0].toUpperCase() + s.substring(1) : '')
        .join('');
  }
}
