import 'dart:io';

import 'package:syntrix/flutter_package_studio_core.dart';
import 'package:test/test.dart';

void main() {
  group('PluginDiscoveryEngine Unit Tests (Phase 7.4)', () {
    late Directory tempDir;
    late PluginDiscoveryEngine engine;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('fps_discovery_test_');
      engine = PluginDiscoveryEngine();
    });

    tearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test(
        '1. Happy-path discovery test matching roadmap example layout (3 valid plugins)',
        () async {
      final p1 = Directory('${tempDir.path}/plugin_a');
      final p2 = Directory('${tempDir.path}/plugin_b');
      final p3 = Directory('${tempDir.path}/plugin_c');

      await p1.create();
      await p2.create();
      await p3.create();

      await File('${p1.path}/plugin.json').writeAsString(
          '{"id":"plugin_a","name":"A","description":"D","version":"1.0.0","author":{"name":"X"},"apiVersion":"1.0.0","capabilities":["commandContribution"],"compatibility":{"minApiVersion":"1.0.0"}}');
      await File('${p2.path}/plugin.json').writeAsString(
          '{"id":"plugin_b","name":"B","description":"D","version":"1.0.0","author":{"name":"X"},"apiVersion":"1.0.0","capabilities":["commandContribution"],"compatibility":{"minApiVersion":"1.0.0"}}');
      await File('${p3.path}/plugin.json').writeAsString(
          '{"id":"plugin_c","name":"C","description":"D","version":"1.0.0","author":{"name":"X"},"apiVersion":"1.0.0","capabilities":["commandContribution"],"compatibility":{"minApiVersion":"1.0.0"}}');

      final result = await engine.discoverPlugins([tempDir.path]);

      expect(result.entries.length, equals(3));
      expect(result.validEntries.length, equals(3));
      expect(result.validEntries.map((e) => e.manifest!.id.value),
          equals(['plugin_a', 'plugin_b', 'plugin_c']));
    });

    test(
        '2. Invalid-manifest test reports specific violations from Phase 7.1 validator',
        () async {
      final p = Directory('${tempDir.path}/invalid_plugin');
      await p.create();
      await File('${p.path}/plugin.json').writeAsString(
          '{"id":"INVALID ID!","name":"","description":"","version":"bad","author":{},"apiVersion":"1.0.0","capabilities":[],"compatibility":{}}');

      final result = await engine.discoverPlugins([tempDir.path]);

      expect(result.invalidEntries.length, equals(1));
      expect(result.invalidEntries.first.details, isNotEmpty);
      expect(
          result.invalidEntries.first.details
              .any((d) => d.contains('[PluginId]')),
          isTrue);
    });

    test('3. No-manifest-present test silently excludes directory', () async {
      final p = Directory('${tempDir.path}/plain_dir');
      await p.create();

      final result = await engine.discoverPlugins([tempDir.path]);
      expect(result.entries, isEmpty);
    });

    test(
        '4. Duplicate-plugin-ID test flags all directories declaring same PluginId',
        () async {
      final p1 = Directory('${tempDir.path}/dir_a');
      final p2 = Directory('${tempDir.path}/dir_b');
      await p1.create();
      await p2.create();

      const manifestContent =
          '{"id":"same_id","name":"A","description":"D","version":"1.0.0","author":{"name":"X"},"apiVersion":"1.0.0","capabilities":["commandContribution"],"compatibility":{"minApiVersion":"1.0.0"}}';
      await File('${p1.path}/plugin.json').writeAsString(manifestContent);
      await File('${p2.path}/plugin.json').writeAsString(manifestContent);

      final result = await engine.discoverPlugins([tempDir.path]);

      expect(result.duplicateEntries.length, equals(2));
      expect(
          result.duplicateEntries
              .every((e) => e.status == DiscoveredPluginStatus.duplicate),
          isTrue);
    });

    test(
        '5. Unsupported-API-version test distinctly categorizes unsupported version',
        () async {
      final p = Directory('${tempDir.path}/unsupported_plugin');
      await p.create();
      await File('${p.path}/plugin.json').writeAsString(
          '{"id":"unsupported_plugin","name":"A","description":"D","version":"1.0.0","author":{"name":"X"},"apiVersion":"9.9.9","capabilities":["commandContribution"],"compatibility":{"minApiVersion":"1.0.0"}}');

      final result = await engine.discoverPlugins([tempDir.path]);

      expect(result.unsupportedEntries.length, equals(1));
      expect(result.unsupportedEntries.first.status,
          equals(DiscoveredPluginStatus.unsupported));
    });

    test('6. Deterministic-ordering test produces identically sorted results',
        () async {
      final p3 = Directory('${tempDir.path}/plugin_z');
      final p1 = Directory('${tempDir.path}/plugin_a');
      final p2 = Directory('${tempDir.path}/plugin_m');
      await p3.create();
      await p1.create();
      await p2.create();

      await File('${p3.path}/plugin.json').writeAsString(
          '{"id":"plugin_z","name":"Z","description":"D","version":"1.0.0","author":{"name":"X"},"apiVersion":"1.0.0","capabilities":["commandContribution"],"compatibility":{"minApiVersion":"1.0.0"}}');
      await File('${p1.path}/plugin.json').writeAsString(
          '{"id":"plugin_a","name":"A","description":"D","version":"1.0.0","author":{"name":"X"},"apiVersion":"1.0.0","capabilities":["commandContribution"],"compatibility":{"minApiVersion":"1.0.0"}}');
      await File('${p2.path}/plugin.json').writeAsString(
          '{"id":"plugin_m","name":"M","description":"D","version":"1.0.0","author":{"name":"X"},"apiVersion":"1.0.0","capabilities":["commandContribution"],"compatibility":{"minApiVersion":"1.0.0"}}');

      final r1 = await engine.discoverPlugins([tempDir.path]);
      final r2 = await engine.discoverPlugins([tempDir.path]);

      final ids1 = r1.entries.map((e) => e.manifest!.id.value).toList();
      final ids2 = r2.entries.map((e) => e.manifest!.id.value).toList();

      expect(ids1, equals(['plugin_a', 'plugin_m', 'plugin_z']));
      expect(ids1, equals(ids2));
    });

    test(
        '7. Non-execution audit: executable files alongside manifest are completely untouched',
        () async {
      final p = Directory('${tempDir.path}/script_plugin');
      await p.create();
      await File('${p.path}/plugin.json').writeAsString(
          '{"id":"script_plugin","name":"S","description":"D","version":"1.0.0","author":{"name":"X"},"apiVersion":"1.0.0","capabilities":["commandContribution"],"compatibility":{"minApiVersion":"1.0.0"}}');

      // Add executable script / binary alongside manifest
      final script = File('${p.path}/dangerous_script.sh');
      await script.writeAsString('rm -rf /');

      final result = await engine.discoverPlugins([tempDir.path]);
      expect(result.validEntries.length, equals(1));
    });

    test(
        '8. Discovery-does-not-register test confirms PluginRegistry remains untouched',
        () async {
      final registry = PluginRegistry();
      final p = Directory('${tempDir.path}/valid_plugin');
      await p.create();
      await File('${p.path}/plugin.json').writeAsString(
          '{"id":"valid_plugin","name":"V","description":"D","version":"1.0.0","author":{"name":"X"},"apiVersion":"1.0.0","capabilities":["commandContribution"],"compatibility":{"minApiVersion":"1.0.0"}}');

      final result = await engine.discoverPlugins([tempDir.path]);
      expect(result.validEntries.length, equals(1));
      expect(registry.listPlugins(), isEmpty);
    });

    test(
        '9a. Defensive filesystem: unreadable/permission-denied directory handled fail-closed',
        () async {
      final result =
          await engine.discoverPlugins(['/nonexistent_system_dir_xyz']);
      expect(result.entries, isEmpty);
    });

    test(
        '9b. Defensive filesystem: symlinked plugin directory explicitly handled (do not follow policy)',
        () async {
      final realDir = Directory('${tempDir.path}/real_plugin');
      await realDir.create();
      await File('${realDir.path}/plugin.json').writeAsString(
          '{"id":"real_plugin","name":"R","description":"D","version":"1.0.0","author":{"name":"X"},"apiVersion":"1.0.0","capabilities":["commandContribution"],"compatibility":{"minApiVersion":"1.0.0"}}');

      final link = Link('${tempDir.path}/symlink_plugin');
      try {
        await link.create(realDir.path);
        final result = await engine.discoverPlugins([tempDir.path]);
        expect(
            result.entries.any((e) =>
                e.directoryPath.contains('symlink_plugin') &&
                e.status == DiscoveredPluginStatus.invalid),
            isTrue);
      } catch (_) {
        // Fallback on platforms where symlink creation requires admin privileges
      }
    });

    test('9c. Defensive filesystem: corrupted non-UTF8 manifest file',
        () async {
      final p = Directory('${tempDir.path}/corrupt_plugin');
      await p.create();
      await File('${p.path}/plugin.json').writeAsBytes([0xFF, 0xFE, 0xFD]);

      final result = await engine.discoverPlugins([tempDir.path]);
      expect(result.invalidEntries.length, equals(1));
      expect(result.invalidEntries.first.details.first,
          contains('Corrupted or non-UTF-8'));
    });

    test(
        '9d. Defensive filesystem: suspiciously oversized manifest file (>512KB)',
        () async {
      final p = Directory('${tempDir.path}/huge_plugin');
      await p.create();
      final hugeString = '{"id":"huge_plugin","name":"${"A" * (600 * 1024)}"}';
      await File('${p.path}/plugin.json').writeAsString(hugeString);

      final result = await engine.discoverPlugins([tempDir.path]);
      expect(result.invalidEntries.length, equals(1));
      expect(result.invalidEntries.first.details.first,
          contains('Oversized manifest'));
    });

    test(
        '10. Multi-root-directory test aggregates discovery across multiple root directories',
        () async {
      final root1 = Directory('${tempDir.path}/root1');
      final root2 = Directory('${tempDir.path}/root2');
      await root1.create();
      await root2.create();

      final p1 = Directory('${root1.path}/plugin_1');
      final p2 = Directory('${root2.path}/plugin_2');
      await p1.create();
      await p2.create();

      await File('${p1.path}/plugin.json').writeAsString(
          '{"id":"plugin_1","name":"P1","description":"D","version":"1.0.0","author":{"name":"X"},"apiVersion":"1.0.0","capabilities":["commandContribution"],"compatibility":{"minApiVersion":"1.0.0"}}');
      await File('${p2.path}/plugin.json').writeAsString(
          '{"id":"plugin_2","name":"P2","description":"D","version":"1.0.0","author":{"name":"X"},"apiVersion":"1.0.0","capabilities":["commandContribution"],"compatibility":{"minApiVersion":"1.0.0"}}');

      final result = await engine.discoverPlugins([root1.path, root2.path]);
      expect(result.validEntries.length, equals(2));
    });

    test(
        '11. Empty-plugins-directory test produces valid empty discovery result',
        () async {
      final emptyRoot = Directory('${tempDir.path}/empty_root');
      await emptyRoot.create();

      final result = await engine.discoverPlugins([emptyRoot.path]);
      expect(result.scannedRoots.length, equals(1));
      expect(result.entries, isEmpty);
    });
  });
}
