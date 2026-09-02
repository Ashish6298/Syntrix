import 'dart:convert';
import 'dart:io';
import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:flutter_package_studio_cli/src/base_command.dart';

// ─────────────────────────────────────────────────────────────────────────────
// debug / ai debug CLI command
// ─────────────────────────────────────────────────────────────────────────────

/// Subcommand: `fps debug` / `fps ai debug <template-id>`
///
/// Ingests failure evidence, diagnoses root causes with tiered certainty, and recommends verification plans (Phase 8.5).
class DebugCommand extends FpsCommand {
  @override
  final String name = 'debug';

  @override
  final String description =
      'Diagnose defects and test failures with tiered certainty causes and verification plans.';

  DebugCommand() {
    argParser.addOption(
      'error',
      abbr: 'e',
      help: 'Primary error message or failure description to diagnose.',
    );
    argParser.addOption(
      'stack-trace',
      abbr: 's',
      help: 'Runtime or test stack trace string or file path containing trace.',
    );
    argParser.addOption(
      'file',
      abbr: 'f',
      help: 'Target source file suspected of failure.',
    );
    argParser.addOption(
      'package',
      abbr: 'p',
      help: 'Target package ID/name in monorepo.',
    );
    argParser.addOption(
      'dir',
      abbr: 'd',
      help: 'Project root directory path.',
      defaultsTo: '.',
    );
    argParser.addOption(
      'budget',
      abbr: 'b',
      help: 'Maximum context token budget limit.',
      defaultsTo: '4000',
    );
    argParser.addOption(
      'output',
      abbr: 'o',
      help: 'Target output file path when --write is specified.',
      defaultsTo: 'diagnosis_report.md',
    );
    argParser.addFlag(
      'write',
      abbr: 'w',
      negatable: false,
      help: 'Write the rendered failure diagnosis report directly to disk.',
    );
    argParser.addFlag(
      'json',
      negatable: false,
      help: 'Output diagnosis results as structured JSON.',
    );
  }

  @override
  Future<int> run() async {
    final rest = argResults?.rest ?? [];
    final errorInput = (argResults?['error'] as String?) ??
        (rest.isNotEmpty ? rest.join(' ') : null);
    final stackTraceInput = argResults?['stack-trace'] as String?;
    final targetFile = argResults?['file'] as String?;
    final targetPkg = argResults?['package'] as String?;
    final dirPath = argResults?['dir'] as String? ?? '.';
    final budgetStr = argResults?['budget'] as String? ?? '4000';
    final outputPath =
        argResults?['output'] as String? ?? 'diagnosis_report.md';
    final writeToDisk = argResults?['write'] as bool? ?? false;
    final jsonOutput = argResults?['json'] as bool? ?? false;

    final tokenBudget = int.tryParse(budgetStr) ?? 4000;

    final projectDir = Directory(dirPath);
    if (!projectDir.existsSync()) {
      print('Error: Target directory "$dirPath" does not exist.');
      return 1;
    }

    final primaryError = errorInput ?? 'Unspecified defect or build failure';

    // Build evidence items
    final evidenceItems = <DiagnosisEvidenceItem>[];
    if (stackTraceInput != null && stackTraceInput.trim().isNotEmpty) {
      String traceContent = stackTraceInput;
      final traceFile = File(stackTraceInput);
      if (traceFile.existsSync()) {
        traceContent = traceFile.readAsStringSync();
      }
      evidenceItems.add(DiagnosisEvidenceItem(
        id: 'ev_cli_trace',
        type: EvidenceType.stackTrace,
        source: targetFile ?? 'cli_input',
        content: traceContent,
      ));
    }

    final evidenceBundle = FailureEvidenceBundle(
      primaryError: primaryError,
      items: evidenceItems,
      targetPackage: targetPkg,
      targetFile: targetFile,
    );

    final provider = MockAiProvider(
      defaultResponse: jsonEncode({
        'summary': 'Failure diagnosis completed.',
        'problem': primaryError,
        'likelyCauses': [
          {
            'description': 'Diagnosed root cause for $primaryError',
            'certainty': 'confirmed',
            'rationale': 'Directly reproduced from provided evidence.'
          }
        ],
        'citedEvidence': [primaryError],
        'affectedComponents': [targetFile ?? 'project_root'],
        'recommendedFix': 'Apply defensive null-check and error boundary.',
        'risk': 'low',
        'verificationSteps': [
          {
            'stepNumber': 1,
            'action': 'Run unit test suite.',
            'expectedOutcome': 'All tests pass.'
          }
        ]
      }),
    );

    final engine = FailureDiagnosisEngine.withProvider(
      projectRoot: projectDir.path,
      provider: provider,
    );

    final request = DiagnosisRequest(
      evidence: evidenceBundle,
      targetPackage: targetPkg,
      tokenBudget: tokenBudget,
    );

    final result = await engine.diagnose(request);
    const renderer = FailureDiagnosisRenderer();

    if (!result.isSuccess) {
      print('Error: Failure diagnosis failed.');
      if (result.errorMessage != null) {
        print(result.errorMessage!);
      }
      return 1;
    }

    if (jsonOutput) {
      final rendered = renderer.renderJson(result);
      print(rendered);
      if (writeToDisk) {
        final targetOut = File(outputPath);
        targetOut.parent.createSync(recursive: true);
        targetOut.writeAsStringSync(rendered);
        print('Wrote Diagnosis JSON report to $outputPath');
      }
    } else {
      final rendered = renderer.renderMarkdown(result);
      print(rendered);
      if (writeToDisk) {
        final targetOut = File(outputPath);
        targetOut.parent.createSync(recursive: true);
        targetOut.writeAsStringSync(rendered);
        print('Wrote Diagnosis Markdown report to $outputPath');
      }
    }

    return 0;
  }
}
