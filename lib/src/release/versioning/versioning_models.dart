/// Type of semantic version bump requested.
enum VersionChangeType {
  patch,
  minor,
  major,
  explicit,
}

/// Structured entry for CHANGELOG.md.
class ChangelogEntry {
  final String version;
  final String date;
  final List<String> changes;

  const ChangelogEntry({
    required this.version,
    required this.date,
    required this.changes,
  });

  String toMarkdown() {
    final buf = StringBuffer();
    buf.writeln('## [$version] - $date');
    buf.writeln();
    for (final c in changes) {
      buf.writeln('- $c');
    }
    return buf.toString();
  }

  Map<String, dynamic> toJson() => {
        'version': version,
        'date': date,
        'changes': changes,
      };
}

/// Options configuring version and changelog management.
class VersionOptions {
  final String packageName;
  final String currentVersion;
  final VersionChangeType type;
  final String? explicitVersion;
  final String changelogPath;

  const VersionOptions({
    required this.packageName,
    this.currentVersion = '1.0.0',
    this.type = VersionChangeType.patch,
    this.explicitVersion,
    this.changelogPath = 'CHANGELOG.md',
  });

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'currentVersion': currentVersion,
        'type': type.name,
        if (explicitVersion != null) 'explicitVersion': explicitVersion,
        'changelogPath': changelogPath,
      };
}

/// Preview plan of version and changelog modifications.
class VersionPlan {
  final String packageName;
  final String currentVersion;
  final String targetVersion;
  final VersionChangeType type;
  final ChangelogEntry changelogEntry;

  const VersionPlan({
    required this.packageName,
    required this.currentVersion,
    required this.targetVersion,
    required this.type,
    required this.changelogEntry,
  });

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'currentVersion': currentVersion,
        'targetVersion': targetVersion,
        'type': type.name,
        'changelogEntry': changelogEntry.toJson(),
      };
}

/// Result of executing version and changelog modifications.
class VersionResult {
  final String packageName;
  final String previousVersion;
  final String newVersion;
  final bool isApplied;
  final String changelogContent;

  const VersionResult({
    required this.packageName,
    required this.previousVersion,
    required this.newVersion,
    required this.isApplied,
    required this.changelogContent,
  });

  String toMarkdown() {
    final buf = StringBuffer();
    buf.writeln('# Version & Changelog Report: $packageName');
    buf.writeln();
    buf.writeln('**Previous Version**: $previousVersion');
    buf.writeln('**New Version**: $newVersion');
    buf.writeln(
        '**Status**: ${isApplied ? "APPLIED ✓" : "PREVIEW-ONLY (NOT APPLIED)"}');
    buf.writeln();
    buf.writeln('### Changelog Entry');
    buf.writeln();
    buf.writeln(changelogContent);
    return buf.toString();
  }

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'previousVersion': previousVersion,
        'newVersion': newVersion,
        'isApplied': isApplied,
        'changelogContent': changelogContent,
      };
}
