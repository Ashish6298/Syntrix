import 'package:syntrix/src/error/exceptions.dart';
import 'package:syntrix/src/logging/logger.dart';
import 'package:syntrix/src/release/assistant/publishing_assistant_models.dart';
import 'package:syntrix/src/release/assistant/release_publishing_assistant.dart';
import 'package:syntrix/src/release/dashboard/release_dashboard_models.dart';
import 'package:syntrix/src/release/dry_run/release_dry_run_models.dart';

/// Read-only aggregator service providing unified release lifecycle visibility without side-effects.
class ReleaseDashboard {
  final Logger _logger = Logger('ReleaseDashboard');
  final ReleasePublishingAssistant _assistant;

  ReleaseDashboard({ReleasePublishingAssistant? assistant})
      : _assistant = assistant ?? ReleasePublishingAssistant();

  /// Compiles a read-only [DashboardSnapshot] aggregating provided upstream structured records.
  DashboardSnapshot renderSnapshot({
    required String packageName,
    required String currentVersion,
    required String nextRelease,
    required String channel,
    ReleaseDryRunReport? dryRunReport,
    PublishingExecutionResult? latestExecution,
    List<PublishingExecutionResult>? priorExecutions,
  }) {
    _logger.info(
        'Rendering read-only release dashboard snapshot for "$packageName"');

    if (packageName.trim().isEmpty) {
      throw ReleaseDashboardException('Package name must not be empty.');
    }

    // Helper for stage status evaluation
    String getStageStatus(
        String stageName, Map<String, String>? fallbackEvidence) {
      if (latestExecution != null) {
        final match =
            latestExecution.stageRecords.where((s) => s.stageName == stageName);
        if (match.isNotEmpty) {
          final rec = match.first;
          if (rec.status == StageStatus.success) return '✓';
          if (rec.status == StageStatus.failed) return '✗';
          return 'PENDING';
        }
      }
      if (fallbackEvidence != null && fallbackEvidence.containsKey(stageName)) {
        final val = fallbackEvidence[stageName];
        if (val == 'PASSED' || val == 'VERIFIED' || val == 'CLEAN') return '✓';
        if (val == 'FAILED') return '✗';
      }
      return 'NOT TRACKED';
    }

    final certStatus = getStageStatus('Certification', null);
    final secStatus = getStageStatus('Security Audit', null);
    final testStatus = getStageStatus('Validate', null);
    final artStatus = getStageStatus('Build', null);
    final manifestStatus = getStageStatus('Manifest', null);
    final gitTagStatus = getStageStatus('Git Tag', null);
    final gitHubStatus = getStageStatus('GitHub Release', null);

    final pubStatus = dryRunReport != null
        ? (dryRunReport.isReady ? 'READY' : 'NOT READY')
        : (latestExecution != null
            ? (latestExecution.isSuccess ? 'READY' : 'NOT READY')
            : 'NOT TRACKED');

    // Aggregate History items
    final historyItems = <ReleaseHistoryItem>[];
    final failedItems = <ReleaseHistoryItem>[];
    final timelineEntries = <ReleaseTimelineEntry>[];

    final allExecutions = <PublishingExecutionResult>[];
    if (priorExecutions != null) allExecutions.addAll(priorExecutions);
    if (latestExecution != null && !allExecutions.contains(latestExecution)) {
      allExecutions.add(latestExecution);
    }

    for (final exec in allExecutions) {
      final isRollbackAvail = exec.stageRecords
          .any((s) => s.isRollbackable && s.status == StageStatus.success);
      final isManualReq = exec.rollbackLog
          .any((l) => l.contains('Manual intervention required'));

      final item = ReleaseHistoryItem(
        version: exec.targetVersion,
        timestamp: exec.stageRecords.isNotEmpty
            ? exec.stageRecords.first.timestamp
            : 'N/A',
        isSuccess: exec.isSuccess,
        statusDetails: exec.summary,
        isRollbackAvailable: isRollbackAvail,
        manualInterventionRequired: isManualReq,
      );

      historyItems.add(item);
      if (!exec.isSuccess) {
        failedItems.add(item);
      }

      for (final rec in exec.stageRecords) {
        timelineEntries.add(ReleaseTimelineEntry(
          timestamp: rec.timestamp,
          eventType: rec.stageName,
          description: rec.details,
          version: exec.targetVersion,
        ));
      }
    }

    // Sort timeline chronologically by timestamp
    timelineEntries.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return DashboardSnapshot(
      packageName: packageName,
      currentVersion: currentVersion,
      nextRelease: nextRelease,
      channel: channel,
      certificationStatus: certStatus,
      securityStatus: secStatus,
      testStatus: testStatus,
      artifactStatus: artStatus,
      manifestStatus: manifestStatus,
      gitTagStatus: gitTagStatus,
      gitHubReleaseStatus: gitHubStatus,
      publishingStatus: pubStatus,
      history: List.unmodifiable(historyItems),
      failedReleases: List.unmodifiable(failedItems),
      timeline: List.unmodifiable(timelineEntries),
    );
  }

  /// Thin pass-through delegating action to Phase 6.7 authorized execution path without hidden side-effects.
  Future<PublishingExecutionResult> delegateExecution(
    PublishingAssistantOptions options,
  ) async {
    _logger
        .info('Delegating release execution to Phase 6.7 Publishing Assistant');
    return _assistant.executePipeline(options);
  }
}
