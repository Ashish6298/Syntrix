import 'package:flutter_package_studio_core/src/wizard/wizard_flow.dart';
import 'package:flutter_package_studio_core/src/wizard/wizard_session.dart';
import 'package:flutter_package_studio_core/src/wizard/wizard_step.dart';

/// Navigation engine responsible for evaluating conditions, skipping irrelevant steps, and step indexing.
class WizardNavigator {
  final WizardFlow _flow;
  final WizardSession _session;

  /// Creates a [WizardNavigator] binding [_flow] and [_session].
  WizardNavigator(this._flow, this._session);

  /// Gets total number of defined steps in flow.
  int get totalSteps => _flow.steps.length;

  /// Gets current step index.
  int get currentIndex => _session.currentStepIndex;

  /// Determines if there is a next valid step in the flow.
  bool get hasNext {
    for (int i = _session.currentStepIndex + 1; i < _flow.steps.length; i++) {
      if (_flow.steps[i].shouldExecute(_session.context)) {
        return true;
      }
    }
    return false;
  }

  /// Determines if there is a previous valid step in the flow.
  bool get hasPrevious {
    for (int i = _session.currentStepIndex - 1; i >= 0; i--) {
      if (_flow.steps[i].shouldExecute(_session.context)) {
        return true;
      }
    }
    return false;
  }

  /// Moves to next executable step index and returns true, or false if reached end.
  bool next() {
    for (int i = _session.currentStepIndex + 1; i < _flow.steps.length; i++) {
      if (_flow.steps[i].shouldExecute(_session.context)) {
        _session.currentStepIndex = i;
        return true;
      }
    }
    return false;
  }

  /// Moves to previous executable step index and returns true, or false if at start.
  bool previous() {
    for (int i = _session.currentStepIndex - 1; i >= 0; i--) {
      if (_flow.steps[i].shouldExecute(_session.context)) {
        _session.currentStepIndex = i;
        return true;
      }
    }
    return false;
  }

  /// Jumps directly to step with [stepId]. Returns true if found and executable.
  bool jumpTo(String stepId) {
    final idx = _flow.steps.indexWhere((s) => s.id == stepId);
    if (idx != -1 && _flow.steps[idx].shouldExecute(_session.context)) {
      _session.currentStepIndex = idx;
      return true;
    }
    return false;
  }

  /// Returns current step or null.
  WizardStep? get currentStep {
    if (_session.currentStepIndex >= 0 &&
        _session.currentStepIndex < _flow.steps.length) {
      return _flow.steps[_session.currentStepIndex];
    }
    return null;
  }
}
