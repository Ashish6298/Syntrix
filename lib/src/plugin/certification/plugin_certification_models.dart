/// Structured models and audit data objects for Plugin Architecture Hardening & Certification (Phase 7.18).
library;

/// Category classification for Plugin Architecture Certification audit items.
enum PluginCertificationCategory {
  functional,
  security,
  reliability,
  regression,
  determinism,
}

/// Evaluation status for an individual certification gate check.
enum PluginCertificationStatus {
  passed,
  failed,
  blocked,
}

/// Overall certification verdict for Milestone 7 Plugin Architecture.
enum Milestone7CertificationVerdict {
  certified,
  notYetCertified,
}

/// Individual gate audit result item with detailed evidence.
class PluginCertificationItem {
  final String id;
  final String title;
  final PluginCertificationCategory category;
  final PluginCertificationStatus status;
  final String evidence;
  final bool isAdversarial;
  final DateTime timestamp;

  PluginCertificationItem({
    required this.id,
    required this.title,
    required this.category,
    required this.status,
    required this.evidence,
    this.isAdversarial = false,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  bool get isPassed => status == PluginCertificationStatus.passed;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category.name,
        'status': status.name,
        'evidence': evidence,
        'isAdversarial': isAdversarial,
        'timestamp': timestamp.toIso8601String(),
      };
}

/// Complete, structured result of orchestrating the Plugin Architecture Hardening & Certification suite.
class PluginArchitectureCertificationResult {
  final DateTime evaluatedAt;
  final List<PluginCertificationItem> items;
  final int totalScenarios;
  final int passedScenarios;
  final int failedScenarios;
  final Milestone7CertificationVerdict verdict;
  final List<String> findings;

  PluginArchitectureCertificationResult({
    required this.items,
    DateTime? evaluatedAt,
  })  : evaluatedAt = evaluatedAt ?? DateTime.now(),
        totalScenarios = items.length,
        passedScenarios = items.where((i) => i.isPassed).length,
        failedScenarios = items.where((i) => !i.isPassed).length,
        verdict = items.every((i) => i.isPassed)
            ? Milestone7CertificationVerdict.certified
            : Milestone7CertificationVerdict.notYetCertified,
        findings = List.unmodifiable(items
            .where((i) => !i.isPassed)
            .map((i) => '[${i.id}] ${i.title}: ${i.evidence}'));

  bool get isCertified => verdict == Milestone7CertificationVerdict.certified;

  Map<String, dynamic> toJson() => {
        'evaluatedAt': evaluatedAt.toIso8601String(),
        'totalScenarios': totalScenarios,
        'passedScenarios': passedScenarios,
        'failedScenarios': failedScenarios,
        'verdict': verdict.name,
        'findings': findings,
        'items': items.map((i) => i.toJson()).toList(),
      };

  String toMarkdownReport() {
    final sb = StringBuffer();
    sb.writeln(
        '# Milestone 7: Plugin Architecture Hardening & Certification Report');
    sb.writeln('');
    sb.writeln('**Verdict:** `${verdict.name.toUpperCase()}`');
    sb.writeln('**Evaluated At:** `${evaluatedAt.toIso8601String()}`');
    sb.writeln(
        '**Scenarios Evaluated:** $totalScenarios | **Passed:** $passedScenarios | **Failed:** $failedScenarios');
    sb.writeln('');
    sb.writeln('## Category Breakdown');
    sb.writeln('');
    for (final cat in PluginCertificationCategory.values) {
      final catItems = items.where((i) => i.category == cat).toList();
      final passCount = catItems.where((i) => i.isPassed).length;
      sb.writeln(
          '### ${cat.name.toUpperCase()} ($passCount/${catItems.length})');
      sb.writeln('| ID | Title | Status | Adversarial | Evidence |');
      sb.writeln('|---|---|---|---|---|');
      for (final item in catItems) {
        final icon = item.isPassed ? 'PASS' : 'FAIL';
        final adv = item.isAdversarial ? 'YES' : 'NO';
        sb.writeln(
            '| `${item.id}` | ${item.title} | **$icon** | $adv | ${item.evidence} |');
      }
      sb.writeln('');
    }

    if (findings.isNotEmpty) {
      sb.writeln('## Unresolved Findings');
      for (final f in findings) {
        sb.writeln('- $f');
      }
      sb.writeln('');
    }

    return sb.toString();
  }
}
