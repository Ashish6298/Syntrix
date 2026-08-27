/// Single item representation in the historical release list.

class ReleaseHistoryItem {
  final String version;
  final String timestamp;
  final bool isSuccess;
  final String statusDetails;
  final bool isRollbackAvailable;
  final bool manualInterventionRequired;

  const ReleaseHistoryItem({
    required this.version,
    required this.timestamp,
    required this.isSuccess,
    required this.statusDetails,
    required this.isRollbackAvailable,
    required this.manualInterventionRequired,
  });

  Map<String, dynamic> toJson() => {
        'version': version,
        'timestamp': timestamp,
        'isSuccess': isSuccess,
        'statusDetails': statusDetails,
        'isRollbackAvailable': isRollbackAvailable,
        'manualInterventionRequired': manualInterventionRequired,
      };
}

/// Chronological timeline event entry in the dashboard.
class ReleaseTimelineEntry {
  final String timestamp;
  final String eventType;
  final String description;
  final String version;

  const ReleaseTimelineEntry({
    required this.timestamp,
    required this.eventType,
    required this.description,
    required this.version,
  });

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp,
        'eventType': eventType,
        'description': description,
        'version': version,
      };
}

/// Read-only snapshot of the complete release lifecycle.
class DashboardSnapshot {
  final String packageName;
  final String currentVersion;
  final String nextRelease;
  final String channel;
  final String certificationStatus;
  final String securityStatus;
  final String testStatus;
  final String artifactStatus;
  final String manifestStatus;
  final String gitTagStatus;
  final String gitHubReleaseStatus;
  final String publishingStatus;

  final List<ReleaseHistoryItem> history;
  final List<ReleaseHistoryItem> failedReleases;
  final List<ReleaseTimelineEntry> timeline;

  const DashboardSnapshot({
    required this.packageName,
    required this.currentVersion,
    required this.nextRelease,
    required this.channel,
    required this.certificationStatus,
    required this.securityStatus,
    required this.testStatus,
    required this.artifactStatus,
    required this.manifestStatus,
    required this.gitTagStatus,
    required this.gitHubReleaseStatus,
    required this.publishingStatus,
    required this.history,
    required this.failedReleases,
    required this.timeline,
  });

  String toFormattedText() {
    final buf = StringBuffer();
    buf.writeln('RELEASE DASHBOARD');
    buf.writeln('=================');
    buf.writeln('Package       : $packageName');
    buf.writeln('Current Version: $currentVersion');
    buf.writeln('Next Release  : $nextRelease');
    buf.writeln('Channel       : $channel');
    buf.writeln('Certification : $certificationStatus');
    buf.writeln('Security      : $securityStatus');
    buf.writeln('Tests         : $testStatus');
    buf.writeln('Artifacts     : $artifactStatus');
    buf.writeln('Manifest      : $manifestStatus');
    buf.writeln('Git Tag       : $gitTagStatus');
    buf.writeln('GitHub Release: $gitHubReleaseStatus');
    buf.writeln('Publishing    : $publishingStatus');
    buf.writeln();

    if (history.isNotEmpty) {
      buf.writeln('### RELEASE HISTORY');
      for (final item in history) {
        final statusSymbol = item.isSuccess ? '✓' : '✗';
        buf.writeln(
            '- [$statusSymbol] v${item.version} (${item.timestamp}): ${item.statusDetails}');
      }
      buf.writeln();
    }

    if (failedReleases.isNotEmpty) {
      buf.writeln('### FAILED / INTERRUPTED RELEASES');
      for (final item in failedReleases) {
        buf.writeln(
            '- [FAILED] v${item.version} (${item.timestamp}): ${item.statusDetails}');
      }
      buf.writeln();
    }

    if (timeline.isNotEmpty) {
      buf.writeln('### RELEASE TIMELINE');
      for (final entry in timeline) {
        buf.writeln(
            '[${entry.timestamp}] (${entry.version}) ${entry.eventType}: ${entry.description}');
      }
    }

    return buf.toString();
  }

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'currentVersion': currentVersion,
        'nextRelease': nextRelease,
        'channel': channel,
        'certificationStatus': certificationStatus,
        'securityStatus': securityStatus,
        'testStatus': testStatus,
        'artifactStatus': artifactStatus,
        'manifestStatus': manifestStatus,
        'gitTagStatus': gitTagStatus,
        'gitHubReleaseStatus': gitHubReleaseStatus,
        'publishingStatus': publishingStatus,
        'history': history.map((h) => h.toJson()).toList(),
        'failedReleases': failedReleases.map((f) => f.toJson()).toList(),
        'timeline': timeline.map((t) => t.toJson()).toList(),
      };
}
