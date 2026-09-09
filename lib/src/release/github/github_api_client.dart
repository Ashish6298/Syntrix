import 'package:syntrix/src/release/github/github_release_models.dart';

/// Abstract interface for GitHub API operations isolating network interaction.
abstract class GitHubApiClient {
  /// Checks if a release exists for target tag.
  Future<bool> releaseExists(String ownerRepo, String tagName);

  /// Creates or updates a GitHub release.
  Future<String> createOrUpdateRelease({
    required String ownerRepo,
    required GitHubReleasePlan plan,
    required GitHubCredential credential,
  });

  /// Uploads an artifact asset to a release.
  Future<void> uploadArtifact({
    required String ownerRepo,
    required String tagName,
    required String artifactPath,
    required GitHubCredential credential,
  });
}

/// Controlled in-memory implementation of [GitHubApiClient] for isolated testing.
class MockGitHubApiClient implements GitHubApiClient {
  final Map<String, bool> existingReleases;
  final bool shouldFailAuth;
  final bool shouldFailRateLimit;
  final bool shouldFailNetwork;
  final bool shouldFailTagNotFound;
  final bool shouldFailUpload;

  final List<String> createdReleases = [];
  final List<String> uploadedAssets = [];

  MockGitHubApiClient({
    this.existingReleases = const {},
    this.shouldFailAuth = false,
    this.shouldFailRateLimit = false,
    this.shouldFailNetwork = false,
    this.shouldFailTagNotFound = false,
    this.shouldFailUpload = false,
  });

  @override
  Future<bool> releaseExists(String ownerRepo, String tagName) async {
    if (shouldFailNetwork)
      throw Exception('Network timeout connecting to api.github.com');
    if (shouldFailRateLimit)
      throw Exception('GitHub API rate limit exceeded (429)');
    return existingReleases[tagName] ?? false;
  }

  @override
  Future<String> createOrUpdateRelease({
    required String ownerRepo,
    required GitHubReleasePlan plan,
    required GitHubCredential credential,
  }) async {
    if (shouldFailAuth)
      throw Exception('401 Unauthorized: Invalid GitHub token');
    if (shouldFailTagNotFound)
      throw Exception('404 Not Found: Tag "${plan.tagName}" does not exist');
    if (shouldFailNetwork)
      throw Exception('Network timeout connecting to api.github.com');

    createdReleases.add(plan.tagName);
    return 'https://github.com/$ownerRepo/releases/tag/${plan.tagName}';
  }

  @override
  Future<void> uploadArtifact({
    required String ownerRepo,
    required String tagName,
    required String artifactPath,
    required GitHubCredential credential,
  }) async {
    if (shouldFailUpload)
      throw Exception(
          'Failed to upload asset "$artifactPath": server error 500');
    uploadedAssets.add(artifactPath);
  }
}
