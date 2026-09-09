import 'package:syntrix/src/utils/file_utils.dart';
import 'package:syntrix/src/validation/validation_models.dart';

/// Abstract contract for a single composable validation rule.
abstract interface class ValidationRule {
  /// Unique stable identifier of the rule (e.g. `STRUCT_001`).
  String get id;

  /// Human-readable title of the rule.
  String get title;

  /// Category classification of the rule.
  ValidationCategory get category;

  /// Default severity of the rule.
  ValidationSeverity get defaultSeverity;

  /// Executes validation logic against [targetDirectory].
  Future<List<ValidationIssue>> validate({
    required String targetDirectory,
    required FileUtils fileUtils,
  });
}
