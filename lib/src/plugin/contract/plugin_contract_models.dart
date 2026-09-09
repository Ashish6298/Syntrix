import 'package:syntrix/src/error/exceptions.dart';
import 'package:syntrix/src/release/versioning/semver_models.dart';

/// Closed enumerable set of recognized plugin capabilities.
enum PluginCapability {
  commandContribution,
  serviceContribution,
  validationContribution,
  releaseWorkflowContribution,
  packageAnalysisContribution,
  lifecycleManagement,
}

/// Full set of pre-execution and execution lifecycle states.
enum PluginLifecycleState {
  // Pre-execution states (Phase 7.1 baseline)
  discovered,
  validated,
  incompatible,
  disabled,

  // Genuine Phase 7.7 additive execution & failure states
  registered,
  initialized,
  active,
  stopping,
  inactive,
  invalid,
  blocked,
  initializationFailed,
  shutdownFailed,
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

/// Supported property data types in configuration schemas.
enum ConfigPropertyType {
  string,
  number,
  boolean,
  map,
  list,
}

/// Single declared configuration property in a plugin schema.
class ConfigurationProperty {
  final String key;
  final ConfigPropertyType type;
  final bool isRequired;
  final bool isSecret;
  final String? description;

  const ConfigurationProperty({
    required this.key,
    required this.type,
    this.isRequired = false,
    this.isSecret = false,
    this.description,
  });

  Map<String, dynamic> toJson() => {
        'key': key,
        'type': type.name,
        'isRequired': isRequired,
        'isSecret': isSecret,
        if (description != null) 'description': description,
      };

  factory ConfigurationProperty.fromJson(Map<String, dynamic> json) {
    final key = json['key'] as String?;
    final typeStr = json['type'] as String?;
    if (key == null || key.trim().isEmpty || typeStr == null) {
      throw PluginContractException(
          'ConfigurationProperty requires valid "key" and "type".');
    }
    final typeMatch =
        ConfigPropertyType.values.where((t) => t.name == typeStr.trim());
    if (typeMatch.isEmpty) {
      throw PluginContractException('Invalid ConfigPropertyType "$typeStr".');
    }
    return ConfigurationProperty(
      key: key.trim(),
      type: typeMatch.first,
      isRequired: json['isRequired'] as bool? ?? false,
      isSecret: json['isSecret'] as bool? ?? false,
      description: json['description'] as String?,
    );
  }
}

/// Declared configuration schema for a plugin.
class ConfigurationSchema {
  final List<ConfigurationProperty> properties;

  ConfigurationSchema({List<ConfigurationProperty>? properties})
      : properties = List.unmodifiable(properties ?? const []) {
    final keys = <String>{};
    for (final p in this.properties) {
      if (keys.contains(p.key)) {
        throw PluginContractException(
            'Duplicate configuration property key "${p.key}" in schema.');
      }
      keys.add(p.key);
    }
  }

  Map<String, dynamic> toJson() => {
        'properties': properties.map((p) => p.toJson()).toList(),
      };

  factory ConfigurationSchema.fromJson(Map<String, dynamic> json) {
    final rawProps = json['properties'] as List<dynamic>?;
    final list = <ConfigurationProperty>[];
    if (rawProps != null) {
      for (final p in rawProps) {
        if (p is Map<String, dynamic>) {
          list.add(ConfigurationProperty.fromJson(p));
        }
      }
    }
    return ConfigurationSchema(properties: list);
  }
}

/// Declared plugin dependency requirement value object.
class PluginDependency {
  final String name;
  final String versionConstraint;

  PluginDependency({
    required this.name,
    required this.versionConstraint,
  }) {
    if (name.trim().isEmpty) {
      throw PluginContractException('Dependency name must not be empty.');
    }
    if (versionConstraint.trim().isEmpty) {
      throw PluginContractException(
          'Dependency version constraint must not be empty.');
    }
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'versionConstraint': versionConstraint,
      };

  factory PluginDependency.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String?;
    final ver = json['versionConstraint'] as String?;
    if (name == null || ver == null) {
      throw PluginContractException(
          'PluginDependency requires name and versionConstraint.');
    }
    return PluginDependency(name: name, versionConstraint: ver);
  }
}

/// Declared plugin security requirements value object.
class SecurityRequirements {
  final List<String> permissions;
  final bool sandboxRequired;

  const SecurityRequirements({
    this.permissions = const [],
    this.sandboxRequired = true,
  });

  Map<String, dynamic> toJson() => {
        'permissions': permissions,
        'sandboxRequired': sandboxRequired,
      };

  factory SecurityRequirements.fromJson(Map<String, dynamic> json) {
    final rawPerms = json['permissions'] as List<dynamic>?;
    final perms = rawPerms?.map((e) => e.toString()).toList() ?? const [];
    return SecurityRequirements(
      permissions: List.unmodifiable(perms),
      sandboxRequired: json['sandboxRequired'] as bool? ?? true,
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

  // Genuine Phase 7.5 extended fields (Backward-compatible optional fields)
  final String? entryPoint;
  final List<PluginDependency> dependencies;
  final ConfigurationSchema configSchema;
  final SecurityRequirements securityRequirements;

  PluginManifest({
    required this.id,
    required this.name,
    required this.description,
    required this.version,
    required this.author,
    required this.apiVersion,
    required this.capabilities,
    required this.compatibility,
    this.state = PluginLifecycleState.discovered,
    this.entryPoint,
    List<PluginDependency>? dependencies,
    ConfigurationSchema? configSchema,
    SecurityRequirements? securityRequirements,
  })  : dependencies = List.unmodifiable(dependencies ?? const []),
        configSchema = configSchema ?? ConfigurationSchema(),
        securityRequirements =
            securityRequirements ?? const SecurityRequirements() {
    if (entryPoint != null && entryPoint!.trim().isEmpty) {
      throw PluginContractException(
          'entryPoint must not be empty string when provided.');
    }
    for (final dep in this.dependencies) {
      if (dep.name == id.value) {
        throw PluginContractException(
            'Self-referential dependency: plugin cannot depend on itself "${id.value}".');
      }
    }
  }

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
        if (entryPoint != null) 'entryPoint': entryPoint,
        if (dependencies.isNotEmpty)
          'dependencies': dependencies.map((d) => d.toJson()).toList(),
        if (configSchema.properties.isNotEmpty)
          'configSchema': configSchema.toJson(),
        'securityRequirements': securityRequirements.toJson(),
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

    // Extended Phase 7.5 fields
    final entryPoint = json['entryPoint'] as String?;
    final rawDeps = json['dependencies'] as List<dynamic>?;
    final depsList = <PluginDependency>[];
    if (rawDeps != null) {
      for (final d in rawDeps) {
        if (d is Map<String, dynamic>) {
          depsList.add(PluginDependency.fromJson(d));
        }
      }
    }
    final rawSchema = json['configSchema'] as Map<String, dynamic>?;
    final configSchema = rawSchema != null
        ? ConfigurationSchema.fromJson(rawSchema)
        : ConfigurationSchema();

    final rawSec = json['securityRequirements'] as Map<String, dynamic>?;
    final secReq = rawSec != null
        ? SecurityRequirements.fromJson(rawSec)
        : const SecurityRequirements();

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
      entryPoint: entryPoint,
      dependencies: depsList,
      configSchema: configSchema,
      securityRequirements: secReq,
    );
  }
}
