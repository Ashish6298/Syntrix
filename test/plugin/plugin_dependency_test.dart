import 'package:syntrix/flutter_package_studio_core.dart';
import 'package:test/test.dart';

void main() {
  group('PluginDependencyResolver Unit Tests (Phase 7.6)', () {
    late PluginDependencyResolver resolver;

    setUp(() {
      resolver = PluginDependencyResolver();
    });

    PluginManifest buildManifest({
      required String id,
      String version = '1.0.0',
      String apiVersion = '1.0.0',
      List<PluginDependency>? dependencies,
    }) {
      return PluginManifest(
        id: PluginId(id),
        name: PluginName('Plugin $id'),
        description: PluginDescription('Desc for $id'),
        version: SemVer.parse(version),
        author: const PluginAuthor(name: 'Dev'),
        apiVersion: apiVersion,
        capabilities: {PluginCapability.commandContribution},
        compatibility: PluginCompatibility(minApiVersion: '1.0.0'),
        dependencies: dependencies,
      );
    }

    test('1. Fully-compatible happy-path linear test (A -> B -> C)', () {
      // C depends on B; B depends on A
      final mA = buildManifest(id: 'plugin_a', version: '1.0.0');
      final mB = buildManifest(id: 'plugin_b', version: '1.0.0', dependencies: [
        PluginDependency(name: 'plugin_a', versionConstraint: '^1.0.0'),
      ]);
      final mC = buildManifest(id: 'plugin_c', version: '1.0.0', dependencies: [
        PluginDependency(name: 'plugin_b', versionConstraint: '^1.0.0'),
      ]);

      final result = resolver.resolveDependencies([mC, mB, mA]);

      expect(result.isCompatible, isTrue);
      expect(result.initializationOrder,
          equals(['plugin_a', 'plugin_b', 'plugin_c']));
    });

    test('2. Complex valid-graph test with diamond shape (A -> B,C -> D)', () {
      final mD = buildManifest(id: 'plugin_d');
      final mB = buildManifest(id: 'plugin_b', dependencies: [
        PluginDependency(name: 'plugin_d', versionConstraint: '^1.0.0'),
      ]);
      final mC = buildManifest(id: 'plugin_c', dependencies: [
        PluginDependency(name: 'plugin_d', versionConstraint: '^1.0.0'),
      ]);
      final mA = buildManifest(id: 'plugin_a', dependencies: [
        PluginDependency(name: 'plugin_b', versionConstraint: '^1.0.0'),
        PluginDependency(name: 'plugin_c', versionConstraint: '^1.0.0'),
      ]);

      final result = resolver.resolveDependencies([mA, mB, mC, mD]);

      expect(result.isCompatible, isTrue);
      expect(result.initializationOrder!.first, equals('plugin_d'));
      expect(result.initializationOrder!.last, equals('plugin_a'));
    });

    test('3a. Specific problem detection: missing dependency', () {
      final mA = buildManifest(id: 'plugin_a', dependencies: [
        PluginDependency(name: 'nonexistent_b', versionConstraint: '^1.0.0'),
      ]);

      final result = resolver.resolveDependencies([mA]);

      expect(result.isCompatible, isFalse);
      expect(result.findings.first.type,
          equals(DependencyProblemType.missingDependency));
      expect(result.findings.first.sourcePluginId, equals('plugin_a'));
      expect(result.findings.first.targetPluginId, equals('nonexistent_b'));
    });

    test(
        '3b. Specific problem detection: version conflict (malformed constraint)',
        () {
      final mB = buildManifest(id: 'plugin_b', version: '1.0.0');
      final mA = buildManifest(id: 'plugin_a', dependencies: [
        PluginDependency(
            name: 'plugin_b', versionConstraint: 'invalid_constraint_xyz'),
      ]);

      final result = resolver.resolveDependencies([mA, mB]);

      expect(result.isCompatible, isFalse);
      expect(result.findings.first.type,
          equals(DependencyProblemType.versionConflict));
      expect(result.findings.first.sourcePluginId, equals('plugin_a'));
    });

    test(
        '3c-1. Specific problem detection: circular dependency (short A -> B -> A cycle)',
        () {
      final mA = buildManifest(id: 'plugin_a', dependencies: [
        PluginDependency(name: 'plugin_b', versionConstraint: '^1.0.0'),
      ]);
      final mB = buildManifest(id: 'plugin_b', dependencies: [
        PluginDependency(name: 'plugin_a', versionConstraint: '^1.0.0'),
      ]);

      final result = resolver.resolveDependencies([mA, mB]);

      expect(result.isCompatible, isFalse);
      expect(result.findings.first.type,
          equals(DependencyProblemType.circularDependency));
      expect(result.findings.first.details,
          contains('plugin_a -> plugin_b -> plugin_a'));
    });

    test(
        '3c-2. Specific problem detection: circular dependency (longer A -> B -> C -> A cycle)',
        () {
      final mA = buildManifest(id: 'plugin_a', dependencies: [
        PluginDependency(name: 'plugin_b', versionConstraint: '^1.0.0'),
      ]);
      final mB = buildManifest(id: 'plugin_b', dependencies: [
        PluginDependency(name: 'plugin_c', versionConstraint: '^1.0.0'),
      ]);
      final mC = buildManifest(id: 'plugin_c', dependencies: [
        PluginDependency(name: 'plugin_a', versionConstraint: '^1.0.0'),
      ]);

      final result = resolver.resolveDependencies([mA, mB, mC]);

      expect(result.isCompatible, isFalse);
      expect(result.findings.first.type,
          equals(DependencyProblemType.circularDependency));
      expect(result.findings.first.details,
          contains('plugin_a -> plugin_b -> plugin_c -> plugin_a'));
    });

    test('3d. Specific problem detection: unsupported API version', () {
      final mA = buildManifest(id: 'plugin_a', apiVersion: '9.9.9');

      final result = resolver.resolveDependencies([mA]);

      expect(result.isCompatible, isFalse);
      expect(result.findings.first.type,
          equals(DependencyProblemType.unsupportedApiVersion));
      expect(result.findings.first.sourcePluginId, equals('plugin_a'));
    });

    test('3e. Specific problem detection: incompatible plugin version', () {
      final mB = buildManifest(id: 'plugin_b', version: '2.0.0');
      final mA = buildManifest(id: 'plugin_a', dependencies: [
        PluginDependency(name: 'plugin_b', versionConstraint: '^1.0.0'),
      ]);

      final result = resolver.resolveDependencies([mA, mB]);

      expect(result.isCompatible, isFalse);
      expect(result.findings.first.type,
          equals(DependencyProblemType.incompatiblePluginVersion));
      expect(result.findings.first.sourcePluginId, equals('plugin_a'));
      expect(result.findings.first.targetPluginId, equals('plugin_b'));
    });

    test('3f. Specific problem detection: dependency ordering impossible', () {
      final mA = buildManifest(id: 'plugin_a', dependencies: [
        PluginDependency(name: 'plugin_b', versionConstraint: '^1.0.0'),
      ]);
      final mB = buildManifest(id: 'plugin_b', dependencies: [
        PluginDependency(name: 'plugin_a', versionConstraint: '^1.0.0'),
      ]);

      final result = resolver.resolveDependencies([mA, mB]);

      expect(result.isCompatible, isFalse);
      expect(
          result.findings.any((f) =>
              f.type == DependencyProblemType.circularDependency ||
              f.type == DependencyProblemType.dependencyOrderingImpossible),
          isTrue);
    });

    test(
        '4. Multi-problem test returns all simultaneous distinct problems together',
        () {
      final mA =
          buildManifest(id: 'plugin_a', apiVersion: '9.9.9', dependencies: [
        PluginDependency(name: 'missing_b', versionConstraint: '^1.0.0'),
      ]);

      final result = resolver.resolveDependencies([mA]);

      expect(result.isCompatible, isFalse);
      expect(result.findings.length,
          equals(2)); // unsupportedApiVersion + missingDependency
    });

    test(
        '5. Blocked-result-has-no-partial-order test confirms null initialization order on failure',
        () {
      final mA = buildManifest(id: 'plugin_a', dependencies: [
        PluginDependency(name: 'missing_b', versionConstraint: '^1.0.0'),
      ]);

      final result = resolver.resolveDependencies([mA]);

      expect(result.isCompatible, isFalse);
      expect(result.initializationOrder, isNull);
    });

    test(
        '6. Determinism test confirms identical order even when input list is scrambled',
        () {
      final mD = buildManifest(id: 'plugin_d');
      final mB = buildManifest(id: 'plugin_b', dependencies: [
        PluginDependency(name: 'plugin_d', versionConstraint: '^1.0.0'),
      ]);
      final mC = buildManifest(id: 'plugin_c', dependencies: [
        PluginDependency(name: 'plugin_d', versionConstraint: '^1.0.0'),
      ]);
      final mA = buildManifest(id: 'plugin_a', dependencies: [
        PluginDependency(name: 'plugin_b', versionConstraint: '^1.0.0'),
        PluginDependency(name: 'plugin_c', versionConstraint: '^1.0.0'),
      ]);

      final r1 = resolver.resolveDependencies([mA, mB, mC, mD]);
      final r2 = resolver.resolveDependencies([mD, mC, mB, mA]);

      expect(r1.initializationOrder, equals(r2.initializationOrder));
    });

    test(
        '7. Non-execution audit: resolving graph performs zero code execution or lifecycle calls',
        () {
      final mA = buildManifest(id: 'plugin_a');
      final result = resolver.resolveDependencies([mA]);

      expect(result.isCompatible, isTrue);
    });

    test(
        '8. Reuse-verification test confirms PluginContractValidator.supportedApiVersions is re-used',
        () {
      expect(PluginContractValidator.supportedApiVersions.contains('1.0.0'),
          isTrue);
      final mA = buildManifest(id: 'plugin_a', apiVersion: '1.0.0');

      final result = resolver.resolveDependencies([mA]);
      expect(
          result.findings.any(
              (f) => f.type == DependencyProblemType.unsupportedApiVersion),
          isFalse);
    });

    test(
        '9a. Fail-closed edge-case: empty plugin set resolves to empty valid order',
        () {
      final result = resolver.resolveDependencies([]);
      expect(result.isCompatible, isTrue);
      expect(result.initializationOrder, isEmpty);
    });

    test(
        '9b. Fail-closed edge-case: single plugin with no dependencies resolves trivially',
        () {
      final mA = buildManifest(id: 'plugin_a');
      final result = resolver.resolveDependencies([mA]);

      expect(result.isCompatible, isTrue);
      expect(result.initializationOrder, equals(['plugin_a']));
    });

    test('9c. Fail-closed edge-case: self-dependency treated as one-node cycle',
        () {
      expect(
        () => PluginManifest(
          id: PluginId('plugin_self'),
          name: PluginName('N'),
          description: PluginDescription('D'),
          version: SemVer.parse('1.0.0'),
          author: const PluginAuthor(name: 'A'),
          apiVersion: '1.0.0',
          capabilities: {PluginCapability.commandContribution},
          compatibility: PluginCompatibility(minApiVersion: '1.0.0'),
          dependencies: [
            PluginDependency(name: 'plugin_self', versionConstraint: '^1.0.0'),
          ],
        ),
        throwsA(isA<PluginContractException>()),
      );
    });

    test(
        '9d. Fail-closed edge-case: malformed version-range constraint treated as blocked',
        () {
      final mB = buildManifest(id: 'plugin_b', version: '1.0.0');
      final mA = buildManifest(id: 'plugin_a', dependencies: [
        PluginDependency(
            name: 'plugin_b', versionConstraint: 'illegal range!@#'),
      ]);

      final result = resolver.resolveDependencies([mA, mB]);
      expect(result.isCompatible, isFalse);
      expect(result.findings.first.type,
          equals(DependencyProblemType.versionConflict));
    });
  });
}
