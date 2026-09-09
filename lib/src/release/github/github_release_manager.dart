import 'package:syntrix/src/documentation/readme/readme_sanitizer.dart';
import 'package:syntrix/src/error/exceptions.dart';
import 'package:syntrix/src/logging/logger.dart';
import 'package:syntrix/src/release/github/github_api_client.dart';
import 'package:syntrix/src/release/github/github_release_models.dart';
import 'package:syntrix/src/release/versioning/semver_models.dart';

/// Core manager service for plan-first GitHub Releases planning, conflict detection, and execution.
class GitHubReleaseManager {
  final Logger _logger = Logger('GitHubReleaseManager');
  final GitHubApiClient _client;

  GitHubReleaseManager({GitHubApiClient? client})
      : _client = client ?? MockGitHubApiClient();

  /// Plans a GitHub release in-memory with zero network or credential requirement.
  GitHubReleasePlan planRelease(GitHubReleaseOptions options) {
    _logger.info(
        'Planning GitHub release for "${options.packageName}" version ${options.version}');

    if (options.packageName.trim().isEmpty) {
      throw GitHubReleaseException('Package name must not be empty.');
    }

    final lowerOutput = options.outputDir.toLowerCase();
    if (lowerOutput.startsWith('/') ||
        lowerOutput.startsWith(RegExp(r'^[a-z]:', caseSensitive: false))) {
      throw GitHubReleaseException(
          'Absolute output directory paths are forbidden: "${options.outputDir}". Relative path required.');
    }
    if (lowerOutput.contains('..')) {
      throw GitHubReleaseException(
          'Path traversal ("..") is forbidden in output directory path: "${options.outputDir}".');
    }

    final semVer = SemVer.parse(options.version);
    final isPrerelease = semVer.isPrerelease || options.channel != 'stable';

    return GitHubReleasePlan(
      packageName: options.packageName,
      version: options.version,
      tagName: options.tagName,
      targetCommitish: options.targetCommitish,
      releaseTitle: options.releaseTitle,
      releaseBody: options.releaseBody,
      isPrerelease: isPrerelease,
      isDraft: options.isDraft,
      updateExisting: options.updateExisting,
      artifacts: List.unmodifiable(options.artifacts),
      isValid: true,
      details:
          'GitHub release plan created cleanly for tag "${options.tagName}".',
    );
  }

  /// Executes GitHub release creation/updating using provided credential and client.
  Future<GitHubReleaseResult> executeRelease({
    required GitHubReleasePlan plan,
    required String ownerRepo,
    required GitHubCredential credential,
    bool execute = false,
  }) async {
    _logger.info('Executing GitHub release for "${plan.packageName}"');

    final cleanName = ReadmeSanitizer.escapeText(plan.packageName);

    if (!execute) {
      return GitHubReleaseResult(
        packageName: cleanName,
        tagName: plan.tagName,
        releaseUrl:
            'https://github.com/$ownerRepo/releases/tag/${plan.tagName}',
        isExecuted: false,
        isDraft: plan.isDraft,
        uploadedArtifacts: const [],
        details: plan.details,
      );
    }

    try {
      final exists = await _client.releaseExists(ownerRepo, plan.tagName);
      if (exists && !plan.updateExisting) {
        throw GitHubReleaseException(
            'GitHub release for tag "${plan.tagName}" already exists. Refusing to overwrite without explicit update authorization.');
      }

      final releaseUrl = await _client.createOrUpdateRelease(
        ownerRepo: ownerRepo,
        plan: plan,
        credential: credential,
      );

      final uploaded = <String>[];
      for (final artifact in plan.artifacts) {
        await _client.uploadArtifact(
          ownerRepo: ownerRepo,
          tagName: plan.tagName,
          artifactPath: artifact,
          credential: credential,
        );
        uploaded.add(artifact);
      }

      return GitHubReleaseResult(
        packageName: cleanName,
        tagName: plan.tagName,
        releaseUrl: releaseUrl,
        isExecuted: true,
        isDraft: plan.isDraft,
        uploadedArtifacts: List.unmodifiable(uploaded),
        details: 'GitHub release successfully created/updated at $releaseUrl.',
      );
    } catch (e) {
      // Ensure credentials are sanitized from exception messages
      final cleanError =
          e.toString().replaceAll(credential.token, '[REDACTED]');
      throw GitHubReleaseException(
          'GitHub release execution failed: $cleanError');
    }
  }
}
