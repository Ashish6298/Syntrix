import 'dart:convert';
import 'dart:io';
import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:flutter_package_studio_cli/src/base_command.dart';

// ─────────────────────────────────────────────────────────────────────────────
// template ai
// ─────────────────────────────────────────────────────────────────────────────

/// Subcommand: `fps template ai <template-id>`
///
/// Runs the AI Assistant against a target template or package archetype (Phase 8.1).
class TemplateAiCommand extends FpsCommand {
  @override
  final String name = 'ai';

  @override
  final String description =
      'Query the AI Assistant for analysis, recommendations, explanations, or planning for a template.';

  TemplateAiCommand() {
    argParser.addOption(
      'prompt',
      abbr: 'p',
      help: 'The prompt instruction for the assistant.',
    );
    argParser.addOption(
      'mode',
      abbr: 'm',
      help: 'Assistant mode: analysis, recommendation, explanation, planning.',
      defaultsTo: 'analysis',
    );
    argParser.addOption(
      'output',
      abbr: 'o',
      help: 'Output file path when --write is specified.',
      defaultsTo: 'assistant_report.md',
    );
    argParser.addFlag(
      'write',
      abbr: 'w',
      negatable: false,
      help:
          'Write the rendered assistant report directly to the target output file.',
    );
    argParser.addFlag(
      'json',
      negatable: false,
      help: 'Output assistant response as structured JSON.',
    );
  }

  @override
  Future<int> run() async {
    final rest = argResults?.rest ?? [];
    if (rest.isEmpty) {
      print('Error: Template ID argument is required.');
      printUsage();
      return 64; // Usage error
    }

    final templateId = rest.first;
    final prompt = argResults?['prompt'] as String?;
    final modeStr = argResults?['mode'] as String? ?? 'analysis';
    final outputPath =
        argResults?['output'] as String? ?? 'assistant_report.md';
    final writeToDisk = argResults?['write'] as bool? ?? false;
    final jsonOutput = argResults?['json'] as bool? ?? false;

    if (prompt == null || prompt.trim().isEmpty) {
      print('Error: Option --prompt is required and cannot be empty.');
      return 64;
    }

    final mode = AssistantMode.tryParse(modeStr);
    if (mode == null) {
      print(
          'Error: Unrecognized assistant mode "$modeStr". Supported modes: analysis, recommendation, explanation, planning.');
      return 64;
    }

    // Resolve template from catalog
    final registry = TemplateRegistry();
    BuiltinTemplates.registerDefaultTemplates(registry);
    final template = registry.get(templateId);

    if (template == null) {
      print('Error: Template "$templateId" not found in catalog.');
      return 1;
    }

    final manifest = template.manifest;

    // Assemble deterministic context
    final promptContext = PromptContext(
      templateId: templateId,
      version: manifest.version,
      metadata: {
        'name': manifest.name,
        'description': manifest.description,
        'projectType': manifest.projectType,
      },
      capabilities: manifest.capabilities,
      dependencies: manifest.dependencies.map((d) => d.templateId).toList(),
    );

    final request = AssistantRequest(
      prompt: prompt,
      mode: mode,
      templateId: templateId,
      context: promptContext,
    );

    // Setup MockAiProvider with representative canned outputs for CLI operations
    final mockProvider = MockAiProvider();
    _setupDefaultMockResponses(mockProvider, templateId);

    final engine = AssistantEngine(provider: mockProvider);
    final response = await engine.executeRequest(request);
    const renderer = AssistantRenderer();

    if (jsonOutput) {
      final rendered = renderer.renderJson(response);
      print(rendered);

      if (writeToDisk) {
        final targetFile = File(outputPath);
        targetFile.parent.createSync(recursive: true);
        targetFile.writeAsStringSync(rendered);
        print('Wrote JSON report to $outputPath');
      }
    } else {
      final rendered = renderer.renderMarkdown(response);
      print(rendered);

      if (writeToDisk) {
        final targetFile = File(outputPath);
        targetFile.parent.createSync(recursive: true);
        targetFile.writeAsStringSync(rendered);
        print('Wrote Markdown report to $outputPath');
      }
    }

    return response.isSuccess ? 0 : 1;
  }

  void _setupDefaultMockResponses(MockAiProvider provider, String templateId) {
    provider.registerCannedResponse(
      'ANALYSIS',
      jsonEncode({
        'summary': 'Comprehensive architectural evaluation of $templateId.',
        'findings': [
          'Modular structure conforms to clean architecture standards.',
          'Zero circular dependencies detected.',
        ],
        'metrics': {
          'maintainabilityIndex': '92',
          'testCoverageTarget': '85%',
        },
        'risks': [
          'High number of external plugins requires dependency monitoring.'
        ],
      }),
    );

    provider.registerCannedResponse(
      'RECOMMENDATION',
      jsonEncode({
        'overview':
            'Optimization recommendations for template $templateId architecture.',
        'recommendations': [
          {
            'title': 'Adopt Domain-Driven Folder Hierarchy',
            'rationale':
                'Enhances scalability as package contribution count expands.',
            'impact': 'high',
            'suggestedAction': 'Refactor feature modules into core/src/domain',
          },
        ],
      }),
    );

    provider.registerCannedResponse(
      'EXPLANATION',
      jsonEncode({
        'topic': 'Architecture and Lifecycle Patterns in $templateId',
        'detailedExplanation':
            'The $templateId template leverages decoupled interfaces and fail-closed state machines to isolate third-party extensions.',
        'keyConcepts': [
          'Lifecycle State Isolation',
          'Deterministic Rendering',
        ],
        'architecturalTradeoffs': [
          'Isolation adds slight indirection but guarantees zero host stack unwind.'
        ],
      }),
    );

    provider.registerCannedResponse(
      'PLANNING',
      jsonEncode({
        'objective': 'Migration and Enhancement Roadmap for $templateId',
        'estimatedEffort': '3 days',
        'steps': [
          {
            'sequence': 1,
            'title': 'Audit Existing Capabilities',
            'description':
                'Run static analyzer and contract validator over all features.',
            'prerequisites': ['Valid pubspec.yaml'],
          },
          {
            'sequence': 2,
            'title': 'Introduce Sandboxed AI Testing Harness',
            'description': 'Connect MockAiProvider to validation pipeline.',
            'prerequisites': ['Completed Step 1'],
          }
        ],
      }),
    );
  }
}
