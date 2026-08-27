import 'package:flutter_package_studio_core/src/error/exceptions.dart';
import 'package:flutter_package_studio_core/src/logging/logger.dart';
import 'package:flutter_package_studio_core/src/release/changelog/automated_changelog_generator.dart';
import 'package:flutter_package_studio_core/src/release/changelog/automated_changelog_models.dart';
import 'package:flutter_package_studio_core/src/release/dry_run/release_dry_run_models.dart';
import 'package:flutter_package_studio_core/src/release/git/git_release_manager.dart';
import 'package:flutter_package_studio_core/src/release/git/git_release_models.dart';
import 'package:flutter_package_studio_core/src/release/github/github_release_manager.dart';
import 'package:flutter_package_studio_core/src/release/github/github_release_models.dart';
import 'package:flutter_package_studio_core/src/release/notes_generator/release_notes_generator.dart';
import 'package:flutter_package_studio_core/src/release/versioning/semantic_version_manager.dart';
import 'package:flutter_package_studio_core/src/release/versioning/semver_models.dart';

/// Core orchestrator for composing upstream release planning phases (6.1–6.5) with zero real-world side effects.
class ReleaseDryRunOrchestrator {
  final Logger _logger = Logger('ReleaseDryRunOrchestrator');
  final SemanticVersionManager _semVerManager;
  final AutomatedChangelogGenerator _changelogGenerator;
  final GitReleaseManager _gitReleaseManager;
  final ReleaseNotesGenerator _notesGenerator;
  final GitHubReleaseManager _gitHubReleaseManager;

  ReleaseDryRunOrchestrator({
    SemanticVersionManager? semVerManager,
    AutomatedChangelogGenerator? changelogGenerator,
    GitReleaseManager? gitReleaseManager,
    ReleaseNotesGenerator? notesGenerator,
    GitHubReleaseManager? gitHubReleaseManager,
  })  : _semVerManager = semVerManager ?? SemanticVersionManager(),
        _changelogGenerator =
            changelogGenerator ?? AutomatedChangelogGenerator(),
        _gitReleaseManager = gitReleaseManager ?? GitReleaseManager(),
        _notesGenerator = notesGenerator ?? ReleaseNotesGenerator(),
        _gitHubReleaseManager = gitHubReleaseManager ?? GitHubReleaseManager();

  /// Orchestrates end-to-end dry run evaluation over upstream planning APIs synchronously / side-effect-free.
  Future<ReleaseDryRunReport> executeDryRun(
      ReleaseDryRunOptions options) async {
    _logger
        .info('Executing dry run orchestration for "${options.packageName}"');

    if (options.packageName.trim().isEmpty) {
      throw ReleaseDryRunException('Package name must not be empty.');
    }

    final lowerOutput = options.outputDir.toLowerCase();
    if (lowerOutput.startsWith('/') ||
        lowerOutput.startsWith(RegExp(r'^[a-z]:', caseSensitive: false))) {
      throw ReleaseDryRunException(
          'Absolute output directory paths are forbidden: "${options.outputDir}". Relative path required.');
    }
    if (lowerOutput.contains('..')) {
      throw ReleaseDryRunException(
          'Path traversal ("..") is forbidden in output directory path: "${options.outputDir}".');
    }

    final findings = <DryRunValidationFinding>[];

    // Stage 6.1: SemVer Plan
    SemVerPlan? semVerPlan;
    try {
      semVerPlan = _semVerManager.planTransition(SemVerOptions(
        packageName: options.packageName,
        currentVersion: options.currentVersion,
        type: SemVerIncrementType.explicit,
        explicitVersion: options.targetVersion,
        channel: options.channel,
      ));
    } catch (e) {
      findings.add(DryRunValidationFinding(
          stage: 'SemVer (Phase 6.1)', message: e.toString()));
    }

    // Stage 6.2: Changelog Plan
    AutomatedChangelogPlan? changelogPlan;
    try {
      changelogPlan =
          _changelogGenerator.planChangelog(AutomatedChangelogOptions(
        packageName: options.packageName,
        version: options.targetVersion,
      ));
    } catch (e) {
      findings.add(DryRunValidationFinding(
          stage: 'Changelog (Phase 6.2)', message: e.toString()));
    }

    // Stage 6.3: Git Plan
    GitReleasePlan? gitPlan;
    try {
      gitPlan = await _gitReleaseManager.planRelease(GitReleaseOptions(
        packageName: options.packageName,
        version: options.targetVersion,
      ));
    } catch (e) {
      findings.add(DryRunValidationFinding(
          stage: 'Git (Phase 6.3)', message: e.toString()));
    }

    // Stage 6.4: Release Notes Plan
    ReleaseNotesPlan? notesPlan;
    if (semVerPlan != null && changelogPlan != null && gitPlan != null) {
      try {
        final inputs = ReleaseNotesInputs(
          packageName: options.packageName,
          version: semVerPlan.targetVersion,
          changelogPlan: changelogPlan,
          gitPlan: gitPlan,
          channel: options.channel,
        );
        notesPlan = _notesGenerator.planReleaseNotes(inputs,
            options: ReleaseNotesOptions(outputDir: options.outputDir));
      } catch (e) {
        findings.add(DryRunValidationFinding(
            stage: 'Release Notes (Phase 6.4)', message: e.toString()));
      }
    } else {
      findings.add(const DryRunValidationFinding(
          stage: 'Release Notes (Phase 6.4)',
          message: 'Skipped due to upstream plan failure.'));
    }

    // Stage 6.5: GitHub Plan
    GitHubReleasePlan? gitHubPlan;
    try {
      gitHubPlan = _gitHubReleaseManager.planRelease(GitHubReleaseOptions(
        packageName: options.packageName,
        version: options.targetVersion,
        tagName: gitPlan?.tagName ?? 'v${options.targetVersion}',
        releaseTitle:
            'Flutter Package Studio ${options.packageName} v${options.targetVersion}',
        releaseBody: notesPlan != null
            ? _notesGenerator.renderMarkdown(notesPlan.inputs)
            : 'Release body.',
        channel: options.channel,
        isDraft: options.isDraft,
      ));
    } catch (e) {
      findings.add(DryRunValidationFinding(
          stage: 'GitHub (Phase 6.5)', message: e.toString()));
    }

    // Stage 6.5 Artifact Manifest Validation
    if (gitHubPlan != null && options.availableArtifacts != null) {
      final missingArtifacts = gitHubPlan.artifacts
          .where((art) => !options.availableArtifacts!.contains(art))
          .toList();
      if (missingArtifacts.isNotEmpty) {
        findings.add(DryRunValidationFinding(
          stage: 'Artifact Manifest (Phase 6.5)',
          message:
              'GitHub release plan expects artifact(s) [${missingArtifacts.join(', ')}] which are absent from artifact manifest.',
        ));
      }
    }

    // Stage 6.5 Existing GitHub Release Conflict Validation
    if (gitHubPlan != null && options.existingGitHubReleases != null) {
      if (options.existingGitHubReleases!.contains(gitHubPlan.tagName) &&
          !gitHubPlan.updateExisting) {
        findings.add(DryRunValidationFinding(
          stage: 'GitHub Release Conflict (Phase 6.5)',
          message:
              'Existing GitHub release found for tag "${gitHubPlan.tagName}". Overwrite intent not authorized.',
        ));
      }
    }

    // Cross-stage consistency validation
    if (changelogPlan != null &&
        semVerPlan != null &&
        changelogPlan.version != semVerPlan.targetVersion.toString()) {
      findings.add(DryRunValidationFinding(
        stage: 'Changelog Version Mismatch (Phase 6.2)',
        message:
            'Changelog version (${changelogPlan.version}) does not match SemVer target (${semVerPlan.targetVersion}).',
      ));
    }

    final isReady = findings.isEmpty;
    final summary = isReady
        ? 'RELEASE PLAN VALID: All upstream release phases verified successfully.'
        : 'RELEASE PLAN BLOCKED: ${findings.length} validation blocking issue(s) detected.';

    return ReleaseDryRunReport(
      packageName: options.packageName,
      semVerPlan: semVerPlan,
      changelogPlan: changelogPlan,
      gitPlan: gitPlan,
      notesPlan: notesPlan,
      gitHubPlan: gitHubPlan,
      findings: List.unmodifiable(findings),
      isReady: isReady,
      resultSummary: summary,
    );
  }
}
