import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:test/test.dart';

void main() {
  group('StaticWebsiteGenerator Unit Tests', () {
    late StaticWebsiteGenerator generator;

    setUp(() {
      generator = StaticWebsiteGenerator();
    });

    test('Plans static website by aggregating documentation sub-generators',
        () {
      const options = WebsiteOptions(packageName: 'awesome_flutter_pkg');
      final plan = generator.planWebsite(options);

      expect(plan.packageName, equals('awesome_flutter_pkg'));
      expect(plan.pages.length, equals(5));
      expect(plan.navigation.length, equals(5));

      final routes = plan.pages.map((p) => p.route).toList();
      expect(routes, contains('index.html'));
      expect(routes, contains('architecture.html'));
      expect(routes, contains('examples.html'));
      expect(routes, contains('screenshots.html'));
      expect(routes, contains('gifs.html'));
    });

    test('Renders static HTML pages deterministically', () {
      const options = WebsiteOptions(packageName: 'det_site_pkg');

      final plan1 = generator.planWebsite(options);
      final res1 = generator.generateWebsite(plan1);

      final plan2 = generator.planWebsite(options);
      final res2 = generator.generateWebsite(plan2);

      expect(res1.files, equals(res2.files));
      expect(res1.files['index.html'], contains('<!DOCTYPE html>'));
      expect(res1.files['index.html'], contains('Overview'));
    });

    test('WebsiteResult produces valid JSON map', () {
      const options = WebsiteOptions(packageName: 'json_pkg');
      final plan = generator.planWebsite(options);
      final result = generator.generateWebsite(plan);
      final json = result.toJson();

      expect(json['packageName'], equals('json_pkg'));
      expect(json['fileCount'], equals(5));
      expect(json['routes'], isA<List>());
    });
  });
}
