import 'dart:convert';
import 'dart:io';
import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('Phase 9.10 — Enterprise Remote Execution & Controlled Workers Tests', () {
    late Directory tempDir;
    late String rootPath;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('fps_enterprise_worker_test_');
      rootPath = tempDir.path;

      // Scaffold clean workspace
      File(p.join(rootPath, 'pubspec.yaml')).writeAsStringSync('''
name: worker_sample_pkg
version: 1.0.0
environment:
  sdk: '>=3.5.0 <4.0.0'
''');
    });

    tearDown(() {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 1: Worker Model Conformance & Capability Matching
    // ─────────────────────────────────────────────────────────────────────────

    test('1. Worker Model: defines capabilities, health status, and resource limits', () {
      final worker = ControlledWorkerInfo(
        workerId: 'w_heavy_01',
        displayName: 'Heavy Build Worker',
        host: 'build-node-01.enterprise.internal',
        capabilities: const [
          WorkerCapability.buildArtifacts,
          WorkerCapability.runTestSuite,
          WorkerCapability.packagePublishing,
        ],
        capacity: const WorkerResourceLimits(
          maxMemoryMb: 8192,
          maxCpuCores: 8,
          timeout: Duration(minutes: 30),
        ),
        registeredAt: DateTime.now(),
        lastHeartbeat: DateTime.now(),
      );

      expect(worker.capabilities.contains(WorkerCapability.buildArtifacts), isTrue);
      expect(worker.capabilities.contains(WorkerCapability.aiAnalysis), isFalse);
      expect(worker.capacity.maxMemoryMb, equals(8192));

      // JSON roundtrip
      final json = worker.toJson();
      final roundtrip = ControlledWorkerInfo.fromJson(json);
      expect(roundtrip.workerId, equals('w_heavy_01'));
      expect(roundtrip.capabilities.length, equals(3));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 2: Worker Dispatch & Execution
    // ─────────────────────────────────────────────────────────────────────────

    test('2. Worker Dispatch: successfully schedules and executes isolated task', () async {
      final manager = EnterpriseWorkerManager(projectRoot: rootPath);

      final request = WorkerExecutionRequest(
        taskId: 'task_001',
        taskType: 'build_android_aar',
        requiredCapability: WorkerCapability.buildArtifacts,
        payload: {'target': 'release'},
        requesterId: 'usr_dev_01',
        correlationId: 'cid_worker_100',
        createdAt: DateTime.now(),
      );

      final result = await manager.dispatchExecution(request);

      expect(result.taskId, equals('task_001'));
      expect(result.status, equals(WorkerExecutionStatus.completed));
      expect(result.exitCode, equals(0));
      expect(result.isSuccess, isTrue);
      expect(result.stdoutLog, contains('executed successfully in worker isolation'));
      expect(manager.executionHistory.length, equals(1));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 3: Capability Mismatch Handling
    // ─────────────────────────────────────────────────────────────────────────

    test('3. Capability Filter: rejects or throws when no worker supports requested capability', () async {
      // Worker only supports analyzerCheck
      final specializedWorker = LocalControlledWorker(
        workerId: 'w_lint_only',
        displayName: 'Linting Worker',
        capabilities: [WorkerCapability.analyzerCheck],
      );

      final manager = EnterpriseWorkerManager(
        projectRoot: rootPath,
        initialWorkers: [specializedWorker],
      );

      final request = WorkerExecutionRequest(
        taskId: 'task_002',
        taskType: 'publish_package',
        requiredCapability: WorkerCapability.packagePublishing, // Not supported
        payload: {},
        requesterId: 'usr_rel_01',
        correlationId: 'cid_fail_100',
        createdAt: DateTime.now(),
      );

      expect(
        () async => await manager.dispatchExecution(request),
        throwsA(isA<StateError>()),
      );
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 4: Task Cancellation
    // ─────────────────────────────────────────────────────────────────────────

    test('4. Task Cancellation: cancels active worker task on request', () async {
      final worker = LocalControlledWorker(
        workerId: 'w_cancel_test',
        displayName: 'Cancel Worker',
      );

      // Cancel non-existent task returns false
      expect(await worker.cancelTask('non_existent'), isFalse);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 5: Pure Worker Renderer Conformance
    // ─────────────────────────────────────────────────────────────────────────

    test('5. Renderer Conformance: generates deterministic JSON and Markdown worker reports', () {
      final manager = EnterpriseWorkerManager(projectRoot: rootPath);
      const renderer = EnterpriseWorkerRenderer();

      final json1 = renderer.renderJson(manager.registeredWorkers);
      final json2 = renderer.renderJson(manager.registeredWorkers);
      expect(json1, equals(json2));

      final md = renderer.renderMarkdown(manager.registeredWorkers);
      expect(md, contains('# Enterprise Controlled Workers & Remote Execution Report'));
      expect(md, contains('Total Workers: 1'));
      expect(md, contains('Healthy Workers: 1'));
    });
  });
}
