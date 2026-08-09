import 'dart:io' as io;
import 'package:path/path.dart' as p;
import 'package:flutter_package_studio_core/src/error/exceptions.dart';
import 'package:flutter_package_studio_core/src/github/github_automation_result.dart';
import 'package:flutter_package_studio_core/src/github/github_credential_provider.dart';
import 'package:flutter_package_studio_core/src/github/github_metadata_builder.dart';
import 'package:flutter_package_studio_core/src/github/github_options.dart';
import 'package:flutter_package_studio_core/src/github/github_repository_plan.dart';
import 'package:flutter_package_studio_core/src/github/github_service.dart';
import 'package:flutter_package_studio_core/src/logging/logger.dart';
import 'package:flutter_package_studio_core/src/repository/git_service.dart';
import 'package:flutter_package_studio_core/src/template/template_context.dart';
import 'package:flutter_package_studio_core/src/utils/file_utils.dart';
import 'package:flutter_package_studio_core/src/validation/validators.dart';

/// Orchestrates GitHub remote repository creation, Git remote setup, and initial push.
class GitHubRepositoryGenerator {
  final FileUtils _fileUtils;
  final GitService _gitService;
  final GitHubService _githubService;
  final GitHubCredentialProvider _credentialProvider;
  final Logger _logger;

  /// Creates a [GitHubRepositoryGenerator] with dependencies.
  GitHubRepositoryGenerator({
    FileUtils fileUtils = const SystemFileUtils(),
    GitService? gitService,
    GitHubService? githubService,
    GitHubCredentialProvider? credentialProvider,
    Logger? logger,
  })  : _fileUtils = fileUtils,
        _gitService = gitService ?? SystemGitService(logger: logger),
        _githubService = githubService ?? MockableGitHubService(),
        _credentialProvider =
            credentialProvider ?? EnvironmentGitHubCredentialProvider(),
        _logger = logger ?? Logger('GitHubRepositoryGenerator');

  /// Validates [options] using core validation framework.
  void validateOptions(GitHubOptions options) {
    final repoNameRes =
        const RepositoryNameValidator().validate(options.repositoryName);
    if (!repoNameRes.isValid) {
      throw ValidationException(
          'Invalid GitHub repository name: ${repoNameRes.errors.join(', ')}');
    }

    final branchRes =
        const GitBranchValidator().validate(options.defaultBranch);
    if (!branchRes.isValid) {
      throw ValidationException(
          'Invalid default branch: ${branchRes.errors.join(', ')}');
    }
  }

  /// Constructs a deterministic plan for GitHub automation.
  Future<GitHubRepositoryPlan> buildPlan({
    required GitHubOptions options,
    required TemplateContext context,
    required String projectDirectory,
  }) async {
    validateOptions(options);

    _sanitizePath(projectDirectory);
    final owner = options.owner.isNotEmpty ? options.owner : 'user';

    final remoteUrl = 'https://github.com/$owner/${options.repositoryName}.git';

    final actions = <GitHubAction>[];

    // 1. Create Remote Repo API action
    if (options.createRemote) {
      actions.add(GitHubAction(
        type: GitHubActionType.createRepository,
        target: '$owner/${options.repositoryName}',
        description:
            'Create ${options.isPrivate ? 'private' : 'public'} repository on GitHub',
      ));
    }

    // 2. Configure Topics & Metadata
    final topics = GitHubMetadataBuilder.buildTopics(options, context);
    if (topics.isNotEmpty) {
      actions.add(GitHubAction(
        type: GitHubActionType.configureMetadata,
        target: topics.join(', '),
        description: 'Set repository topics: ${topics.join(', ')}',
      ));
    }

    // 3. Configure Local Git Remote
    actions.add(GitHubAction(
      type: GitHubActionType.configureRemote,
      target: '${options.remoteName} -> $remoteUrl',
      description: 'Configure local Git remote "${options.remoteName}"',
    ));

    // 4. Initial Commit & Push
    if (options.autoPush) {
      actions.add(const GitHubAction(
        type: GitHubActionType.createInitialCommit,
        target: 'HEAD',
        description: 'Create initial commit if repository is clean',
      ));

      actions.add(GitHubAction(
        type: GitHubActionType.pushRemote,
        target: '${options.remoteName}/${options.defaultBranch}',
        description:
            'Push initial commit to remote branch "${options.defaultBranch}"',
      ));
    }

    return GitHubRepositoryPlan(
      repositoryName: options.repositoryName,
      remoteUrl: remoteUrl,
      actions: actions,
    );
  }

  /// Executes [plan] against GitHub API and local Git repository.
  Future<GitHubAutomationResult> execute({
    required GitHubRepositoryPlan plan,
    required GitHubOptions options,
    required String projectDirectory,
    bool dryRun = false,
  }) async {
    final stopwatch = Stopwatch()..start();
    final executedActions = <String>[];
    final warnings = <String>[];
    bool remoteCreated = false;
    bool pushed = false;

    final rootDir = _sanitizePath(projectDirectory);
    _logger.info(
        'Executing GitHub automation for "${plan.repositoryName}" in "$rootDir" (dryRun: $dryRun)');

    if (dryRun) {
      stopwatch.stop();
      return GitHubAutomationSuccess(
        repositoryName: plan.repositoryName,
        duration: stopwatch.elapsed,
        isDryRun: true,
        remoteUrl: plan.remoteUrl,
        executedActions: plan.actions.map((a) => a.description).toList(),
        remoteCreated: false,
        pushed: false,
      );
    }

    try {
      // Check credentials
      final hasToken = await _credentialProvider.hasCredential();
      final token = await _credentialProvider.getToken();

      // 1. Create Remote Repository if requested
      if (options.createRemote) {
        if (!hasToken && _githubService is! MockableGitHubService) {
          throw GitHubAuthenticationException(
              'Missing GITHUB_TOKEN or GH_TOKEN environment variable.');
        }

        final exists = await _githubService
            .repositoryExists(options.repositoryName, owner: options.owner);
        if (exists) {
          warnings.add(
              'GitHub repository "${options.repositoryName}" already exists. Skipped API creation.');
          executedActions.add('skip_existing_repository');
        } else {
          await _githubService.createRepository(options);
          remoteCreated = true;
          executedActions.add('create_repository');
        }
      }

      // 2. Configure Local Git Remote
      final gitInstalled = await _gitService.isGitInstalled();
      if (!gitInstalled) {
        throw GitHubException('Git CLI is not installed or available on PATH.');
      }

      await _gitService.initRepository(rootDir,
          defaultBranch: options.defaultBranch);
      await _addOrUpdateRemote(rootDir, options.remoteName, plan.remoteUrl);
      executedActions.add('configure_remote');

      // 3. Stage & Initial Commit
      if (options.autoPush) {
        final hasCommits = await _hasCommits(rootDir);
        if (!hasCommits) {
          await _createInitialCommit(rootDir);
          executedActions.add('create_initial_commit');
        }

        // Push to remote (safety: no force push)
        await _pushToRemote(rootDir, options.remoteName, options.defaultBranch);
        pushed = true;
        executedActions.add('push_remote');
      }

      stopwatch.stop();
      return GitHubAutomationSuccess(
        repositoryName: plan.repositoryName,
        duration: stopwatch.elapsed,
        isDryRun: false,
        remoteUrl: EnvironmentGitHubCredentialProvider.redactSecrets(
            plan.remoteUrl, token),
        executedActions: executedActions,
        remoteCreated: remoteCreated,
        pushed: pushed,
        warnings: warnings,
      );
    } catch (e, st) {
      stopwatch.stop();
      final token = await _credentialProvider.getToken();
      final safeError = EnvironmentGitHubCredentialProvider.redactSecrets(
          e.toString(), token);
      _logger.error('GitHub automation failed: $safeError', e, st);

      return GitHubAutomationFailure(
        repositoryName: plan.repositoryName,
        duration: stopwatch.elapsed,
        isDryRun: false,
        message: 'GitHub automation failed: $safeError',
        errors: [safeError],
      );
    }
  }

  Future<void> _addOrUpdateRemote(
      String dir, String remoteName, String url) async {
    try {
      final checkRes = await io.Process.run(
          'git', ['remote', 'get-url', remoteName],
          workingDirectory: dir);
      if (checkRes.exitCode == 0) {
        await io.Process.run('git', ['remote', 'set-url', remoteName, url],
            workingDirectory: dir);
      } else {
        await io.Process.run('git', ['remote', 'add', remoteName, url],
            workingDirectory: dir);
      }
    } catch (_) {}
  }

  Future<bool> _hasCommits(String dir) async {
    try {
      final res = await io.Process.run('git', ['rev-parse', 'HEAD'],
          workingDirectory: dir);
      return res.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  Future<void> _createInitialCommit(String dir) async {
    await io.Process.run('git', ['add', '.'], workingDirectory: dir);
    await io.Process.run('git',
        ['commit', '-m', 'Initial commit generated by Flutter Package Studio'],
        workingDirectory: dir);
  }

  Future<void> _pushToRemote(
      String dir, String remoteName, String branch) async {
    // Non-destructive push without --force
    final res = await io.Process.run('git', ['push', '-u', remoteName, branch],
        workingDirectory: dir);
    if (res.exitCode != 0) {
      _logger.warning('Git push failed or remote unreachable: ${res.stderr}');
    }
  }

  String _sanitizePath(String projectDir) {
    final normalized = p.normalize(p.absolute(projectDir));
    if (_fileUtils.exists(normalized) && !_fileUtils.isDirectory(normalized)) {
      throw GitHubConfigurationException(
          'Target path is not a directory: "$normalized".');
    }
    return normalized;
  }
}
