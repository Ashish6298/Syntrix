import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:test/test.dart';

void main() {
  group('GitHubService & GitHubMetadataBuilder Tests', () {
    test('GitHubMetadataBuilder produces clean deduplicated topics', () {
      const options = GitHubOptions(
        repositoryName: 'my_awesome_pkg',
        topics: ['Awesome', 'Widget-Lib', 'INVALID_TOPIC!@#'],
      );

      final ctx = TemplateContext(
          {'package_name': 'my_awesome_pkg', 'is_flutter': true});

      final topics = GitHubMetadataBuilder.buildTopics(options, ctx);

      expect(topics, contains('my-awesome-pkg'));
      expect(topics, contains('flutter'));
      expect(topics, contains('flutter-package'));
      expect(topics, isNot(contains('INVALID_TOPIC!@#')));
    });

    test(
        'MockableGitHubService simulates repository creation and duplicate handling',
        () async {
      final service = MockableGitHubService();

      expect(await service.repositoryExists('my_pkg', owner: 'test-user'),
          isFalse);

      const options =
          GitHubOptions(repositoryName: 'my_pkg', owner: 'test-user');
      final res = await service.createRepository(options);

      expect(res['name'], equals('my_pkg'));
      expect(res['html_url'], contains('github.com/test-user/my_pkg'));
      expect(
          await service.repositoryExists('my_pkg', owner: 'test-user'), isTrue);
    });
  });
}
