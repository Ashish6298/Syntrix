import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:test/test.dart';

void main() {
  group('ReleaseChannelManager Unit Tests', () {
    late ReleaseChannelManager manager;

    setUp(() {
      manager = ReleaseChannelManager();
    });

    test(
        'Resolves policies correctly for stable, beta, dev, and canary channels',
        () {
      final stablePol = manager.getPolicy(ReleaseChannelType.stable);
      expect(stablePol.requiresStrictVerification, isTrue);
      expect(stablePol.allowsPrereleaseVersion, isFalse);

      final betaPol = manager.getPolicy(ReleaseChannelType.beta);
      expect(betaPol.allowsPrereleaseVersion, isTrue);
    });

    test('Plans channel promotion preview and validates path safety', () {
      const options = ReleaseChannelOptions(
          packageName: 'awesome_pkg',
          version: '1.0.0',
          targetChannel: ReleaseChannelType.stable,
          outputDir: 'doc/release');
      final plan = manager.planChannelPromotion(options);

      expect(plan.packageName, equals('awesome_pkg'));
      expect(plan.version, equals('1.0.0'));
      expect(plan.targetChannel, equals(ReleaseChannelType.stable));
      expect(plan.isEligible, isTrue);
    });

    test('Rejects prerelease versions for stable channel promotion', () {
      const options = ReleaseChannelOptions(
          packageName: 'awesome_pkg',
          version: '1.0.0-beta.1',
          targetChannel: ReleaseChannelType.stable);
      final plan = manager.planChannelPromotion(options);

      expect(plan.isEligible, isFalse);

      final result = manager.executeChannelPromotion(plan, promote: true);
      expect(result.isSuccess, isFalse);
      expect(result.details,
          contains('Prerelease versions forbidden in stable channel'));
    });

    test('Executes channel promotion preview mode by default (promote: false)',
        () {
      const options = ReleaseChannelOptions(
          packageName: 'awesome_pkg',
          version: '1.0.0',
          targetChannel: ReleaseChannelType.stable);
      final plan = manager.planChannelPromotion(options);
      final result = manager.executeChannelPromotion(plan, promote: false);

      expect(result.packageName, equals('awesome_pkg'));
      expect(result.isSuccess, isTrue);

      final md = result.toMarkdown();
      expect(md, contains('# Release Channel Promotion Report: awesome_pkg'));
      expect(md, contains('PROMOTION APPROVED ✓'));
    });

    test('Rejects absolute output directory paths', () {
      const options =
          ReleaseChannelOptions(packageName: 'pkg', outputDir: '/etc/channels');
      expect(() => manager.planChannelPromotion(options),
          throwsA(isA<ReleaseChannelException>()));
    });

    test('Rejects path traversal ".." in output directory', () {
      const options =
          ReleaseChannelOptions(packageName: 'pkg', outputDir: '../channels');
      expect(() => manager.planChannelPromotion(options),
          throwsA(isA<ReleaseChannelException>()));
    });
  });
}
