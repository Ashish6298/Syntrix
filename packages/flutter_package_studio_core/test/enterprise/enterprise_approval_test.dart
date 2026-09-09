import 'dart:io';
import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('Phase 9.5 — Approval & Release Governance Tests', () {
    late Directory tempDir;
    late String rootPath;

    setUp(() {
      tempDir =
          Directory.systemTemp.createTempSync('fps_enterprise_approval_test_');
      rootPath = tempDir.path;

      // Scaffold project workspace
      File(p.join(rootPath, 'pubspec.yaml')).writeAsStringSync('''
name: approval_sample_pkg
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

    const devIdentity = EnterpriseIdentity(
      id: 'usr_dev_1',
      displayName: 'Alice Developer',
      roles: [EnterpriseRole.developer],
    );

    const reviewerIdentity = EnterpriseIdentity(
      id: 'usr_rev_1',
      displayName: 'Bob Reviewer',
      roles: [EnterpriseRole.reviewer],
    );

    const relManagerIdentity = EnterpriseIdentity(
      id: 'usr_rel_1',
      displayName: 'Charlie ReleaseManager',
      roles: [EnterpriseRole.releaseManager],
    );

    const adminIdentity = EnterpriseIdentity(
      id: 'usr_adm_1',
      displayName: 'Eve Administrator',
      roles: [EnterpriseRole.administrator],
    );

    // ─────────────────────────────────────────────────────────────────────────
    // Test 1: Full Approval Lifecycle (Create -> Reviewer Vote -> RM Vote -> Approved)
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '1. Approval Lifecycle: Developer creates request, Reviewer & Release Manager approve',
        () async {
      final engine = EnterpriseApprovalEngine(projectRoot: rootPath);

      final req = await engine.createApprovalRequest(
        candidateName: 'approval_sample_pkg',
        candidateVersion: '1.0.0',
        requester: devIdentity,
        policy: const ApprovalPolicy(
          requiredReviewerApprovals: 1,
          requiredReleaseManagerApprovals: 1,
        ),
        satisfiedTechnicalGates: const [
          'security_audit',
          'release_verification',
          'pub_dev_validation',
        ],
      );

      expect(req.status, equals(ApprovalStatus.pending));

      // 1. Reviewer approves
      final afterReviewer = await engine.submitVote(
        requestId: req.requestId,
        voter: reviewerIdentity,
        action: ApprovalVoteAction.approve,
        comment: 'Code review looks clean and well tested.',
      );
      expect(afterReviewer.status, equals(ApprovalStatus.pending));
      expect(afterReviewer.reviewerApprovalCount, equals(1));

      // 2. Release Manager approves
      final afterRM = await engine.submitVote(
        requestId: req.requestId,
        voter: relManagerIdentity,
        action: ApprovalVoteAction.approve,
        comment: 'Release verification passed. Ready for publishing.',
      );
      expect(afterRM.status, equals(ApprovalStatus.approved));
      expect(afterRM.releaseManagerApprovalCount, equals(1));

      // 3. Technical Verification + Human Approval Gate
      expect(engine.isReleaseAuthorized(requestId: req.requestId), isTrue);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 2: Rejection Flow
    // ─────────────────────────────────────────────────────────────────────────

    test('2. Rejection Flow: single rejection terminates request as REJECTED',
        () async {
      final engine = EnterpriseApprovalEngine(projectRoot: rootPath);

      final req = await engine.createApprovalRequest(
        candidateName: 'approval_sample_pkg',
        candidateVersion: '1.0.0',
        requester: devIdentity,
      );

      final rejected = await engine.submitVote(
        requestId: req.requestId,
        voter: reviewerIdentity,
        action: ApprovalVoteAction.reject,
        comment: 'Breaking changes in public API without semver major bump.',
      );

      expect(rejected.status, equals(ApprovalStatus.rejected));
      expect(engine.isReleaseAuthorized(requestId: req.requestId), isFalse);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 3: Request Cancellation Flow
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '3. Cancellation Flow: requester or manager can cancel pending request',
        () async {
      final engine = EnterpriseApprovalEngine(projectRoot: rootPath);

      final req = await engine.createApprovalRequest(
        candidateName: 'approval_sample_pkg',
        candidateVersion: '1.0.0',
        requester: devIdentity,
      );

      final cancelled = await engine.cancelRequest(
        requestId: req.requestId,
        actor: devIdentity,
        reason: 'Found a bug during manual smoke testing.',
      );

      expect(cancelled.status, equals(ApprovalStatus.cancelled));
      expect(cancelled.cancellationReason, contains('Found a bug'));
      expect(engine.isReleaseAuthorized(requestId: req.requestId), isFalse);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 4: Administrator Override Flow
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '4. Admin Override Flow: administrator can override pending approval with reason',
        () async {
      final engine = EnterpriseApprovalEngine(projectRoot: rootPath);

      final req = await engine.createApprovalRequest(
        candidateName: 'approval_sample_pkg',
        candidateVersion: '1.0.0',
        requester: devIdentity,
        satisfiedTechnicalGates: const [
          'security_audit',
          'release_verification',
          'pub_dev_validation',
        ],
      );

      final overridden = await engine.adminOverride(
        requestId: req.requestId,
        adminActor: adminIdentity,
        reason: 'Emergency security hotfix bypass per executive directive.',
      );

      expect(overridden.status, equals(ApprovalStatus.approved));
      expect(overridden.overrideReason, contains('Emergency security hotfix'));
      expect(engine.isReleaseAuthorized(requestId: req.requestId), isTrue);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 5: Separation of Technical Gates vs. Human Approval
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '5. Gate Separation: Approved human vote cannot bypass missing technical verification gates',
        () async {
      final engine = EnterpriseApprovalEngine(projectRoot: rootPath);

      // Missing security_audit technical verification gate
      final req = await engine.createApprovalRequest(
        candidateName: 'approval_sample_pkg',
        candidateVersion: '1.0.0',
        requester: devIdentity,
        satisfiedTechnicalGates: const [
          'release_verification',
          'pub_dev_validation',
        ],
      );

      // Both human reviewers approve
      await engine.submitVote(
        requestId: req.requestId,
        voter: reviewerIdentity,
        action: ApprovalVoteAction.approve,
      );
      await engine.submitVote(
        requestId: req.requestId,
        voter: relManagerIdentity,
        action: ApprovalVoteAction.approve,
      );

      // Human approval is granted (status == approved), BUT technical gate is missing -> publish NOT authorized
      expect(engine.isReleaseAuthorized(requestId: req.requestId), isFalse);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 6: Pure Approval Renderer Conformance
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '6. Renderer Conformance: generates deterministic JSON and Markdown approval reports',
        () async {
      final engine = EnterpriseApprovalEngine(projectRoot: rootPath);
      final req = await engine.createApprovalRequest(
        candidateName: 'approval_sample_pkg',
        candidateVersion: '1.0.0',
        requester: devIdentity,
        satisfiedTechnicalGates: const [
          'security_audit',
          'release_verification',
          'pub_dev_validation'
        ],
      );

      await engine.submitVote(
        requestId: req.requestId,
        voter: reviewerIdentity,
        action: ApprovalVoteAction.approve,
        comment: 'LGTM',
      );

      final updated = engine.allRequests.first;
      const renderer = EnterpriseApprovalRenderer();

      final json1 = renderer.renderJson(updated);
      final json2 = renderer.renderJson(updated);
      expect(json1, equals(json2));

      final md = renderer.renderMarkdown(updated);
      expect(md, contains('# Enterprise Release Approval Report'));
      expect(md, contains('**Target Candidate**: `approval_sample_pkg@1.0.0`'));
      expect(md, contains('Reviewer Approvals: 1 / 1'));
      expect(md, contains('LGTM'));
    });
  });
}
