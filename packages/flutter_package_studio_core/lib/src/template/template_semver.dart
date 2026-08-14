import 'package:flutter_package_studio_core/src/error/exceptions.dart';

/// Immutable representation of a Semantic Version (e.g. 1.2.3 or 1.0.0-alpha).
class TemplateSemVer implements Comparable<TemplateSemVer> {
  final int major;
  final int minor;
  final int patch;
  final String? prerelease;

  const TemplateSemVer(this.major, this.minor, this.patch, [this.prerelease]);

  /// Parses a semver string like `1.2.3` or `2.0.0-beta.1`.
  factory TemplateSemVer.parse(String versionStr) {
    final trimmed = versionStr.trim();
    if (trimmed.isEmpty) {
      throw TemplateException('Empty version string.');
    }

    final parts = trimmed.split('-');
    final core = parts[0].split('.');
    if (core.length != 3) {
      throw TemplateException(
          'Invalid semver format "$versionStr". Expected "major.minor.patch".');
    }

    final maj = int.tryParse(core[0]);
    final min = int.tryParse(core[1]);
    final pat = int.tryParse(core[2]);

    if (maj == null || min == null || pat == null) {
      throw TemplateException('Invalid semver core numbers in "$versionStr".');
    }

    final pre = parts.length > 1 ? parts.sublist(1).join('-') : null;
    return TemplateSemVer(maj, min, pat, pre);
  }

  /// Evaluates whether this version satisfies constraint string (e.g. `>=1.0.0 <2.0.0` or `^1.0.0`).
  bool satisfies(String constraint) {
    final c = constraint.trim();
    if (c.isEmpty || c == '*') return true;

    // Handle space-separated compound range constraints (e.g. ">=1.0.0 <2.0.0")
    if (c.contains(' ')) {
      final parts = c.split(' ').where((p) => p.trim().isNotEmpty).toList();
      return parts.every((p) => _satisfiesSingle(p.trim()));
    }

    return _satisfiesSingle(c);
  }

  bool _satisfiesSingle(String c) {
    if (c.startsWith('^')) {
      final base = TemplateSemVer.parse(c.substring(1));
      return this >= base && major == base.major;
    }

    if (c.startsWith('>=')) {
      final base = TemplateSemVer.parse(c.substring(2));
      return this >= base;
    }

    if (c.startsWith('>')) {
      final base = TemplateSemVer.parse(c.substring(1));
      return this > base;
    }

    if (c.startsWith('<=')) {
      final base = TemplateSemVer.parse(c.substring(2));
      return this <= base;
    }

    if (c.startsWith('<')) {
      final base = TemplateSemVer.parse(c.substring(1));
      return this < base;
    }

    if (c.startsWith('==') || c.startsWith('=')) {
      final clean = c.replaceAll('=', '').trim();
      final base = TemplateSemVer.parse(clean);
      return this == base;
    }

    try {
      final base = TemplateSemVer.parse(c);
      return this == base;
    } catch (_) {
      return true;
    }
  }

  @override
  int compareTo(TemplateSemVer other) {
    if (major != other.major) return major.compareTo(other.major);
    if (minor != other.minor) return minor.compareTo(other.minor);
    if (patch != other.patch) return patch.compareTo(other.patch);

    if (prerelease == null && other.prerelease != null) return 1;
    if (prerelease != null && other.prerelease == null) return -1;
    if (prerelease != null && other.prerelease != null) {
      return prerelease!.compareTo(other.prerelease!);
    }
    return 0;
  }

  bool operator <(TemplateSemVer other) => compareTo(other) < 0;
  bool operator <=(TemplateSemVer other) => compareTo(other) <= 0;
  bool operator >(TemplateSemVer other) => compareTo(other) > 0;
  bool operator >=(TemplateSemVer other) => compareTo(other) >= 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TemplateSemVer &&
          major == other.major &&
          minor == other.minor &&
          patch == other.patch &&
          prerelease == other.prerelease;

  @override
  int get hashCode => Object.hash(major, minor, patch, prerelease);

  @override
  String toString() => prerelease != null
      ? '$major.$minor.$patch-$prerelease'
      : '$major.$minor.$patch';
}
