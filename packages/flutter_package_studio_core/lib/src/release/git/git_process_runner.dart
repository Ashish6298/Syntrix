import 'package:flutter_package_studio_core/src/release/git/git_release_models.dart';

/// Abstract interface for executing Git process commands safely.
abstract class GitProcessRunner {
  /// Inspects Git repository state.
  Future<GitReleaseState> getRepositoryState();

  /// Creates a release tag.
  Future<void> createTag(String tagName, {required String message});

  /// Creates a release branch.
  Future<void> createBranch(String branchName);
}

/// Controlled in-memory implementation of [GitProcessRunner] for isolated testing.
class MockGitProcessRunner implements GitProcessRunner {
  final GitReleaseState state;
  final List<String> createdTags = [];
  final List<String> createdBranches = [];

  MockGitProcessRunner({
    this.state = const GitReleaseState(
      currentBranch: 'main',
      currentCommit: 'abc1234',
      isClean: true,
      existingTags: [],
      existingBranches: ['main'],
    ),
  });

  @override
  Future<GitReleaseState> getRepositoryState() async {
    return state;
  }

  @override
  Future<void> createTag(String tagName, {required String message}) async {
    createdTags.add(tagName);
  }

  @override
  Future<void> createBranch(String branchName) async {
    createdBranches.add(branchName);
  }
}
