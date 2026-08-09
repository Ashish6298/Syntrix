import 'package:flutter_package_studio_core/src/logging/logger.dart';
import 'package:flutter_package_studio_core/src/utils/file_utils.dart';
import 'package:flutter_package_studio_core/src/validation/validation_models.dart';
import 'package:flutter_package_studio_core/src/validation/validation_registry.dart';

/// Central engine for orchestrating non-mutating validation runs.
class ValidationEngine {
  final FileUtils _fileUtils;
  final ValidationRuleRegistry _registry;
  final Logger _logger;

  /// Creates a [ValidationEngine] instance with dependencies.
  ValidationEngine({
    FileUtils fileUtils = const SystemFileUtils(),
    ValidationRuleRegistry? registry,
    Logger? logger,
  })  : _fileUtils = fileUtils,
        _registry = registry ?? ValidationRuleRegistry(),
        _logger = logger ?? Logger('ValidationEngine');

  /// Executes validation rules based on [request]. Zero filesystem mutations guaranteed.
  Future<ValidationReport> validate(ValidationRequest request) async {
    final stopwatch = Stopwatch()..start();
    final rules = _registry.resolveProfile(request.profile);

    final issues = <ValidationIssue>[];
    int passedRulesCount = 0;

    _logger.info(
        'Executing validation engine for target "${request.targetDirectory}" (profile: ${request.profile})');

    for (final rule in rules) {
      if (request.ruleIds != null && !request.ruleIds!.contains(rule.id)) {
        continue;
      }
      if (request.categories != null &&
          !request.categories!.contains(rule.category)) {
        continue;
      }

      try {
        final ruleIssues = await rule.validate(
          targetDirectory: request.targetDirectory,
          fileUtils: _fileUtils,
        );

        if (ruleIssues.isEmpty) {
          passedRulesCount++;
        } else {
          issues.addAll(ruleIssues);
        }
      } catch (e, st) {
        _logger.error('Rule ${rule.id} failed with error: $e', e, st);
        issues.add(ValidationIssue(
          ruleId: rule.id,
          category: rule.category,
          severity: ValidationSeverity.error,
          message: 'Rule exception: $e',
        ));
      }
    }

    stopwatch.stop();

    final infoCount =
        issues.where((i) => i.severity == ValidationSeverity.info).length;
    final warningCount =
        issues.where((i) => i.severity == ValidationSeverity.warning).length;
    final errorCount =
        issues.where((i) => i.severity == ValidationSeverity.error).length;

    final summary = ValidationSummary(
      totalRulesExecuted: rules.length,
      passedRulesCount: passedRulesCount,
      infoCount: infoCount,
      warningCount: warningCount,
      errorCount: errorCount,
    );

    return ValidationReport(
      targetDirectory: request.targetDirectory,
      profile: request.profile,
      duration: stopwatch.elapsed,
      issues: issues,
      summary: summary,
    );
  }
}
