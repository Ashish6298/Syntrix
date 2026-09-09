/// Domain models and evaluation criteria for Phase 11.4: Platform Verification.
library;

/// Supported target platforms.
enum TargetPlatformType {
  android,
  ios,
  web,
  windows,
  macos,
  linux;

  String get id => name;

  String get label {
    switch (this) {
      case TargetPlatformType.android:
        return 'Android';
      case TargetPlatformType.ios:
        return 'iOS';
      case TargetPlatformType.web:
        return 'Web';
      case TargetPlatformType.windows:
        return 'Windows';
      case TargetPlatformType.macos:
        return 'macOS';
      case TargetPlatformType.linux:
        return 'Linux';
    }
  }
}

/// Specialized platform behavior dimensions.
enum PlatformVerificationDimension {
  initialization,
  rendering,
  animations,
  lifecycle,
  resizing,
  disposal,
  hotReload,
  hotRestart,
  orientationChanges,
  backgroundForegroundTransitions,
  highDpiDisplays,
  differentScreenSizes;

  String get id => name;

  String get label {
    switch (this) {
      case PlatformVerificationDimension.initialization:
        return 'Initialization';
      case PlatformVerificationDimension.rendering:
        return 'Rendering';
      case PlatformVerificationDimension.animations:
        return 'Animations';
      case PlatformVerificationDimension.lifecycle:
        return 'Lifecycle';
      case PlatformVerificationDimension.resizing:
        return 'Resizing';
      case PlatformVerificationDimension.disposal:
        return 'Disposal';
      case PlatformVerificationDimension.hotReload:
        return 'Hot reload';
      case PlatformVerificationDimension.hotRestart:
        return 'Hot restart';
      case PlatformVerificationDimension.orientationChanges:
        return 'Orientation changes';
      case PlatformVerificationDimension.backgroundForegroundTransitions:
        return 'Background/foreground transitions';
      case PlatformVerificationDimension.highDpiDisplays:
        return 'High-DPI displays';
      case PlatformVerificationDimension.differentScreenSizes:
        return 'Different screen sizes';
    }
  }
}

/// Status of a platform verification check.
enum PlatformCheckStatus {
  verified,
  unsupported,
  failed;

  String get id => name;

  String get label {
    switch (this) {
      case PlatformCheckStatus.verified:
        return 'VERIFIED';
      case PlatformCheckStatus.unsupported:
        return 'UNSUPPORTED';
      case PlatformCheckStatus.failed:
        return 'FAILED';
    }
  }

  String get symbol => this == PlatformCheckStatus.verified
      ? '✓'
      : (this == PlatformCheckStatus.unsupported ? '○' : '✗');
}

/// Item representing an individual platform test verification.
class PlatformCheckItem {
  final TargetPlatformType platform;
  final PlatformVerificationDimension dimension;
  final PlatformCheckStatus status;
  final String verificationDetails;

  const PlatformCheckItem({
    required this.platform,
    required this.dimension,
    this.status = PlatformCheckStatus.verified,
    required this.verificationDetails,
  });

  Map<String, dynamic> toJson() => {
        'platform': platform.id,
        'dimension': dimension.id,
        'status': status.id,
        'verification_details': verificationDetails,
      };

  factory PlatformCheckItem.fromJson(Map<String, dynamic> json) {
    return PlatformCheckItem(
      platform: TargetPlatformType.values.firstWhere(
        (p) => p.id == json['platform'] || p.name == json['platform'],
        orElse: () => TargetPlatformType.windows,
      ),
      dimension: PlatformVerificationDimension.values.firstWhere(
        (d) => d.id == json['dimension'] || d.name == json['dimension'],
        orElse: () => PlatformVerificationDimension.initialization,
      ),
      status: PlatformCheckStatus.values.firstWhere(
        (s) => s.id == json['status'] || s.name == json['status'],
        orElse: () => PlatformCheckStatus.verified,
      ),
      verificationDetails: json['verification_details'] as String? ?? '',
    );
  }
}

/// Comprehensive Phase 11.4 Platform Verification Report.
class PlatformVerificationReport {
  final String reportId;
  final String targetVersion;
  final bool isAllPlatformsVerified;
  final int totalPlatformsAudited;
  final int totalChecksRun;
  final List<PlatformCheckItem> checkItems;
  final DateTime verifiedAt;

  const PlatformVerificationReport({
    required this.reportId,
    required this.targetVersion,
    required this.isAllPlatformsVerified,
    required this.totalPlatformsAudited,
    required this.totalChecksRun,
    required this.checkItems,
    required this.verifiedAt,
  });

  Map<String, dynamic> toJson() => {
        'report_id': reportId,
        'target_version': targetVersion,
        'is_all_platforms_verified': isAllPlatformsVerified,
        'total_platforms_audited': totalPlatformsAudited,
        'total_checks_run': totalChecksRun,
        'check_items': checkItems.map((i) => i.toJson()).toList(),
        'verified_at': verifiedAt.toIso8601String(),
      };

  factory PlatformVerificationReport.fromJson(Map<String, dynamic> json) {
    return PlatformVerificationReport(
      reportId: json['report_id'] as String? ?? 'platform_report_default',
      targetVersion: json['target_version'] as String? ?? '1.0.0',
      isAllPlatformsVerified:
          json['is_all_platforms_verified'] as bool? ?? true,
      totalPlatformsAudited: json['total_platforms_audited'] as int? ?? 0,
      totalChecksRun: json['total_checks_run'] as int? ?? 0,
      checkItems: (json['check_items'] as List<dynamic>?)
              ?.map(
                  (i) => PlatformCheckItem.fromJson(i as Map<String, dynamic>))
              .toList() ??
          const [],
      verifiedAt: DateTime.parse(json['verified_at'] as String),
    );
  }
}
