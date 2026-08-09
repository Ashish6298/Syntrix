import 'package:flutter_package_studio_core/src/error/exceptions.dart';

/// Represents an example application template style.

class ExampleTemplate {
  /// Unique identifier of the example template.
  final String id;

  /// Display name of the example template.
  final String name;

  /// Description of the example template.
  final String description;

  /// Main entry point template content (`lib/main.dart`).
  final String mainDartTemplate;

  /// Widget test template content (`test/widget_test.dart`).
  final String widgetTestTemplate;

  /// Creates an [ExampleTemplate] instance.
  const ExampleTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.mainDartTemplate,
    required this.widgetTestTemplate,
  });

  /// Standard Flutter example template.
  static const ExampleTemplate standard = ExampleTemplate(
    id: 'standard',
    name: 'Standard Example Application',
    description: 'A clean, runnable Flutter demo app showing package usage.',
    mainDartTemplate: _standardMainDart,
    widgetTestTemplate: _standardWidgetTest,
  );

  /// Minimal Flutter example template.
  static const ExampleTemplate minimal = ExampleTemplate(
    id: 'minimal',
    name: 'Minimal Example Application',
    description:
        'A lightweight main entry point without extra sample UI widgets.',
    mainDartTemplate: _minimalMainDart,
    widgetTestTemplate: _standardWidgetTest,
  );

  static const String _standardMainDart = '''
import 'package:flutter/material.dart';
import 'package:{{package_name}}/{{package_name}}.dart';

void main() {
  runApp(const {{package_name_pascal}}ExampleApp());
}

/// Example Application root widget.
class {{package_name_pascal}}ExampleApp extends StatelessWidget {
  const {{package_name_pascal}}ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '{{package_name_pascal}} Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const {{package_name_pascal}}HomePage(),
    );
  }
}

/// Example Application Home Page.
class {{package_name_pascal}}HomePage extends StatefulWidget {
  const {{package_name_pascal}}HomePage({super.key});

  @override
  State<{{package_name_pascal}}HomePage> createState() => _{{package_name_pascal}}HomePageState();
}

class _{{package_name_pascal}}HomePageState extends State<{{package_name_pascal}}HomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('{{package_name_pascal}} Example'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Demonstrating {{package_name}} package:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Text(
              '\$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
''';

  static const String _minimalMainDart = '''
import 'package:flutter/material.dart';
import 'package:{{package_name}}/{{package_name}}.dart';

void main() {
  runApp(
    const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('{{package_name_pascal}} Minimal Example'),
        ),
      ),
    ),
  );
}
''';

  static const String _standardWidgetTest = '''
import 'package:flutter_test/flutter_test.dart';
import 'package:{{package_name}}_example/main.dart';

void main() {
  testWidgets('Example application renders successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const {{package_name_pascal}}ExampleApp());
    expect(find.text('{{package_name_pascal}} Example'), findsOneWidget);
  });
}
''';
}

/// Registry for managing available [ExampleTemplate] instances.
class ExampleTemplateRegistry {
  final Map<String, ExampleTemplate> _templates = {};

  /// Creates an [ExampleTemplateRegistry] initialized with defaults.
  ExampleTemplateRegistry() {
    register(ExampleTemplate.standard);
    register(ExampleTemplate.minimal);
  }

  /// Registers an [ExampleTemplate].
  void register(ExampleTemplate template) {
    _templates[template.id.toLowerCase()] = template;
  }

  /// Resolves an [ExampleTemplate] by [id]. Throws [ExampleTemplateException] if not found.
  ExampleTemplate get(String id) {
    final template = _templates[id.toLowerCase()];
    if (template == null) {
      throw ExampleTemplateException(
          'Example template "$id" not found in registry.');
    }
    return template;
  }
}
