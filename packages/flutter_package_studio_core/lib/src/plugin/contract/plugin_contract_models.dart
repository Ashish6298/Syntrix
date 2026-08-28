import 'package:flutter_package_studio_core/src/error/exceptions.dart';
import 'package:flutter_package_studio_core/src/release/versioning/semver_models.dart';

/// Closed enumerable set of recognized plugin capabilities.
enum PluginCapability {
  releasePlanning,
  versionManagement,
  changelogGeneration,
  securityAudit,
  artifactGeneration,
  customValidation,
}

/// Static lifecycle states determinable statically without code execution.
enum PluginLifecycleState {
  discovered,
  validated,
  incompatible,
  disabled,
}

/// Validated canonical plugin identifier value object.
class PluginId {
  final String value;

  PluginId(this.value) {
    final clean = value.trim();
    final regex = RegExp(r'^[a-z][a-z0-9_]{2,63}$');
    if (!regex.hasMatch(clean)) {
      throw PluginContractException(
          'Invalid Plugin ID "$value": must be lowercase alphanumeric/underscore, start with a letter, length 3-64.');
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is PluginId && other.value == value);

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}

/// Sanitized display name value object.
class PluginName {
  final String value;

  PluginName(this.value) {
    if (value.trim().isEmpty) {
      throw PluginContractException('Plugin name must not be empty.');
    }
  }

  @override
  String toString() => value;
}

/// Sanitized display description value object.
class PluginDescription {
  final String value;

  PluginDescription(this.value) {
    if (value.trim().isEmpty) {
      throw PluginContractException('Plugin description must not be empty.');
    }
  }

  @override
  String toString() => value;
}

/// Immutable author / maintainer metadata value object.
class PluginAuthor {
  final String name;
  final String? email;
  final String? url;

  const PluginAuthor({
    required this.name,
    this.email,
    this.url,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        if (email != null) 'email': email,
        if (url != null) 'url': url,
      };

  factory PluginAuthor.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String?;
    if (name == null || name.trim().isEmpty) {
      throw PluginContractException('Plugin author name is required.');
    }
    return PluginAuthor(
      name: name,
      email: json['email'] as String?,
      url: json['url'] as String?,
    );
  }
}

/// API compatibility range constraints value object.
class PluginCompatibility {
  final String minApiVersion;
  final String? maxApiVersion;

  PluginCompatibility({
    required this.minApiVersion,
    this.maxApiVersion,
  }) {
    final minVer = SemVer.parse(minApiVersion);
    if (maxApiVersion != null) {
      final maxVer = SemVer.parse(maxApiVersion!);
      if (minVer.compareTo(maxVer) > 0) {
        throw PluginContractException(
            'Inconsistent compatibility range: minApiVersion ($minApiVersion) cannot be greater than maxApiVersion ($maxApiVersion).');
      }
    }
  }

  Map<String, dynamic> toJson() => {
        'minApiVersion': minApiVersion,
        if (maxApiVersion != null) 'maxApiVersion': maxApiVersion,
      };

  factory PluginCompatibility.fromJson(Map<String, dynamic> json) {
    final min = json['minApiVersion'] as String?;
    if (min == null || min.trim().isEmpty) {
      throw PluginContractException('minApiVersion is required.');
    }
    return PluginCompatibility(
      minApiVersion: min,
      maxApiVersion: json['maxApiVersion'] as String?,
    );
  }
}

/// Top-level immutable manifest object declaring a plugin's identity, metadata, and capabilities.
class PluginManifest {
  final PluginId id;
  final PluginName name;
  final PluginDescription description;
  final SemVer version;
  final PluginAuthor author;
  final String apiVersion;
  final Set<PluginCapability> capabilities;
  final PluginCompatibility compatibility;
  final PluginLifecycleState state;

  const PluginManifest({
    required this.id,
    required this.name,
    required this.description,
    required this.version,
    required this.author,
    required this.apiVersion,
    required this.capabilities,
    required this.compatibility,
    this.state = PluginLifecycleState.discovered,
  });

  Map<String, dynamic> toJson() => {
        'id': id.value,
        'name': name.value,
        'description': description.value,
        'version': version.toString(),
        'author': author.toJson(),
        'apiVersion': apiVersion,
        'capabilities': capabilities.map((c) => c.name).toList()..sort(),
        'compatibility': compatibility.toJson(),
        'state': state.name,
      };

  factory PluginManifest.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'] as String?;
    final rawName = json['name'] as String?;
    final rawDesc = json['description'] as String?;
    final rawVer = json['version'] as String?;
    final rawAuthor = json['author'] as Map<String, dynamic>?;
    final rawApiVer = json['apiVersion'] as String?;
    final rawCaps = json['capabilities'] as List<dynamic>?;
    final rawComp = json['compatibility'] as Map<String, dynamic>?;
    final rawState = json['state'] as String?;

    if (rawId == null ||
        rawName == null ||
        rawDesc == null ||
        rawVer == null ||
        rawAuthor == null ||
        rawApiVer == null ||
        rawComp == null) {
      throw PluginContractException(
          'Malformed manifest: missing required fields.');
    }

    final capsSet = <PluginCapability>{};
    if (rawCaps != null) {
      for (final item in rawCaps) {
        final match =
            PluginCapability.values.where((c) => c.name == item.toString());
        if (match.isNotEmpty) {
          capsSet.add(match.first);
        } else {
          throw PluginContractException('Unrecognized capability "$item".');
        }
      }
    }

    PluginLifecycleState stateEnum = PluginLifecycleState.discovered;
    if (rawState != null) {
      final match =
          PluginLifecycleState.values.where((s) => s.name == rawState);
      if (match.isNotEmpty) {
        stateEnum = match.first;
      }
    }

    return PluginManifest(
      id: PluginId(rawId),
      name: PluginName(rawName),
      description: PluginDescription(rawDesc),
      version: SemVer.parse(rawVer),
      author: PluginAuthor.fromJson(rawAuthor),
      apiVersion: rawApiVer,
      capabilities: Set.unmodifiable(capsSet),
      compatibility: PluginCompatibility.fromJson(rawComp),
      state: stateEnum,
    );
  }
}
