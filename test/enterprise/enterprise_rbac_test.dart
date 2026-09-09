import 'package:syntrix/flutter_package_studio_core.dart';
import 'package:test/test.dart';

void main() {
  group('Phase 9.3 — Role-Based Access Control (RBAC) Tests', () {
    final rbac = RbacEngine();

    // Helper identities
    const devIdentity = EnterpriseIdentity(
      id: 'usr_dev_01',
      displayName: 'Developer User',
      roles: [EnterpriseRole.developer],
    );

    const reviewerIdentity = EnterpriseIdentity(
      id: 'usr_rev_01',
      displayName: 'Reviewer User',
      roles: [EnterpriseRole.reviewer],
    );

    const releaseManagerIdentity = EnterpriseIdentity(
      id: 'usr_rel_01',
      displayName: 'Release Manager User',
      roles: [EnterpriseRole.releaseManager],
    );

    const adminIdentity = EnterpriseIdentity(
      id: 'usr_adm_01',
      displayName: 'Admin User',
      roles: [EnterpriseRole.administrator],
    );

    const auditorIdentity = EnterpriseIdentity(
      id: 'usr_aud_01',
      displayName: 'Security Auditor User',
      roles: [EnterpriseRole.securityAuditor],
    );

    // ─────────────────────────────────────────────────────────────────────────
    // Test 1: Milestone 9.3 Specification Matrix Conformance
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '1. Specification Matrix: verifies all operations across Developer, Reviewer, Release Manager, Admin',
        () {
      // 1. Inspect project (Dev: ✓, Rev: ✓, Rel: ✓, Admin: ✓)
      expect(
          rbac
              .authorize(const AuthorizationRequest(
                  identity: devIdentity,
                  operation: EnterpriseOperation.inspectProject))
              .isAllowed,
          isTrue);
      expect(
          rbac
              .authorize(const AuthorizationRequest(
                  identity: reviewerIdentity,
                  operation: EnterpriseOperation.inspectProject))
              .isAllowed,
          isTrue);
      expect(
          rbac
              .authorize(const AuthorizationRequest(
                  identity: releaseManagerIdentity,
                  operation: EnterpriseOperation.inspectProject))
              .isAllowed,
          isTrue);
      expect(
          rbac
              .authorize(const AuthorizationRequest(
                  identity: adminIdentity,
                  operation: EnterpriseOperation.inspectProject))
              .isAllowed,
          isTrue);

      // 2. Run AI review (Dev: ✓, Rev: ✓, Rel: ✓, Admin: ✓)
      expect(
          rbac
              .authorize(const AuthorizationRequest(
                  identity: devIdentity,
                  operation: EnterpriseOperation.runAiReview))
              .isAllowed,
          isTrue);
      expect(
          rbac
              .authorize(const AuthorizationRequest(
                  identity: reviewerIdentity,
                  operation: EnterpriseOperation.runAiReview))
              .isAllowed,
          isTrue);
      expect(
          rbac
              .authorize(const AuthorizationRequest(
                  identity: releaseManagerIdentity,
                  operation: EnterpriseOperation.runAiReview))
              .isAllowed,
          isTrue);
      expect(
          rbac
              .authorize(const AuthorizationRequest(
                  identity: adminIdentity,
                  operation: EnterpriseOperation.runAiReview))
              .isAllowed,
          isTrue);

      // 3. Modify package (Dev: ✓, Rev: ✓, Rel: ✓, Admin: ✓)
      expect(
          rbac
              .authorize(const AuthorizationRequest(
                  identity: devIdentity,
                  operation: EnterpriseOperation.modifyPackage))
              .isAllowed,
          isTrue);
      expect(
          rbac
              .authorize(const AuthorizationRequest(
                  identity: reviewerIdentity,
                  operation: EnterpriseOperation.modifyPackage))
              .isAllowed,
          isTrue);
      expect(
          rbac
              .authorize(const AuthorizationRequest(
                  identity: releaseManagerIdentity,
                  operation: EnterpriseOperation.modifyPackage))
              .isAllowed,
          isTrue);
      expect(
          rbac
              .authorize(const AuthorizationRequest(
                  identity: adminIdentity,
                  operation: EnterpriseOperation.modifyPackage))
              .isAllowed,
          isTrue);

      // 4. Create release (Dev: ❌, Rev: ❌, Rel: ✓, Admin: ✓)
      expect(
          rbac
              .authorize(const AuthorizationRequest(
                  identity: devIdentity,
                  operation: EnterpriseOperation.createRelease))
              .isAllowed,
          isFalse);
      expect(
          rbac
              .authorize(const AuthorizationRequest(
                  identity: reviewerIdentity,
                  operation: EnterpriseOperation.createRelease))
              .isAllowed,
          isFalse);
      expect(
          rbac
              .authorize(const AuthorizationRequest(
                  identity: releaseManagerIdentity,
                  operation: EnterpriseOperation.createRelease))
              .isAllowed,
          isTrue);
      expect(
          rbac
              .authorize(const AuthorizationRequest(
                  identity: adminIdentity,
                  operation: EnterpriseOperation.createRelease))
              .isAllowed,
          isTrue);

      // 5. Publish package (Dev: ❌, Rev: ❌, Rel: ✓, Admin: ✓)
      expect(
          rbac
              .authorize(const AuthorizationRequest(
                  identity: devIdentity,
                  operation: EnterpriseOperation.publishPackage))
              .isAllowed,
          isFalse);
      expect(
          rbac
              .authorize(const AuthorizationRequest(
                  identity: reviewerIdentity,
                  operation: EnterpriseOperation.publishPackage))
              .isAllowed,
          isFalse);
      expect(
          rbac
              .authorize(const AuthorizationRequest(
                  identity: releaseManagerIdentity,
                  operation: EnterpriseOperation.publishPackage))
              .isAllowed,
          isTrue);
      expect(
          rbac
              .authorize(const AuthorizationRequest(
                  identity: adminIdentity,
                  operation: EnterpriseOperation.publishPackage))
              .isAllowed,
          isTrue);

      // 6. Change enterprise policy (Dev: ❌, Rev: ❌, Rel: ❌, Admin: ✓)
      expect(
          rbac
              .authorize(const AuthorizationRequest(
                  identity: devIdentity,
                  operation: EnterpriseOperation.changeEnterprisePolicy))
              .isAllowed,
          isFalse);
      expect(
          rbac
              .authorize(const AuthorizationRequest(
                  identity: reviewerIdentity,
                  operation: EnterpriseOperation.changeEnterprisePolicy))
              .isAllowed,
          isFalse);
      expect(
          rbac
              .authorize(const AuthorizationRequest(
                  identity: releaseManagerIdentity,
                  operation: EnterpriseOperation.changeEnterprisePolicy))
              .isAllowed,
          isFalse);
      expect(
          rbac
              .authorize(const AuthorizationRequest(
                  identity: adminIdentity,
                  operation: EnterpriseOperation.changeEnterprisePolicy))
              .isAllowed,
          isTrue);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 2: Elevated Approval (✓*) for Security Gate Overrides
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '2. Elevated Approval (✓*): Release Manager requires elevated approval to override security gate',
        () {
      // 1. Without elevated approval -> requiresApproval (not directly allowed)
      final unapproved = rbac.authorize(
        const AuthorizationRequest(
          identity: releaseManagerIdentity,
          operation: EnterpriseOperation.overrideSecurityGate,
          hasElevatedApproval: false,
        ),
      );
      expect(unapproved.isAllowed, isFalse);
      expect(
          unapproved.decision, equals(AuthorizationDecision.requiresApproval));
      expect(unapproved.requiresAdditionalApproval, isTrue);

      // 2. With elevated approval -> Allowed
      final approved = rbac.authorize(
        const AuthorizationRequest(
          identity: releaseManagerIdentity,
          operation: EnterpriseOperation.overrideSecurityGate,
          hasElevatedApproval: true,
        ),
      );
      expect(approved.isAllowed, isTrue);
      expect(approved.decision, equals(AuthorizationDecision.allow));

      // 3. Developer / Reviewer cannot override even with flag (Deny)
      final devAttempt = rbac.authorize(
        const AuthorizationRequest(
          identity: devIdentity,
          operation: EnterpriseOperation.overrideSecurityGate,
          hasElevatedApproval: true,
        ),
      );
      expect(devAttempt.isAllowed, isFalse);
      expect(devAttempt.decision, equals(AuthorizationDecision.deny));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 3: Direct Permissions and Wildcard Superuser Grants
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '3. Permission Granularity: supports direct permissions and wildcard grants',
        () {
      const customIdentity = EnterpriseIdentity(
        id: 'usr_custom_99',
        displayName: 'Custom User',
        roles: [EnterpriseRole.readOnly],
        directPermissions: {'release:create'},
      );

      // Granted via direct permission even if role is readOnly
      final res = rbac.authorize(
        const AuthorizationRequest(
          identity: customIdentity,
          operation: EnterpriseOperation.createRelease,
        ),
      );
      expect(res.isAllowed, isTrue);
      expect(res.reason, contains('Granted by direct permission'));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 4: Security Auditor Capabilities
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '4. Security Auditor: can view audit logs and run AI review, but cannot modify or publish',
        () {
      expect(
          rbac
              .authorize(const AuthorizationRequest(
                  identity: auditorIdentity,
                  operation: EnterpriseOperation.viewAuditLogs))
              .isAllowed,
          isTrue);
      expect(
          rbac
              .authorize(const AuthorizationRequest(
                  identity: auditorIdentity,
                  operation: EnterpriseOperation.runAiReview))
              .isAllowed,
          isTrue);
      expect(
          rbac
              .authorize(const AuthorizationRequest(
                  identity: auditorIdentity,
                  operation: EnterpriseOperation.modifyPackage))
              .isAllowed,
          isFalse);
      expect(
          rbac
              .authorize(const AuthorizationRequest(
                  identity: auditorIdentity,
                  operation: EnterpriseOperation.publishPackage))
              .isAllowed,
          isFalse);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 5: Pure RBAC Renderer Conformance
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '5. Renderer Conformance: generates deterministic JSON and Markdown authorization reports',
        () {
      final res = rbac.authorize(
        const AuthorizationRequest(
          identity: releaseManagerIdentity,
          operation: EnterpriseOperation.publishPackage,
        ),
      );

      const renderer = RbacRenderer();
      final json1 = renderer.renderJson(res);
      final json2 = renderer.renderJson(res);
      expect(json1, equals(json2));

      final md = renderer.renderMarkdown(res);
      expect(md, contains('# Enterprise Authorization Decision Report'));
      expect(md, contains('**Decision**: ✅ ALLOW'));
      expect(md, contains('**Operation**: `publishPackage`'));
    });
  });
}
