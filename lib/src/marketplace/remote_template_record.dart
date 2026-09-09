/// A single template metadata record as received from a remote registry.
///
/// [RemoteTemplateRecord] is the deserialized representation of one element
/// in the `templates` array of a registry response. All string fields have
/// been stripped of leading/trailing whitespace but have NOT yet been validated
/// for semantic correctness — validation occurs separately in
/// [RemoteMetadataValidator].
class RemoteTemplateRecord {
  /// Template unique identifier.
  final String id;

  /// Semantic version string.
  final String version;

  /// Human-readable display name.
  final String displayName;

  /// Short description.
  final String description;

  /// Publisher or author name.
  final String publisher;

  /// Project archetype (`flutter_package`, `dart_package`, etc.).
  final String projectType;

  /// Catalog category string (`community`, `local`).
  final String category;

  /// Maturity level (`stable`, `preview`, `experimental`, `deprecated`).
  final String? maturity;

  /// SPDX license identifier (e.g. `MIT`, `Apache-2.0`).
  final String? license;

  /// Discovery tags.
  final List<String> tags;

  /// Declared capabilities.
  final List<String> capabilities;

  /// Minimum Dart SDK constraint string.
  final String minimumDartSdk;

  /// Minimum Flutter SDK constraint string (optional).
  final String? minimumFlutterSdk;

  /// Supported platform identifiers.
  final List<String> supportedPlatforms;

  /// Template dependency IDs.
  final List<String> dependencies;

  /// Documentation URL string (may be empty).
  final String? documentationUrl;

  /// Informational download count.
  final int downloadCount;

  /// Star rating (0.0–5.0).
  final double rating;

  /// Creates a [RemoteTemplateRecord].
  const RemoteTemplateRecord({
    required this.id,
    required this.version,
    required this.displayName,
    required this.description,
    required this.publisher,
    required this.projectType,
    required this.category,
    this.maturity,
    this.license,
    this.tags = const [],
    this.capabilities = const [],
    required this.minimumDartSdk,
    this.minimumFlutterSdk,
    this.supportedPlatforms = const [],
    this.dependencies = const [],
    this.documentationUrl,
    this.downloadCount = 0,
    this.rating = 0.0,
  });

  @override
  String toString() =>
      'RemoteTemplateRecord(id: $id, version: $version, projectType: $projectType)';
}

/// Parsed, top-level payload from a remote registry response.
///
/// Produced by [RegistryResponseParser] after JSON parsing and schema-version
/// validation. Individual [RemoteTemplateRecord] entries are NOT yet validated
/// at this point.
class RemoteRegistryPayload {
  /// Protocol version string from the response (must equal `"1"`).
  final String protocolVersion;

  /// Registry ID as declared in the response.
  final String registryId;

  /// Timestamp when the response was generated on the server.
  final DateTime? generatedAt;

  /// Raw deserialized template records.
  final List<RemoteTemplateRecord> templates;

  /// Creates a [RemoteRegistryPayload].
  const RemoteRegistryPayload({
    required this.protocolVersion,
    required this.registryId,
    required this.templates,
    this.generatedAt,
  });

  @override
  String toString() =>
      'RemoteRegistryPayload(registry: $registryId, proto: $protocolVersion, '
      'templates: ${templates.length})';
}
