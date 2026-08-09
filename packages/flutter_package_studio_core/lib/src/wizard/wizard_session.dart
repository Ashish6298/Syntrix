import 'dart:convert';
import 'package:flutter_package_studio_core/src/wizard/wizard_context.dart';

/// Manages interactive wizard session state, current step index, and JSON serialization.
class WizardSession {
  /// Unique session identifier.
  final String sessionId;

  /// Current step index in execution flow.
  int currentStepIndex;

  /// Current wizard context.
  WizardContext context;

  /// Map of completed step IDs to boolean completion flags.
  final Map<String, bool> completedSteps;

  /// Timestamp when session was initiated.
  final DateTime createdAt;

  /// Creates a [WizardSession] instance.
  WizardSession({
    required this.sessionId,
    this.currentStepIndex = 0,
    WizardContext? context,
    Map<String, bool>? completedSteps,
    DateTime? createdAt,
  })  : context = context ?? WizardContext(),
        completedSteps = completedSteps ?? {},
        createdAt = createdAt ?? DateTime.now();

  /// Serializes session state to JSON string for disk persistence.
  String toJson() {
    return jsonEncode({
      'sessionId': sessionId,
      'currentStepIndex': currentStepIndex,
      'context': context.toMap(),
      'completedSteps': completedSteps,
      'createdAt': createdAt.toIso8601String(),
    });
  }

  /// Deserializes a [WizardSession] from JSON string.
  factory WizardSession.fromJson(String jsonStr) {
    final map = jsonDecode(jsonStr) as Map<String, dynamic>;
    return WizardSession(
      sessionId: map['sessionId'] as String,
      currentStepIndex: map['currentStepIndex'] as int? ?? 0,
      context:
          WizardContext.fromMap(map['context'] as Map<String, dynamic>? ?? {}),
      completedSteps:
          (map['completedSteps'] as Map?)?.cast<String, bool>() ?? {},
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
