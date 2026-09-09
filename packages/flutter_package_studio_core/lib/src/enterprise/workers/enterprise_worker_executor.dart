/// Worker executor abstraction and built-in local/mock worker implementations.
library;

import 'dart:async';
import 'package:flutter_package_studio_core/src/enterprise/workers/enterprise_worker_models.dart';

/// Abstract Controlled Worker Process/Machine Executor.
abstract class ControlledWorkerExecutor {
  ControlledWorkerInfo get workerInfo;

  /// Executes a task in isolation.
  Future<WorkerExecutionResult> executeTask(WorkerExecutionRequest request);

  /// Cancels an in-flight task execution.
  Future<bool> cancelTask(String taskId);
}

/// In-Process / Mock Controlled Worker for local workflows and testing.
class LocalControlledWorker implements ControlledWorkerExecutor {
  @override
  ControlledWorkerInfo workerInfo;

  final Map<String, Completer<WorkerExecutionResult>> _activeJobs = {};

  LocalControlledWorker({
    required String workerId,
    required String displayName,
    List<WorkerCapability>? capabilities,
    WorkerResourceLimits? capacity,
  }) : workerInfo = ControlledWorkerInfo(
          workerId: workerId,
          displayName: displayName,
          capabilities: capabilities ??
              const [
                WorkerCapability.buildArtifacts,
                WorkerCapability.runTestSuite,
                WorkerCapability.runSecurityAudit,
                WorkerCapability.aiAnalysis,
                WorkerCapability.packagePublishing,
                WorkerCapability.codeFormatting,
                WorkerCapability.analyzerCheck,
              ],
          capacity: capacity ?? const WorkerResourceLimits(),
          healthStatus: WorkerHealthStatus.healthy,
          registeredAt: DateTime.now(),
          lastHeartbeat: DateTime.now(),
        );

  @override
  Future<WorkerExecutionResult> executeTask(
      WorkerExecutionRequest request) async {
    final sw = Stopwatch()..start();
    final startedAt = DateTime.now();

    // Check capability
    if (!workerInfo.capabilities.contains(request.requiredCapability)) {
      sw.stop();
      return WorkerExecutionResult(
        taskId: request.taskId,
        workerId: workerInfo.workerId,
        status: WorkerExecutionStatus.failed,
        exitCode: 1,
        errorMessage:
            'Worker "${workerInfo.workerId}" does not support capability "${request.requiredCapability.id}".',
        durationMs: sw.elapsedMilliseconds,
        startedAt: startedAt,
        completedAt: DateTime.now(),
      );
    }

    final completer = Completer<WorkerExecutionResult>();
    _activeJobs[request.taskId] = completer;

    // Simulate task execution respecting timeout
    Timer? timeoutTimer;
    if (request.limits.timeout.inMilliseconds > 0) {
      timeoutTimer = Timer(request.limits.timeout, () {
        if (!completer.isCompleted) {
          sw.stop();
          completer.complete(
            WorkerExecutionResult(
              taskId: request.taskId,
              workerId: workerInfo.workerId,
              status: WorkerExecutionStatus.timedOut,
              exitCode: 124,
              errorMessage:
                  'Task timed out after ${request.limits.timeout.inSeconds}s.',
              durationMs: sw.elapsedMilliseconds,
              startedAt: startedAt,
              completedAt: DateTime.now(),
            ),
          );
        }
      });
    }

    // Complete standard execution if not already cancelled or timed out
    scheduleMicrotask(() {
      if (!completer.isCompleted) {
        timeoutTimer?.cancel();
        sw.stop();
        completer.complete(
          WorkerExecutionResult(
            taskId: request.taskId,
            workerId: workerInfo.workerId,
            status: WorkerExecutionStatus.completed,
            exitCode: 0,
            stdoutLog:
                'Task "${request.taskType}" executed successfully in worker isolation.',
            outputData: {
              'executed_by': workerInfo.workerId,
              'task_type': request.taskType,
              'processed': true,
            },
            durationMs: sw.elapsedMilliseconds,
            startedAt: startedAt,
            completedAt: DateTime.now(),
          ),
        );
      }
    });

    final result = await completer.future;
    _activeJobs.remove(request.taskId);
    return result;
  }

  @override
  Future<bool> cancelTask(String taskId) async {
    final completer = _activeJobs[taskId];
    if (completer != null && !completer.isCompleted) {
      completer.complete(
        WorkerExecutionResult(
          taskId: taskId,
          workerId: workerInfo.workerId,
          status: WorkerExecutionStatus.cancelled,
          exitCode: 130,
          errorMessage: 'Task was cancelled by user request.',
          durationMs: 0,
          startedAt: DateTime.now(),
          completedAt: DateTime.now(),
        ),
      );
      _activeJobs.remove(taskId);
      return true;
    }
    return false;
  }
}
