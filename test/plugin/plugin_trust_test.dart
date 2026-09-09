import 'dart:io' as io;
import 'package:syntrix/flutter_package_studio_core.dart';
import 'package:test/test.dart';

void main() {
  group('Plugin Security & Trust Verification Tests (Phase 7.14)', () {
    late PluginContractValidator validator;
    late PluginPermissionGate permissionGate;
    late PluginDependencyResolver dependencyResolver;
    late PluginTrustGate trustGate;

    setUp(() {
      validator = PluginContractValidator();
      permissionGate = PluginPermissionGate();
      dependencyResolver = PluginDependencyResolver();
      trustGate = PluginTrustGate(
        contractValidator: validator,
        permissionGate: permissionGate,
        dependencyResolver: dependencyResolver,
      );
    });

    PluginManifest createSampleManifest({
      String id = 'sample_plugin',
      String authorName = 'FPS Core Team',
      String version = '1.0.0',
      List<String> permissions = const [],
      List<PluginDependency> dependencies = const [],
      ConfigurationSchema? configSchema,
      String? entryPoint,
    }) {
      return PluginManifest(
        id: PluginId(id),
        name: PluginName('Sample Plugin $id'),
        description: PluginDescription('Trust verification test plugin.'),
        version: SemVer.parse(version),
        author: PluginAuthor(name: authorName, email: 'author@example.com'),
        apiVersion: '1.0.0',
        capabilities: const {PluginCapability.commandContribution},
        compatibility: PluginCompatibility(minApiVersion: '1.0.0'),
        dependencies: dependencies,
        configSchema: configSchema ?? ConfigurationSchema(),
        securityRequirements: SecurityRequirements(permissions: permissions),
        entryPoint: entryPoint,
      );
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Test 1: Individually Named 5-Level Classification Tests
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '1a. Classification: TRUSTED result for verified author with zero risk signals',
        () {
      final manifest = createSampleManifest(
        id: 'official_plugin',
        authorName: 'FPS Core Team',
      );

      final result = trustGate.evaluateTrust(manifest: manifest);
      expect(result.trustLevel, equals(PluginTrustLevel.trusted));
      expect(result.isEligibleForActivation, isTrue);
      expect(result.canActivateDirectly, isTrue);
      expect(result.requiresOperatorAcknowledgment, isFalse);
    });

    test(
        '1b. Classification: VALIDATED result for clean unverified third-party plugin',
        () {
      final manifest = createSampleManifest(
        id: 'third_party_plugin',
        authorName: 'Community Developer',
      );

      final result = trustGate.evaluateTrust(manifest: manifest);
      expect(result.trustLevel, equals(PluginTrustLevel.validated));
      expect(result.isEligibleForActivation, isTrue);
      expect(result.canActivateDirectly, isTrue);
      expect(result.requiresOperatorAcknowledgment, isFalse);
    });

    test(
        '1c. Classification: RESTRICTED result for plugin with heuristic risk signals',
        () {
      final manifest = createSampleManifest(
        id: 'risky_plugin',
        authorName: 'Community Developer',
        permissions: ['process.execute', 'network.access'],
      );

      // Approve permissions so it's not hard-blocked by permission gate
      permissionGate.approvePermission(
          'risky_plugin', PluginPermission.processExecute);
      permissionGate.approvePermission(
          'risky_plugin', PluginPermission.networkAccess);

      final result = trustGate.evaluateTrust(manifest: manifest);
      expect(result.trustLevel, equals(PluginTrustLevel.restricted));
      expect(result.isEligibleForActivation, isTrue);
      expect(result.requiresOperatorAcknowledgment, isTrue);
      expect(result.canActivateDirectly, isFalse);
    });

    test(
        '1d. Classification: BLOCKED result for hard security failure (unapproved permission / integrity fail)',
        () {
      final manifest = createSampleManifest(
        id: 'blocked_plugin',
        permissions: ['process.execute'],
      );

      // Intentionally do NOT approve permission
      final result = trustGate.evaluateTrust(manifest: manifest);
      expect(result.trustLevel, equals(PluginTrustLevel.blocked));
      expect(result.isEligibleForActivation, isFalse);
      expect(result.isHardBlocked, isTrue);
    });

    test('1e. Classification: INVALID result for Phase 7.1 contract failure',
        () {
      // Manifest constructed with invalid raw JSON
      final invalidManifest = PluginManifest(
        id: PluginId('valid_id'),
        name: PluginName('Plugin'),
        description: PluginDescription('Desc'),
        version: SemVer.parse('1.0.0'),
        author: const PluginAuthor(name: 'Dev'),
        apiVersion: '99.0.0', // Unsupported API version
        capabilities: const {PluginCapability.commandContribution},
        compatibility: PluginCompatibility(minApiVersion: '99.0.0'),
      );

      final result = trustGate.evaluateTrust(manifest: invalidManifest);
      expect(result.trustLevel, equals(PluginTrustLevel.invalid));
      expect(result.isEligibleForActivation, isFalse);
      expect(result.isHardBlocked, isTrue);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 2: Reuse Verification & Provenance Discrimination Tests
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '2a. Reuse verification: verified-author plugin with unapproved permission transitions from BLOCKED to TRUSTED upon approval',
        () {
      final manifest = createSampleManifest(
        id: 'reuse_verified_plugin',
        authorName: 'FPS Core Team', // Verified provenance
        permissions: ['packageFiles.read'],
      );

      // 1. Unapproved permission is the SOLE blocking condition -> BLOCKED
      final unapprovedResult = trustGate.evaluateTrust(manifest: manifest);
      expect(unapprovedResult.trustLevel, equals(PluginTrustLevel.blocked));

      // 2. Once approved in real PluginPermissionGate, all criteria for TRUSTED are satisfied -> TRUSTED
      permissionGate.approvePermission(
          'reuse_verified_plugin', PluginPermission.packageFilesRead);
      final approvedResult = trustGate.evaluateTrust(manifest: manifest);
      expect(approvedResult.trustLevel, equals(PluginTrustLevel.trusted));
    });

    test(
        '2b. Reuse verification: unverified third-party plugin with unapproved permission transitions from BLOCKED to VALIDATED (not TRUSTED) upon approval',
        () {
      final manifest = createSampleManifest(
        id: 'reuse_unverified_plugin',
        authorName: 'Community Developer', // Unverified provenance
        permissions: ['packageFiles.read'],
      );

      // 1. Unapproved permission is the SOLE blocking condition -> BLOCKED
      final unapprovedResult = trustGate.evaluateTrust(manifest: manifest);
      expect(unapprovedResult.trustLevel, equals(PluginTrustLevel.blocked));

      // 2. Once approved, reaches VALIDATED (capped because provenance is unverified) -> VALIDATED (not TRUSTED)
      permissionGate.approvePermission(
          'reuse_unverified_plugin', PluginPermission.packageFilesRead);
      final approvedResult = trustGate.evaluateTrust(manifest: manifest);
      expect(approvedResult.trustLevel, equals(PluginTrustLevel.validated));
      expect(
          approvedResult.trustLevel, isNot(equals(PluginTrustLevel.trusted)));
    });

    test(
        '2c. Risk override protection: verified-author plugin with heuristic risk signal is capped at RESTRICTED (cannot reach TRUSTED)',
        () {
      final manifest = createSampleManifest(
        id: 'verified_with_risk_plugin',
        authorName: 'FPS Core Team', // Verified provenance
        permissions: [
          'process.execute',
          'network.access'
        ], // Dangerous combination
      );

      // Approve permissions so permission gate does not hard-block it
      permissionGate.approvePermission(
          'verified_with_risk_plugin', PluginPermission.processExecute);
      permissionGate.approvePermission(
          'verified_with_risk_plugin', PluginPermission.networkAccess);

      // Provenance alone must never override an active risk signal
      final result = trustGate.evaluateTrust(manifest: manifest);
      expect(result.trustLevel, equals(PluginTrustLevel.restricted));
      expect(result.trustLevel, isNot(equals(PluginTrustLevel.trusted)));
      expect(result.requiresOperatorAcknowledgment, isTrue);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 3: Genuinely New Check Tests
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '3a. New check: manifest cryptographic integrity failure triggers BLOCKED classification',
        () {
      final manifest = createSampleManifest(id: 'tampered_plugin');
      const rawContent = '{"id": "tampered_plugin", "name": "Modified"}';
      const expectedChecksum = 'incorrect_sha256_hash_value_12345';

      final result = trustGate.evaluateTrust(
        manifest: manifest,
        manifestRawContent: rawContent,
        expectedChecksum: expectedChecksum,
      );

      expect(result.trustLevel, equals(PluginTrustLevel.blocked));
      expect(
          result.findings.any((f) =>
              f.signalType == TrustSignalType.manifestIntegrity &&
              f.status == TrustSignalStatus.failed),
          isTrue);
    });

    test(
        '3b. New check: unsafe configuration combination triggers RESTRICTED risk signal',
        () {
      final schema = ConfigurationSchema(properties: const [
        ConfigurationProperty(
            key: 'shellCommand',
            type: ConfigPropertyType.string,
            isRequired: true),
      ]);

      final manifest = createSampleManifest(
        id: 'unsafe_config_plugin',
        configSchema: schema,
      );

      final result = trustGate.evaluateTrust(manifest: manifest);
      expect(result.trustLevel, equals(PluginTrustLevel.restricted));
      expect(
          result.findings.any((f) =>
              f.signalType == TrustSignalType.configurationSafety &&
              f.status == TrustSignalStatus.riskWarning),
          isTrue);
    });

    test(
        '3c. New check: non-executing suspicious resource inspection triggers risk signal without execution',
        () {
      final tempDir =
          io.Directory.systemTemp.createTempSync('suspicious_plugin_');
      io.File('${tempDir.path}/native_helper.dll')
          .writeAsStringSync('MZbinarypayload');

      final manifest = createSampleManifest(id: 'binary_plugin');

      final result = trustGate.evaluateTrust(
        manifest: manifest,
        pluginDirectoryPath: tempDir.path,
      );

      expect(result.trustLevel, equals(PluginTrustLevel.restricted));
      expect(
          result.findings.any((f) =>
              f.signalType == TrustSignalType.resourceSafety &&
              f.status == TrustSignalStatus.riskWarning),
          isTrue);

      tempDir.deleteSync(recursive: true);
    });

    test(
        '3d. New check: dependency trust propagation downgrades parent plugin trust',
        () {
      final manifest = createSampleManifest(
        id: 'parent_plugin',
        dependencies: [
          PluginDependency(name: 'untrusted_child', versionConstraint: '^1.0.0')
        ],
      );

      // 1. When child is restricted / unverified -> parent becomes RESTRICTED
      final resRestricted = trustGate.evaluateTrust(
        manifest: manifest,
        dependencyTrustMap: {'untrusted_child': PluginTrustLevel.restricted},
      );
      expect(resRestricted.trustLevel, equals(PluginTrustLevel.restricted));

      // 2. When child is blocked -> parent becomes BLOCKED
      final resBlocked = trustGate.evaluateTrust(
        manifest: manifest,
        dependencyTrustMap: {'untrusted_child': PluginTrustLevel.blocked},
      );
      expect(resBlocked.trustLevel, equals(PluginTrustLevel.blocked));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 4: No-Rescue Test
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '4. No-rescue test: upstream rejections (7.1, 7.6, 7.8) cannot be rescued to passing levels',
        () {
      final manifest = createSampleManifest(
        id: 'unrescuable_plugin',
        authorName: 'FPS Core Team', // Trusted author
        permissions: ['process.execute'], // Unapproved permission
      );

      // Even with verified author and zero config issues, unapproved permission forces BLOCKED
      final result = trustGate.evaluateTrust(manifest: manifest);
      expect(result.trustLevel, equals(PluginTrustLevel.blocked));
      expect(result.isEligibleForActivation, isFalse);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 5: Lifecycle Integration Tests
    // ─────────────────────────────────────────────────────────────────────────

    test('5a. Lifecycle integration: BLOCKED plugin cannot reach Active state',
        () async {
      final lifecycle = PluginLifecycleManager(
        validator: validator,
        permissionGate: permissionGate,
        trustGate: trustGate,
      );

      final manifest = createSampleManifest(
        id: 'lifecycle_blocked_plugin',
        permissions: ['process.execute'],
      );

      lifecycle.trackInstance(
          instanceId: 'lifecycle_blocked_plugin', manifest: manifest)
        ..state = PluginLifecycleState.initialized;

      final outcome = await lifecycle.transitionTo(
        instanceId: 'lifecycle_blocked_plugin',
        targetState: PluginLifecycleState.active,
      );

      expect(outcome, equals(PluginLifecycleState.blocked));
      expect(lifecycle.getInstance('lifecycle_blocked_plugin')!.state,
          equals(PluginLifecycleState.blocked));
    });

    test(
        '5b. Lifecycle integration: RESTRICTED plugin requires explicit operator acknowledgment',
        () async {
      final lifecycle = PluginLifecycleManager(
        validator: validator,
        permissionGate: permissionGate,
        trustGate: trustGate,
      );

      final manifest = createSampleManifest(
        id: 'lifecycle_restricted_plugin',
        permissions: ['process.execute', 'network.access'],
      );

      permissionGate.approvePermission(
          'lifecycle_restricted_plugin', PluginPermission.processExecute);
      permissionGate.approvePermission(
          'lifecycle_restricted_plugin', PluginPermission.networkAccess);

      lifecycle.trackInstance(
          instanceId: 'lifecycle_restricted_plugin', manifest: manifest)
        ..state = PluginLifecycleState.initialized;

      // 1. Transition to active without operator acknowledgment -> REFUSED & BLOCKED
      final rejected = await lifecycle.transitionTo(
        instanceId: 'lifecycle_restricted_plugin',
        targetState: PluginLifecycleState.active,
        context: {'operatorAcknowledged': false},
      );
      expect(rejected, equals(PluginLifecycleState.blocked));

      // Reset to initialized
      lifecycle.getInstance('lifecycle_restricted_plugin')!.state =
          PluginLifecycleState.initialized;

      // 2. Transition to active with explicit operator acknowledgment -> SUCCEEDS
      final active = await lifecycle.transitionTo(
        instanceId: 'lifecycle_restricted_plugin',
        targetState: PluginLifecycleState.active,
        context: {'operatorAcknowledged': true},
      );
      expect(active, equals(PluginLifecycleState.active));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 6: Fail-Closed On Ambiguity Test
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '6. Fail-closed on ambiguity: uninterpretable signal biases classification downward',
        () {
      final manifest = createSampleManifest(id: 'ambiguous_plugin');

      final result = trustGate.evaluateTrust(
        manifest: manifest,
        forceAmbiguity: true,
      );

      expect(result.trustLevel, equals(PluginTrustLevel.restricted));
      expect(result.summary, contains('fail-closed'));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 7: Audit & Explainability Test
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '7. Audit & explainability: generated classification contains detailed findings and reasons',
        () {
      final manifest = createSampleManifest(
        id: 'audit_plugin',
        authorName: 'FPS Core Team',
      );

      final result = trustGate.evaluateTrust(manifest: manifest);
      final json = result.toJson();

      expect(json['pluginId'], equals('audit_plugin'));
      expect(json['trustLevel'], equals('trusted'));
      expect(json['findings'], isA<List>());
      expect((json['findings'] as List).length, greaterThanOrEqualTo(5));
      expect(json['summary'], contains('TRUSTED'));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 8: Determinism Test
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '8. Determinism: identical input manifests and gate state produce identical trust classifications',
        () {
      final manifest = createSampleManifest(id: 'det_plugin');

      final res1 = trustGate.evaluateTrust(manifest: manifest);
      final res2 = trustGate.evaluateTrust(manifest: manifest);

      expect(res1.trustLevel, equals(res2.trustLevel));
      expect(res1.findings.length, equals(res2.findings.length));
      expect(res1.summary, equals(res2.summary));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 9: Fail-Closed Edge Cases
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '9a. Fail-closed edge-case: plugin with zero dependencies is not penalized',
        () {
      final manifest =
          createSampleManifest(id: 'no_deps_plugin', dependencies: []);
      final result = trustGate.evaluateTrust(manifest: manifest);

      expect(result.trustLevel, isNot(equals(PluginTrustLevel.blocked)));
      expect(
          result.findings.any((f) =>
              f.signalType == TrustSignalType.dependencyTrust &&
              f.status == TrustSignalStatus.passed),
          isTrue);
    });

    test(
        '9b. Fail-closed edge-case: corrupted/blocked declared dependency blocks parent plugin',
        () {
      final manifest = createSampleManifest(
        id: 'parent_corrupt_child',
        dependencies: [
          PluginDependency(name: 'corrupted_child', versionConstraint: '^1.0.0')
        ],
      );

      final result = trustGate.evaluateTrust(
        manifest: manifest,
        dependencyTrustMap: {'corrupted_child': PluginTrustLevel.blocked},
      );

      expect(result.trustLevel, equals(PluginTrustLevel.blocked));
      expect(result.isHardBlocked, isTrue);
    });

    test(
        '9c. Fail-closed edge-case: empty configuration schema produces zero false risk signals',
        () {
      final manifest = createSampleManifest(
        id: 'empty_config_plugin',
        configSchema: ConfigurationSchema(properties: const []),
      );

      final result = trustGate.evaluateTrust(manifest: manifest);
      expect(
          result.findings.any((f) =>
              f.signalType == TrustSignalType.configurationSafety &&
              f.status == TrustSignalStatus.passed),
          isTrue);
      expect(result.trustLevel, isNot(equals(PluginTrustLevel.restricted)));
    });
  });
}
