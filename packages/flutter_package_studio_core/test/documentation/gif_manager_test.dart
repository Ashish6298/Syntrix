import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:test/test.dart';

void main() {
  group('GifManager Unit Tests', () {
    late GifManager manager;

    setUp(() {
      manager = GifManager();
    });

    test('Plans and renders valid default GIF animation manifest', () {
      const options = GifOptions(packageName: 'test_pkg');
      final plan = manager.planGifs(options);
      expect(plan.items.length, equals(2));

      final result = manager.manageGifs(plan);
      expect(result.markdownManifest,
          contains('# Animated Demonstrations — test_pkg'));
      expect(result.markdownManifest,
          contains('![Feature Demo Flow](doc/assets/demo.gif)'));
    });

    test('Rejects duplicate GIF IDs', () {
      const options = GifOptions(
        packageName: 'dupe_pkg',
        gifs: [
          GifItem(id: 'g1', title: 'G1', path: 'doc/a.gif'),
          GifItem(id: 'g1', title: 'G1 Duplicate', path: 'doc/b.gif'),
        ],
      );

      expect(() => manager.planGifs(options),
          throwsA(isA<GifPipelineException>()));
    });

    test('Rejects absolute GIF paths', () {
      const options = GifOptions(
        packageName: 'abs_pkg',
        gifs: [
          GifItem(id: 'abs', title: 'Abs Path', path: '/etc/demo.gif'),
        ],
      );

      expect(() => manager.planGifs(options),
          throwsA(isA<GifPipelineException>()));
    });

    test('Rejects path traversal ".." in paths', () {
      const options = GifOptions(
        packageName: 'traversal_pkg',
        gifs: [
          GifItem(id: 'bad', title: 'Bad Path', path: 'doc/../../secret.gif'),
        ],
      );

      expect(() => manager.planGifs(options),
          throwsA(isA<GifPipelineException>()));
    });

    test('Rejects unsupported animation formats', () {
      const options = GifOptions(
        packageName: 'fmt_pkg',
        gifs: [
          GifItem(id: 'mp4', title: 'MP4 File', path: 'doc/demo.mp4'),
        ],
      );

      expect(() => manager.planGifs(options),
          throwsA(isA<GifPipelineException>()));
    });

    test('Output is 100% deterministic across repeated runs', () {
      const options = GifOptions(packageName: 'det_pkg');

      final plan1 = manager.planGifs(options);
      final res1 = manager.manageGifs(plan1);

      final plan2 = manager.planGifs(options);
      final res2 = manager.manageGifs(plan2);

      expect(res1.markdownManifest, equals(res2.markdownManifest));
    });
  });
}
