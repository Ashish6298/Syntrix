/// Evaluation status of a release certification gate or final delivery gate.
enum ReleaseCertificationGateStatus {
  certified,
  conditionallyCertified,
  notCertified,
  blocked,
  failed,
  insufficientEvidence,
}

/// An individual evaluation gate check in the release certification pipeline.
class ReleaseCertificationGateItem {
  final String id;
  final String description;
  final ReleaseCertificationGateStatus status;
  final bool isMandatory;
  final String details;

  const ReleaseCertificationGateItem({
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

/// Options configuring release certification and final delivery gate evaluation.
class ReleaseCertificationOptions {
  final String packageName;
  final String version;
  final String channel;
  final String profile;
  final bool deliver;
  final String outputDir;

  const ReleaseCertificationOptions({
    required this.packageName,
    this.version = '1.0.0',
    this.channel = 'stable',
    this.profile = 'standard',
    this.deliver = false,
    this.outputDir = 'doc/release',
  });

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'version': version,
        'channel': channel,
        'profile': profile,
        'deliver': deliver,
        'outputDir': outputDir,
      };
}

/// Preview plan of release certification gates.
class ReleaseCertificationPlan {
  final String packageName;
  final String version;
  final String channel;
  final String profile;
  final List<ReleaseCertificationGateItem> gates;

  const ReleaseCertificationPlan({
    required this.packageName,
    required this.version,
    required this.channel,
    required this.profile,
    required this.gates,
  });

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'version': version,
        'channel': channel,
        'profile': profile,
        'gateCount': gates.length,
        'gates': gates.map((g) => g.toJson()).toList(),
      };
}

/// Result of release certification and final delivery gate evaluation.
class ReleaseCertificationResult {
  final String packageName;
  final String version;
  final String channel;
  final ReleaseCertificationGateStatus overallStatus;
  final bool isSuccess;
  final List<ReleaseCertificationGateItem> gates;

  const ReleaseCertificationResult({
    required this.packageName,
    required this.version,
    required this.channel,
    required this.overallStatus,
    required this.isSuccess,
    required this.gates,
  });

  String toMarkdown() {
    final buf = StringBuffer();
    buf.writeln(
        '# Release Certification & Final Delivery Gate Report: $packageName');
    buf.writeln();
    buf.writeln('**Package Version**: $version');
    buf.writeln('**Release Channel**: ${channel.toUpperCase()}');
    buf.writeln(
        '**Overall Certification Status**: ${overallStatus.name.toUpperCase()}');
    buf.writeln(
        '**Final Decision**: ${isSuccess ? "CERTIFIED FOR FINAL DELIVERY ✓" : "CERTIFICATION BLOCKED / FAILED ✗"}');
    buf.writeln();
    buf.writeln('## Certification Gates Summary');
    buf.writeln();
    for (final g in gates) {
      final icon =
          g.status == ReleaseCertificationGateStatus.certified ? '✓' : '✗';
      buf.writeln(
          '- **[${g.status.name.toUpperCase()}] $icon ${g.id}**: ${g.description}');
      buf.writeln('  * ${g.details}');
    }
    return buf.toString();
  }

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'version': version,
        'channel': channel,
        'overallStatus': overallStatus.name,
        'isSuccess': isSuccess,
        'gateCount': gates.length,
        'gates': gates.map((g) => g.toJson()).toList(),
      };
}
