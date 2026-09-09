import 'dart:io';
import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('Phase 9.8 — Multi-Project & Organization Management Tests', () {
    late Directory tempDir;
    late String rootPath;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('fps_enterprise_org_test_');
      rootPath = tempDir.path;

      // Scaffold workspace
      File(p.join(rootPath, 'pubspec.yaml')).writeAsStringSync('''
name: org_sample_pkg
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
    // Test 1: Full Hierarchy Construction (Org -> Teams -> Projects -> Packages)
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '1. Hierarchy Model: constructs and serializes 4-tier organization tree',
        () {
      final org = EnterpriseOrganization(
        organizationId: 'acme_corp',
        name: 'Acme Global Corp',
        domain: 'acme.com',
        defaultPolicy: EnterprisePolicyDocument.fromProfile(
            EnterprisePolicyProfile.strict),
        teams: [
          EnterpriseTeam(
            teamId: 'team_fintech',
            name: 'FinTech Mobile Team',
            organizationId: 'acme_corp',
            leadUserId: 'usr_lead_01',
            members: [
              OrganizationMember(
                userId: 'usr_dev_01',
                displayName: 'Alice Dev',
                role: EnterpriseRole.developer,
                joinedAt: DateTime.now(),
              ),
            ],
            projectIds: ['prj_wallet_sdk', 'prj_checkout_ui'],
            createdAt: DateTime.now(),
          ),
          EnterpriseTeam(
            teamId: 'team_platform',
            name: 'Core Platform Team',
            organizationId: 'acme_corp',
            leadUserId: 'usr_lead_02',
            projectIds: ['prj_networking', 'prj_storage'],
            createdAt: DateTime.now(),
          ),
        ],
        sharedPackages: const [
          ManagedPackage(
            packageId: 'pkg_acme_design_system',
            name: 'acme_design_system',
            relativePath: 'packages/acme_design_system',
            currentVersion: '2.1.0',
            ownerTeamId: 'team_platform',
          ),
        ],
        createdAt: DateTime.now(),
      );

      expect(org.teams.length, equals(2));
      expect(org.sharedPackages.length, equals(1));
      expect(org.teams.first.members.length, equals(1));

      // JSON roundtrip
      final json = org.toJson();
      final roundtrip = EnterpriseOrganization.fromJson(json);
      expect(roundtrip.organizationId, equals('acme_corp'));
      expect(roundtrip.teams.length, equals(2));
      expect(roundtrip.sharedPackages.first.name, equals('acme_design_system'));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 2: Deterministic Policy Inheritance & Override Cascade
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '2. Policy Inheritance: Org Defaults -> Team Policy -> Project Overrides -> Package Overrides',
        () {
      final engine = EnterpriseOrganizationEngine(
        projectRoot: rootPath,
        initialOrganization: EnterpriseOrganization(
          organizationId: 'acme_corp',
          name: 'Acme Global Corp',
          defaultPolicy: const EnterprisePolicyDocument(
            profile: EnterprisePolicyProfile.standard,
            enforcementMode: PolicyEnforcementMode.strict,
            releasePolicy: ReleasePolicyConfig(requireGitTag: true),
          ),
          teams: [
            EnterpriseTeam(
              teamId: 'team_fintech',
              name: 'FinTech Team',
              organizationId: 'acme_corp',
              leadUserId: 'lead_1',
              teamPolicyOverride: const EnterprisePolicyDocument(
                profile: EnterprisePolicyProfile.financial,
                securityPolicy:
                    SecurityPolicyConfig(maxAllowedCriticalFindings: 0),
              ),
              createdAt: DateTime.now(),
            ),
          ],
          createdAt: DateTime.now(),
        ),
      );

      // 1. Resolve for Organization level default
      final orgEffective = engine.resolveEffectivePolicy();
      expect(orgEffective.profile, equals(EnterprisePolicyProfile.standard));

      // 2. Resolve for Team level (Financial profile cascade)
      final teamEffective =
          engine.resolveEffectivePolicy(teamId: 'team_fintech');
      expect(teamEffective.profile, equals(EnterprisePolicyProfile.financial));
      expect(teamEffective.releasePolicy.requireGitTag,
          isTrue); // Inherited from Org

      // 3. Resolve for Project level with project-specific override
      final projectWithOverride = ManagedProject(
        projectId: 'prj_instant_pay',
        name: 'Instant Pay',
        teamId: 'team_fintech',
        organizationId: 'acme_corp',
        projectRootPath: 'projects/instant_pay',
        projectPolicyOverride: const EnterprisePolicyDocument(
          customMetadata: {'compliance_tier': 'tier_1'},
        ),
        createdAt: DateTime.now(),
      );

      final projectEffective = engine.resolveEffectivePolicy(
        teamId: 'team_fintech',
        project: projectWithOverride,
      );
      expect(
          projectEffective.profile, equals(EnterprisePolicyProfile.financial));
      expect(
          projectEffective.customMetadata['compliance_tier'], equals('tier_1'));

      // 4. Resolve for Package level with package override
      const packageWithOverride = ManagedPackage(
        packageId: 'pkg_core',
        name: 'instant_pay_core',
        relativePath: 'packages/instant_pay_core',
        ownerTeamId: 'team_fintech',
        packagePolicyOverride: EnterprisePolicyDocument(
          profile: EnterprisePolicyProfile.strict,
        ),
      );

      final packageEffective = engine.resolveEffectivePolicy(
        teamId: 'team_fintech',
        project: projectWithOverride,
        package: packageWithOverride,
      );
      expect(packageEffective.profile, equals(EnterprisePolicyProfile.strict));
      expect(
          packageEffective.customMetadata['compliance_tier'], equals('tier_1'));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 3: Persistent Organization Manifest Storage
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '3. Persistence: saves and loads organization manifest from .fps/organization/',
        () {
      final engine = EnterpriseOrganizationEngine(projectRoot: rootPath);

      engine.registerTeam(
        EnterpriseTeam(
          teamId: 'team_ai',
          name: 'AI Engineering Team',
          organizationId: 'default_org',
          leadUserId: 'lead_ai_01',
          createdAt: DateTime.now(),
        ),
      );

      engine.registerSharedPackage(
        const ManagedPackage(
          packageId: 'pkg_shared_ai',
          name: 'shared_ai_kernel',
          relativePath: 'packages/shared_ai_kernel',
          ownerTeamId: 'team_ai',
        ),
      );

      final manifestFile = File(p.join(
          rootPath, '.fps', 'organization', 'organization_manifest.json'));
      expect(manifestFile.existsSync(), isTrue);

      // Reload into new engine instance
      final engine2 = EnterpriseOrganizationEngine(projectRoot: rootPath);
      expect(
          engine2.organization.teams.any((t) => t.teamId == 'team_ai'), isTrue);
      expect(
          engine2.organization.sharedPackages
              .any((p) => p.packageId == 'pkg_shared_ai'),
          isTrue);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 4: Pure Organization Renderer Conformance
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '4. Renderer Conformance: generates deterministic JSON and Markdown organization reports',
        () {
      final engine = EnterpriseOrganizationEngine(projectRoot: rootPath);
      const renderer = EnterpriseOrganizationRenderer();

      final json1 = renderer.renderJson(engine.organization);
      final json2 = renderer.renderJson(engine.organization);
      expect(json1, equals(json2));

      final md = renderer.renderMarkdown(engine.organization);
      expect(md, contains('# Enterprise Organization Hierarchy Report'));
      expect(md, contains('**Organization Name**: `Enterprise Organization`'));
      expect(md, contains('## Executive Summary'));
    });
  });
}
