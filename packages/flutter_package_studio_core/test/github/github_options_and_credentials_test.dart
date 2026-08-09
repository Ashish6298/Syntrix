import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:test/test.dart';

void main() {
  group('GitHubOptions & GitHubCredentialProvider Tests', () {
    test('GitHubOptions initializes with expected default values', () {
      const options = GitHubOptions(
        repositoryName: 'my_gh_repo',
      );

      expect(options.repositoryName, equals('my_gh_repo'));
      expect(options.isPrivate, isFalse);
      expect(options.defaultBranch, equals('main'));
      expect(options.remoteName, equals('origin'));
      expect(options.createRemote, isTrue);
      expect(options.autoPush, isTrue);
    });

    test('EnvironmentGitHubCredentialProvider redacts secrets from log output',
        () {
      const token = 'ghp_secret_token_12345';
      final provider = EnvironmentGitHubCredentialProvider(
          environment: {'GITHUB_TOKEN': token});

      expect(provider.hasCredential(), completion(isTrue));
      expect(provider.getToken(), completion(equals(token)));

      final redacted = EnvironmentGitHubCredentialProvider.redactSecrets(
          'Error with ghp_secret_token_12345 token', token);
      expect(redacted, contains('[REDACTED_GITHUB_TOKEN]'));
      expect(redacted, isNot(contains(token)));
    });
  });
}
