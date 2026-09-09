/// Domain models and audit criteria for Phase 11.6: Documentation Certification.
library;

/// Essential project and repository documentation files.
enum DocumentationFileTarget {
  readme,
  changelog,
  license,
  contributing,
  codeOfConduct,
  security,
  docDirectory,
  exampleDirectory;

  String get id => name;

  String get filename {
    switch (this) {
      case DocumentationFileTarget.readme:
        return 'README.md';
      case DocumentationFileTarget.changelog:
        return 'CHANGELOG.md';
      case DocumentationFileTarget.license:
        return 'LICENSE';
      case DocumentationFileTarget.contributing:
        return 'CONTRIBUTING.md';
      case DocumentationFileTarget.codeOfConduct:
        return 'CODE_OF_CONDUCT.md';
      case DocumentationFileTarget.security:
        return 'SECURITY.md';
      case DocumentationFileTarget.docDirectory:
        return 'doc/';
      case DocumentationFileTarget.exampleDirectory:
        return 'example/';
    }
  }
}

/// Mandatory topic coverage dimensions.
enum DocumentationTopicDimension {
  installation,
  basicUsage,
  advancedUsage,
  architecture,
  customization,
  themes,
  loaders,
  performance,
  apiReference,
  troubleshooting,
  examples,
  migrationInformation;

  String get id => name;

  String get label {
    switch (this) {
      case DocumentationTopicDimension.installation:
        return 'Installation';
      case DocumentationTopicDimension.basicUsage:
        return 'Basic usage';
      case DocumentationTopicDimension.advancedUsage:
        return 'Advanced usage';
      case DocumentationTopicDimension.architecture:
        return 'Architecture';
      case DocumentationTopicDimension.customization:
        return 'Customization';
      case DocumentationTopicDimension.themes:
        return 'Themes';
      case DocumentationTopicDimension.loaders:
        return 'Loaders';
      case DocumentationTopicDimension.performance:
        return 'Performance';
      case DocumentationTopicDimension.apiReference:
        return 'API reference';
      case DocumentationTopicDimension.troubleshooting:
        return 'Troubleshooting';
      case DocumentationTopicDimension.examples:
        return 'Examples';
      case DocumentationTopicDimension.migrationInformation:
        return 'Migration information';
    }
  }
}

/// Status of a documentation item audit.
enum DocAuditStatus {
  certified,
  missing,
  incomplete;

  String get id => name;

  String get label {
    switch (this) {
      case DocAuditStatus.certified:
        return 'CERTIFIED';
      case DocAuditStatus.missing:
        return 'MISSING';
      case DocAuditStatus.incomplete:
        return 'INCOMPLETE';
    }
  }

  String get symbol => this == DocAuditStatus.certified
      ? '✓'
      : (this == DocAuditStatus.incomplete ? '⚠' : '✗');
}

/// Item representing an audited documentation file or topic.
class DocumentationAuditItem {
  final String identifier;
  final String itemType; // 'file' or 'topic'
  final DocAuditStatus status;
  final String verificationDetails;

  const DocumentationAuditItem({
    required this.identifier,
    required this.itemType,
    this.status = DocAuditStatus.certified,
    required this.verificationDetails,
  });

  Map<String, dynamic> toJson() => {
        'identifier': identifier,
        'item_type': itemType,
        'status': status.id,
        'verification_details': verificationDetails,
      };

  factory DocumentationAuditItem.fromJson(Map<String, dynamic> json) {
    return DocumentationAuditItem(
      identifier: json['identifier'] as String? ?? '',
      itemType: json['item_type'] as String? ?? 'file',
      status: DocAuditStatus.values.firstWhere(
        (s) => s.id == json['status'] || s.name == json['status'],
        orElse: () => DocAuditStatus.certified,
      ),
      verificationDetails: json['verification_details'] as String? ?? '',
    );
  }
}

/// Comprehensive Phase 11.6 Documentation Certification Report.
class DocumentationCertificationReport {
  final String reportId;
  final String targetVersion;
  final bool isDocCertified;
  final int totalFilesAudited;
  final int totalTopicsAudited;
  final List<DocumentationAuditItem> fileItems;
  final List<DocumentationAuditItem> topicItems;
  final DateTime certifiedAt;

  const DocumentationCertificationReport({
    required this.reportId,
    required this.targetVersion,
    required this.isDocCertified,
    required this.totalFilesAudited,
    required this.totalTopicsAudited,
    required this.fileItems,
    required this.topicItems,
    required this.certifiedAt,
  });

  Map<String, dynamic> toJson() => {
        'report_id': reportId,
        'target_version': targetVersion,
        'is_doc_certified': isDocCertified,
        'total_files_audited': totalFilesAudited,
        'total_topics_audited': totalTopicsAudited,
        'file_items': fileItems.map((i) => i.toJson()).toList(),
        'topic_items': topicItems.map((i) => i.toJson()).toList(),
        'certified_at': certifiedAt.toIso8601String(),
      };

  factory DocumentationCertificationReport.fromJson(Map<String, dynamic> json) {
    return DocumentationCertificationReport(
      reportId: json['report_id'] as String? ?? 'doc_cert_default',
      targetVersion: json['target_version'] as String? ?? '1.0.0',
      isDocCertified: json['is_doc_certified'] as bool? ?? true,
      totalFilesAudited: json['total_files_audited'] as int? ?? 0,
      totalTopicsAudited: json['total_topics_audited'] as int? ?? 0,
      fileItems: (json['file_items'] as List<dynamic>?)
              ?.map((i) =>
                  DocumentationAuditItem.fromJson(i as Map<String, dynamic>))
              .toList() ??
          const [],
      topicItems: (json['topic_items'] as List<dynamic>?)
              ?.map((i) =>
                  DocumentationAuditItem.fromJson(i as Map<String, dynamic>))
              .toList() ??
          const [],
      certifiedAt: DateTime.parse(
          json['tested_at'] as String? ?? json['certified_at'] as String),
    );
  }
}
