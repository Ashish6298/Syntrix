import 'package:flutter_package_studio_core/src/github/github_options.dart';

/// Abstract service for interacting with GitHub REST API.
abstract interface class GitHubService {
  /// Verifies authenticated user details or returns `null` if unauthenticated.
  Future<Map<String, dynamic>?> getAuthenticatedUser();

  /// Checks whether a repository named [repoName] owned by [owner] exists on GitHub.
  Future<bool> repositoryExists(String repoName, {String? owner});

  /// Creates a remote GitHub repository based on [options].
  /// Returns metadata map of created repository.
  Future<Map<String, dynamic>> createRepository(GitHubOptions options);
}

/// Mockable/Fake implementation of [GitHubService] for unit testing without live HTTP calls.
class MockableGitHubService implements GitHubService {
  final bool authenticated;
  final Set<String> existingRepositories = {};
  final Map<String, dynamic> createdRepositories = {};

  MockableGitHubService({this.authenticated = true});

  @override
  Future<Map<String, dynamic>?> getAuthenticatedUser() async {
    if (!authenticated) return null;
    return {'login': 'test-user', 'id': 12345};
  }

  @override
  Future<bool> repositoryExists(String repoName, {String? owner}) async {
    final key =
        owner != null && owner.isNotEmpty ? '$owner/$repoName' : repoName;
    return existingRepositories.contains(key);
  }

  @override
  Future<Map<String, dynamic>> createRepository(GitHubOptions options) async {
    final key = options.owner.isNotEmpty
        ? '${options.owner}/${options.repositoryName}'
        : options.repositoryName;
    if (existingRepositories.contains(key)) {
      throw Exception('Repository $key already exists on GitHub.');
    }

    final repoData = {
      'name': options.repositoryName,
      'full_name': key,
      'private': options.isPrivate,
      'html_url': 'https://github.com/$key',
      'clone_url': 'https://github.com/$key.git',
      'default_branch': options.defaultBranch,
    };

    createdRepositories[key] = repoData;
    existingRepositories.add(key);
    return repoData;
  }
}
