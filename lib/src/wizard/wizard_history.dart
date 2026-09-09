/// Stack-based history tracking answered wizard step IDs and responses for backward navigation.
class WizardHistoryEntry {
  /// Step identifier.
  final String stepId;

  /// Question identifier.
  final String questionId;

  /// Previous value before answer.
  final dynamic previousValue;

  /// New answered value.
  final dynamic newAnswer;

  /// Creates a [WizardHistoryEntry] record.
  const WizardHistoryEntry({
    required this.stepId,
    required this.questionId,
    this.previousValue,
    required this.newAnswer,
  });
}

/// Tracks wizard navigation history stack for back/undo operations.
class WizardHistory {
  final List<WizardHistoryEntry> _history = [];

  /// Pushes an entry onto the stack.
  void push(WizardHistoryEntry entry) {
    _history.add(entry);
  }

  /// Pops and returns the top entry from the history stack, or null if empty.
  WizardHistoryEntry? pop() {
    if (_history.isEmpty) return null;
    return _history.removeLast();
  }

  /// Returns true if history stack is not empty.
  bool get canGoBack => _history.isNotEmpty;

  /// Clears history stack.
  void clear() => _history.clear();

  /// Total recorded history actions.
  int get length => _history.length;
}
