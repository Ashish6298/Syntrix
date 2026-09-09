/// Domain models and platform profiles for Phase 10.16: Cross-Platform Environment Center.
library;

/// Supported target platforms.
enum StudioPlatformType {
  android,
  ios,
  web,
  windows,
  macos,
  linux;

  String get id => name;

  String get label {
    switch (this) {
      case StudioPlatformType.android:
        return 'Android';
      case StudioPlatformType.ios:
        return 'iOS';
      case StudioPlatformType.web:
        return 'Web';
      case StudioPlatformType.windows:
        return 'Windows';
      case StudioPlatformType.macos:
        return 'macOS';
      case StudioPlatformType.linux:
        return 'Linux';
    }
  }
}

/// Verification status for a platform capability or support level.
enum PlatformCapabilityStatus {
  verified,
  partial,
  unavailable,
  unsupported;

  String get id => name;

  String get symbol {
    switch (this) {
      case PlatformCapabilityStatus.verified:
        return '✓';
      case PlatformCapabilityStatus.partial:
        return '⚠';
      case PlatformCapabilityStatus.unavailable:
        return '?';
      case PlatformCapabilityStatus.unsupported:
        return '✗';
    }
  }
}

/// Detailed profile for a single target platform.
class StudioPlatformProfile {
  final StudioPlatformType platform;
  final PlatformCapabilityStatus supportStatus;
  final String? rendererBackend; // e.g. Impeller, Skia, CanvasKit, HTML/WebGL
  final bool shadersSupported;
  final bool diagnosticsSupported;
  final List<String> supportedFeatures;
  final List<String> knownLimitations;

  const StudioPlatformProfile({
    required this.platform,
    this.supportStatus = PlatformCapabilityStatus.verified,
    this.rendererBackend,
    this.shadersSupported = true,
    this.diagnosticsSupported = true,
    this.supportedFeatures = const [],
    this.knownLimitations = const [],
  });

  Map<String, dynamic> toJson() => {
        'platform': platform.id,
        'support_status': supportStatus.id,
        'renderer_backend': rendererBackend,
        'shaders_supported': shadersSupported,
        'diagnostics_supported': diagnosticsSupported,
        'supported_features': supportedFeatures,
        'known_limitations': knownLimitations,
      };

  factory StudioPlatformProfile.fromJson(Map<String, dynamic> json) {
    return StudioPlatformProfile(
      platform: StudioPlatformType.values.firstWhere(
        (p) => p.id == json['platform'] || p.name == json['platform'],
        orElse: () => StudioPlatformType.windows,
      ),
      supportStatus: PlatformCapabilityStatus.values.firstWhere(
        (s) =>
            s.id == json['support_status'] || s.name == json['support_status'],
        orElse: () => PlatformCapabilityStatus.verified,
      ),
      rendererBackend: json['renderer_backend'] as String?,
      shadersSupported: json['shaders_supported'] as bool? ?? true,
      diagnosticsSupported: json['diagnostics_supported'] as bool? ?? true,
      supportedFeatures: (json['supported_features'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      knownLimitations: (json['known_limitations'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }
}

/// Environment Center report aggregating all target platform statuses.
class StudioEnvironmentReport {
  final String reportId;
  final String activeHostPlatform;
  final List<StudioPlatformProfile> platformProfiles;
  final DateTime inspectedAt;

  const StudioEnvironmentReport({
    required this.reportId,
    required this.activeHostPlatform,
    required this.platformProfiles,
    required this.inspectedAt,
  });

  Map<String, dynamic> toJson() => {
        'report_id': reportId,
        'active_host_platform': activeHostPlatform,
        'platform_profiles': platformProfiles.map((p) => p.toJson()).toList(),
        'inspected_at': inspectedAt.toIso8601String(),
      };

  factory StudioEnvironmentReport.fromJson(Map<String, dynamic> json) {
    return StudioEnvironmentReport(
      reportId: json['report_id'] as String? ?? 'env_default',
      activeHostPlatform: json['active_host_platform'] as String? ?? 'Windows',
      platformProfiles: (json['platform_profiles'] as List<dynamic>?)
              ?.map((p) =>
                  StudioPlatformProfile.fromJson(p as Map<String, dynamic>))
              .toList() ??
          const [],
      inspectedAt: DateTime.parse(json['inspected_at'] as String),
    );
  }
}
