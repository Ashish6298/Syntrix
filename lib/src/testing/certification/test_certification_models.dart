/// Status of an individual quality gate requirement.
enum CertificationGateStatus {
  passed,
  failed,
  warning,
  skipped,
  notRun,
  unavailable,
  blocked,
  insufficientEvidence,
}

/// Final aggregate certification decision.
enum CertificationDecision {
  certified,
  conditionallyCertified,
  failed,
  blocked,
  notCertified,
  insufficientEvidence,
}

/// A single quality requirement gate in the certification process.
class CertificationGate {
  final String id;
  final String description;
  final CertificationGateStatus status;
  final bool isMandatory;
  final String details;

  const CertificationGate({
    required this.id,
    required this.description,
    required this.status,
    required this.isMandatory,
    required this.details,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'description': description,
        'status': status.name,
        'isMandatory': isMandatory,
        'details': details,
      };
}

/// Options configuring test quality certification.
class TestCertificationOptions {
  final String packageName;
  final String profile; // 'standard', 'strict', 'custom'
  final String configPath;

  const TestCertificationOptions({
    required this.packageName,
    this.profile = 'standard',
    this.configPath = 'test/certification_config.json',
  });

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'profile': profile,
        'configPath': configPath,
      };
}

/// Preview plan of test quality certification.
class TestCertificationPlan {
  final String packageName;
  final String profile;
  final String configPath;

  const TestCertificationPlan({
    required this.packageName,
    required this.profile,
    required this.configPath,
  });

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'profile': profile,
        'configPath': configPath,
      };
}

/// Result of test quality certification evaluation.
class TestCertificationResult {
  final String packageName;
  final CertificationDecision decision;
  final List<CertificationGate> gates;

  const TestCertificationResult({
    required this.packageName,
    required this.decision,
    required this.gates,
  });

  bool get isCertified =>
      decision == CertificationDecision.certified ||
      decision == CertificationDecision.conditionallyCertified;

  String toMarkdown() {
    final buf = StringBuffer();
    buf.writeln('# Test Quality & Certification Report: $packageName');
    buf.writeln();
    buf.writeln('**Certification Decision**: ${decision.name.toUpperCase()}');
    buf.writeln();
    buf.writeln('| Gate ID | Description | Mandatory | Status | Details |');
    buf.writeln('|---|---|---|---|---|');
    for (final g in gates) {
      buf.writeln(
          '| ${g.id} | ${g.description} | ${g.isMandatory ? "YES" : "NO"} | ${g.status.name.toUpperCase()} | ${g.details} |');
    }
    return buf.toString();
  }

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'decision': decision.name,
        'isCertified': isCertified,
        'gateCount': gates.length,
        'gates': gates.map((g) => g.toJson()).toList(),
      };
}
