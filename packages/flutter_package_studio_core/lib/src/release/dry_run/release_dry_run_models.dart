import 'package:flutter_package_studio_core/src/release/changelog/automated_changelog_models.dart';
import 'package:flutter_package_studio_core/src/release/git/git_release_models.dart';
import 'package:flutter_package_studio_core/src/release/github/github_release_models.dart';
import 'package:flutter_package_studio_core/src/release/notes_generator/release_notes_models.dart';
import 'package:flutter_package_studio_core/src/release/versioning/semver_models.dart';

/// Individual finding raised during dry run pipeline validation.
class DryRunValidationFinding {
  final String stage;
  final String message;
  final bool isBlocking;

  const DryRunValidationFinding({
    required this.stage,
    required this.message,
    this.isBlocking = true,
  });

  Map<String, dynamic> toJson() => {
        'stage': stage,
        'message': message,
        'isBlocking': isBlocking,
      };
}

/// Options configuring release dry run composition.
class ReleaseDryRunOptions {
  final String packageName;
  final String currentVersion;
  final String targetVersion;
  final String channel;
  final bool isDraft;
  final String outputDir;
  final List<String>? availableArtifacts;
  final List<String>? existingGitHubReleases;
  final String ownerRepo;

  const ReleaseDryRunOptions({
    required this.packageName,
    this.currentVersion = '1.0.0',
    this.targetVersion = '1.1.0',
    this.channel = 'stable',
    this.isDraft = false,
    this.outputDir = 'doc/release',
    this.availableArtifacts,
    this.existingGitHubReleases,
    this.ownerRepo = 'Syntrix/package',
  });

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'currentVersion': currentVersion,
        'targetVersion': targetVersion,
        'channel': channel,
        'isDraft': isDraft,
        'outputDir': outputDir,
        'availableArtifacts': availableArtifacts,
        'existingGitHubReleases': existingGitHubReleases,
        'ownerRepo': ownerRepo,
      };
}

/// Unified end-to-end dry run report object summarizing all release planning stages.
class ReleaseDryRunReport {
  final String packageName;
  final SemVerPlan? semVerPlan;
  final AutomatedChangelogPlan? changelogPlan;
  final GitReleasePlan? gitPlan;
  final ReleaseNotesPlan? notesPlan;
  final GitHubReleasePlan? gitHubPlan;
  final List<DryRunValidationFinding> findings;
  final bool isReady;
  final String resultSummary;

  const ReleaseDryRunReport({
    required this.packageName,
    this.semVerPlan,
    this.changelogPlan,
    this.gitPlan,
    this.notesPlan,
    this.gitHubPlan,
    required this.findings,
    required this.isReady,
    required this.resultSummary,
  });

  String toFormattedText() {
    final buf = StringBuffer();
    buf.writeln('RELEASE DRY RUN');
    buf.writeln('===============');

    final curVer = semVerPlan?.currentVersion.toString() ?? 'N/A';
    final tgtVer = semVerPlan?.targetVersion.toString() ?? 'N/A';
    buf.writeln('Version: $curVer -> $tgtVer');

    final secCount = changelogPlan?.sections.length ?? 0;
    buf.writeln('Changelog: CHANGELOG.md ($secCount sections)');

    final tag = gitPlan?.tagName ?? 'N/A';
    final branch = gitPlan?.branchName ?? 'N/A';
    final cleanStr = (gitPlan?.isClean ?? false) ? 'CLEAN ✓' : 'DIRTY ✗';
    buf.writeln('Git: $tag on $branch ($cleanStr)');

    final arts = gitHubPlan?.artifacts.join(', ') ?? 'N/A';
    buf.writeln('Artifacts: $arts');

    final title = gitHubPlan?.releaseTitle ?? 'N/A';
    final channel = gitHubPlan?.isPrerelease ?? false ? 'prerelease' : 'stable';
    final draftStr = gitHubPlan?.isDraft ?? false ? 'true' : 'false';
    buf.writeln('GitHub: $title ($channel, draft: $draftStr)');

    buf.writeln('Publishing: Status: ${isReady ? "READY" : "NOT READY"}');
    buf.writeln();

    if (isReady) {
      buf.writeln('Result: RELEASE PLAN VALID');
    } else {
      buf.writeln('Result: RELEASE PLAN BLOCKED');
      for (final f in findings) {
        buf.writeln('  - [${f.stage}] ${f.message}');
      }
    }

    return buf.toString();
  }

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'isReady': isReady,
        'resultSummary': resultSummary,
        'semVerPlan': semVerPlan?.toJson(),
        'changelogPlan': changelogPlan?.toJson(),
        'gitPlan': gitPlan?.toJson(),
        'notesPlan': notesPlan?.toJson(),
        'gitHubPlan': gitHubPlan?.toJson(),
        'findings': findings.map((f) => f.toJson()).toList(),
      };
}
