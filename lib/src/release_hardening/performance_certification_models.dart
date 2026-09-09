/// Domain models and telemetry structures for Phase 11.5: Performance Certification.
library;

/// Hardware/Runtime profile configuration tier.
enum HardwareProfileTier {
  lowEnd,
  normal,
  highEnd;

  String get id => name;

  String get label {
    switch (this) {
      case HardwareProfileTier.lowEnd:
        return 'Low-End Configuration';
      case HardwareProfileTier.normal:
        return 'Normal Configuration';
      case HardwareProfileTier.highEnd:
        return 'High-End Configuration';
    }
  }
}

/// Certified performance telemetry metrics for a configuration tier.
class PerformanceProfileMetrics {
  final HardwareProfileTier tier;
  final double fps;
  final double frameTimeMs;
  final double cpuUsagePercentage;
  final double gpuWorkloadPercentage;
  final double memoryUsageMb;
  final double allocationRateMbPerSec;
  final double gcPressureEventsPerMin;
  final int particleCount;
  final double renderingCostMs;
  final int startupTimeMs;
  final bool isCertified;

  const PerformanceProfileMetrics({
    required this.tier,
    required this.fps,
    required this.frameTimeMs,
    required this.cpuUsagePercentage,
    required this.gpuWorkloadPercentage,
    required this.memoryUsageMb,
    required this.allocationRateMbPerSec,
    required this.gcPressureEventsPerMin,
    required this.particleCount,
    required this.renderingCostMs,
    required this.startupTimeMs,
    this.isCertified = true,
  });

  Map<String, dynamic> toJson() => {
        'tier': tier.id,
        'fps': fps,
        'frame_time_ms': frameTimeMs,
        'cpu_usage_percentage': cpuUsagePercentage,
        'gpu_workload_percentage': gpuWorkloadPercentage,
        'memory_usage_mb': memoryUsageMb,
        'allocation_rate_mb_per_sec': allocationRateMbPerSec,
        'gc_pressure_events_per_min': gcPressureEventsPerMin,
        'particle_count': particleCount,
        'rendering_cost_ms': renderingCostMs,
        'startup_time_ms': startupTimeMs,
        'is_certified': isCertified,
      };

  factory PerformanceProfileMetrics.fromJson(Map<String, dynamic> json) {
    return PerformanceProfileMetrics(
      tier: HardwareProfileTier.values.firstWhere(
        (t) => t.id == json['tier'] || t.name == json['tier'],
        orElse: () => HardwareProfileTier.normal,
      ),
      fps: (json['fps'] as num?)?.toDouble() ?? 60.0,
      frameTimeMs: (json['frame_time_ms'] as num?)?.toDouble() ?? 16.6,
      cpuUsagePercentage:
          (json['cpu_usage_percentage'] as num?)?.toDouble() ?? 0.0,
      gpuWorkloadPercentage:
          (json['gpu_workload_percentage'] as num?)?.toDouble() ?? 0.0,
      memoryUsageMb: (json['memory_usage_mb'] as num?)?.toDouble() ?? 0.0,
      allocationRateMbPerSec:
          (json['allocation_rate_mb_per_sec'] as num?)?.toDouble() ?? 0.0,
      gcPressureEventsPerMin:
          (json['gc_pressure_events_per_min'] as num?)?.toDouble() ?? 0.0,
      particleCount: json['particle_count'] as int? ?? 0,
      renderingCostMs: (json['rendering_cost_ms'] as num?)?.toDouble() ?? 0.0,
      startupTimeMs: json['startup_time_ms'] as int? ?? 0,
      isCertified: json['is_certified'] as bool? ?? true,
    );
  }
}

/// Comprehensive Phase 11.5 Performance Certification Report.
class PerformanceCertificationReport {
  final String reportId;
  final String targetVersion;
  final bool isOverallCertified;
  final List<PerformanceProfileMetrics> profiles;
  final DateTime certifiedAt;

  const PerformanceCertificationReport({
    required this.reportId,
    required this.targetVersion,
    required this.isOverallCertified,
    required this.profiles,
    required this.certifiedAt,
  });

  Map<String, dynamic> toJson() => {
        'report_id': reportId,
        'target_version': targetVersion,
        'is_overall_certified': isOverallCertified,
        'profiles': profiles.map((p) => p.toJson()).toList(),
        'certified_at': certifiedAt.toIso8601String(),
      };

  factory PerformanceCertificationReport.fromJson(Map<String, dynamic> json) {
    return PerformanceCertificationReport(
      reportId: json['report_id'] as String? ?? 'perf_cert_default',
      targetVersion: json['target_version'] as String? ?? '1.0.0',
      isOverallCertified: json['is_overall_certified'] as bool? ?? true,
      profiles: (json['profiles'] as List<dynamic>?)
              ?.map((p) =>
                  PerformanceProfileMetrics.fromJson(p as Map<String, dynamic>))
              .toList() ??
          const [],
      certifiedAt: DateTime.parse(json['certified_at'] as String),
    );
  }
}
