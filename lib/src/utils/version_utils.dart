/// Version utility class for parsing, validating, and comparing semantic versions (SemVer).
class VersionUtils {
  /// Regular expression for validating semantic versioning.
  static final RegExp _semVerRegExp = RegExp(
    r'^v?(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)'
    r'(?:-((?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?'
    r'(?:\+([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?$',
  );

  /// Returns `true` if the given [version] string is a valid SemVer format.
  static bool isValid(String version) {
    return _semVerRegExp.hasMatch(version.trim());
  }

  /// Compares two version strings [versionA] and [versionB].
  ///
  /// Returns:
  /// - A value greater than 0 if [versionA] > [versionB]
  /// - A value less than 0 if [versionA] < [versionB]
  /// - 0 if [versionA] == [versionB]
  ///
  /// Throws an [ArgumentError] if either version is invalid.
  static int compare(String versionA, String versionB) {
    if (!isValid(versionA)) {
      throw ArgumentError('Invalid version format: "$versionA"');
    }
    if (!isValid(versionB)) {
      throw ArgumentError('Invalid version format: "$versionB"');
    }

    final cleanA = versionA.trim().replaceAll(RegExp(r'^v'), '');
    final cleanB = versionB.trim().replaceAll(RegExp(r'^v'), '');

    // Split pre-release and build metadata
    final partsA = _splitVersion(cleanA);
    final partsB = _splitVersion(cleanB);

    // Compare core versions (Major.Minor.Patch)
    for (var i = 0; i < 3; i++) {
      final diff = partsA.core[i].compareTo(partsB.core[i]);
      if (diff != 0) return diff;
    }

    // Compare pre-release tags
    return _comparePreRelease(partsA.preRelease, partsB.preRelease);
  }

  static _VersionParts _splitVersion(String version) {
    final buildIndex = version.indexOf('+');
    final coreAndPre =
        buildIndex == -1 ? version : version.substring(0, buildIndex);

    final preIndex = coreAndPre.indexOf('-');
    final coreStr =
        preIndex == -1 ? coreAndPre : coreAndPre.substring(0, preIndex);
    final preStr = preIndex == -1 ? null : coreAndPre.substring(preIndex + 1);

    final coreParts = coreStr.split('.').map(int.parse).toList();
    while (coreParts.length < 3) {
      coreParts.add(0);
    }

    return _VersionParts(coreParts, preStr);
  }

  static int _comparePreRelease(String? preA, String? preB) {
    // A version without pre-release is always higher than one with pre-release.
    if (preA == null && preB != null) return 1;
    if (preA != null && preB == null) return -1;
    if (preA == null && preB == null) return 0;

    final identifiersA = preA!.split('.');
    final identifiersB = preB!.split('.');

    final minLen = identifiersA.length < identifiersB.length
        ? identifiersA.length
        : identifiersB.length;

    for (var i = 0; i < minLen; i++) {
      final idA = identifiersA[i];
      final idB = identifiersB[i];

      final valA = int.tryParse(idA);
      final valB = int.tryParse(idB);

      if (valA != null && valB != null) {
        final diff = valA.compareTo(valB);
        if (diff != 0) return diff;
      } else if (valA == null && valB == null) {
        final diff = idA.compareTo(idB);
        if (diff != 0) return diff;
      } else {
        // Numeric identifiers always have lower precedence than non-numeric identifiers.
        return valA != null ? -1 : 1;
      }
    }

    return identifiersA.length.compareTo(identifiersB.length);
  }
}

class _VersionParts {
  final List<int> core;
  final String? preRelease;

  _VersionParts(this.core, this.preRelease);
}
