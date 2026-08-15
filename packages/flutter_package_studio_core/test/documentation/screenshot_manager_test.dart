import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:test/test.dart';

void main() {
  group('ScreenshotManager Unit Tests', () {
    late ScreenshotManager manager;

    setUp(() {
      manager = ScreenshotManager();
    });

    test('Plans and renders valid default screenshot manifest', () {
      const options = ScreenshotOptions(packageName: 'test_pkg');
      final plan = manager.planScreenshots(options);
      expect(plan.items.length, equals(2));

      final result = manager.manageScreenshots(plan);
      expect(
          result.markdownManifest, contains('# Screenshot Gallery — test_pkg'));
      expect(result.markdownManifest,
          contains('![Application Overview](doc/assets/overview.png)'));
    });

    test('Rejects duplicate screenshot IDs', () {
      const options = ScreenshotOptions(
        packageName: 'dupe_pkg',
        screenshots: [
          ScreenshotItem(id: 's1', title: 'S1', path: 'doc/a.png'),
          ScreenshotItem(id: 's1', title: 'S1 Duplicate', path: 'doc/b.png'),
        ],
      );

      expect(() => manager.planScreenshots(options),
          throwsA(isA<ScreenshotManagementException>()));
    });

    test('Rejects absolute screenshot paths', () {
      const options = ScreenshotOptions(
        packageName: 'abs_pkg',
        screenshots: [
          ScreenshotItem(
              id: 'abs', title: 'Abs Path', path: '/etc/screenshot.png'),
        ],
      );

      expect(() => manager.planScreenshots(options),
          throwsA(isA<ScreenshotManagementException>()));
    });

    test('Rejects path traversal ".." in paths', () {
      const options = ScreenshotOptions(
        packageName: 'traversal_pkg',
        screenshots: [
          ScreenshotItem(
              id: 'bad', title: 'Bad Path', path: 'doc/../../secret.png'),
        ],
      );

      expect(() => manager.planScreenshots(options),
          throwsA(isA<ScreenshotManagementException>()));
    });

    test('Rejects unsupported image formats', () {
      const options = ScreenshotOptions(
        packageName: 'fmt_pkg',
        screenshots: [
          ScreenshotItem(id: 'exe', title: 'Exe File', path: 'doc/image.exe'),
        ],
      );

      expect(() => manager.planScreenshots(options),
          throwsA(isA<ScreenshotManagementException>()));
    });

    test('Output is 100% deterministic across repeated runs', () {
      const options = ScreenshotOptions(packageName: 'det_pkg');

      final plan1 = manager.planScreenshots(options);
      final res1 = manager.manageScreenshots(plan1);

      final plan2 = manager.planScreenshots(options);
      final res2 = manager.manageScreenshots(plan2);

      expect(res1.markdownManifest, equals(res2.markdownManifest));
    });
  });
}
