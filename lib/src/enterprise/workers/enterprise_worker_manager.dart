/// Central Enterprise Worker Pool & Execution Manager for Phase 9.10.
library;

import 'package:path/path.dart' as p;
import 'package:syntrix/src/logging/logger.dart';
import 'package:syntrix/src/enterprise/workers/enterprise_worker_models.dart';
import 'package:syntrix/src/enterprise/workers/enterprise_worker_executor.dart';

/// Central Enterprise Worker Pool & Execution Manager.
///
/// Features:
/// 1. Registers and maintains worker instances with health status and resource limits.
/// 2. Schedules and dispatches execution requests based on capability requirements.
/// 3. Handles job cancellation, timeouts, and isolation boundaries.
/// 4. Collects structured execution results and logs.
class EnterpriseWorkerManager {
  final Logger _logger = Logger('EnterpriseWorkerManager');
  final String _projectRoot;
  final Map<String, ControlledWorkerExecutor> _workers = {};
  final List<WorkerExecutionResult> _executionHistory = [];

  String get projectRoot => _projectRoot;
  List<ControlledWorkerInfo> get registeredWorkers =>
      _workers.values.map((w) => w.workerInfo).toList();
  List<WorkerExecutionResult> get executionHistory =>
      List.unmodifiable(_executionHistory);

  EnterpriseWorkerManager({
    required String projectRoot,
    List<ControlledWorkerExecutor>? initialWorkers,
  }) : _projectRoot = p.normalize(projectRoot) {
    if (initialWorkers != null && initialWorkers.isNotEmpty) {
      for (final w in initialWorkers) {
        registerWorker(w);
      }
    } else {
      // Default local worker
      registerWorker(
        LocalControlledWorker(
          workerId: 'worker_local_01',
          displayName: 'Default Local Worker',
        ),
      );
    }
  }

  /// Registers a controlled worker executor into the pool.
  void registerWorker(ControlledWorkerExecutor worker) {
    _workers[worker.workerInfo.workerId] = worker;
    _logger.info(
        'Registered controlled worker: ${worker.workerInfo.workerId} (${worker.workerInfo.displayName})');
  }

  /// Dispatches an execution request to an available worker supporting the required capability.
  Future<WorkerExecutionResult> dispatchExecution(
      WorkerExecutionRequest request) async {
    _logger.info(
        'Dispatching task "${request.taskType}" (${request.taskId}) requiring capability: ${request.requiredCapability.id}');

    // Find suitable healthy worker
    final candidate = _workers.values.firstWhere(
      (w) =>
          w.workerInfo.healthStatus == WorkerHealthStatus.healthy &&
          w.workerInfo.capabilities.contains(request.requiredCapability),
      orElse: () => throw StateError(
        'No available healthy worker found supporting capability "${request.requiredCapability.id}".',
      ),
    );

    final result = await candidate.executeTask(request);
    _executionHistory.add(result);

    _logger.info(
        'Task "${request.taskId}" completed on worker "${candidate.workerInfo.workerId}" with status: ${result.status.label}');
    return result;
  }

  /// Cancels an active task across registered workers.
  Future<bool> cancelTask(String taskId) async {
    for (final worker in _workers.values) {
      final cancelled = await worker.cancelTask(taskId);
      if (cancelled) {
        _logger.info(
            'Cancelled task "$taskId" on worker "${worker.workerInfo.workerId}".');
        return true;
      }
    }
    return false;
  }
}
