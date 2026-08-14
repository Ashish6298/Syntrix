/// Protocol version constants and documentation for the FPS Remote Registry
/// Wire Protocol v1.
///
/// # FPS Registry Protocol v1
///
/// ## Overview
///
/// The FPS Registry Protocol defines a machine-readable JSON format for
/// advertising template catalog metadata from a remote HTTP endpoint. The
/// protocol is intentionally minimal and focused exclusively on **metadata
/// discovery** — it does not transfer executable code, hooks, or template file
/// contents.
///
/// ## Endpoint
///
/// Registries expose a single catalog endpoint:
///
///   GET <baseUrl>/catalog
///   Accept: application/json
///
/// ## Response Schema (Protocol v1)
///
/// ```json
/// {
///   "protocolVersion": "1",
///   "registryId": "my-registry",
///   "generatedAt": "2025-01-01T00:00:00.000Z",
///   "templates": [
///     {
///       "id": "my_template",
///       "version": "1.0.0",
///       "displayName": "My Template",
///       "description": "Short description of the template.",
///       "publisher": "Author Name",
///       "projectType": "flutter_package",
///       "category": "community",
///       "maturity": "stable",
///       "license": "MIT",
///       "tags": ["flutter", "widget"],
///       "capabilities": [],
///       "minimumDartSdk": ">=3.5.0 <4.0.0",
///       "minimumFlutterSdk": ">=3.22.0",
///       "supportedPlatforms": ["android", "ios", "web"],
///       "dependencies": [],
///       "documentationUrl": "https://example.com/docs",
///       "downloadCount": 1200,
///       "rating": 4.5
///     }
///   ]
/// }
/// ```
///
/// ## Security Notes
///
/// - Responses exceeding [maxResponseBytes] are rejected.
/// - `protocolVersion` must equal [supportedProtocolVersion].
/// - All string fields are sanitized; executable fields are rejected.
/// - Template IDs and versions are validated before entering the catalog.
/// - No credentials, tokens, or auth headers appear in catalog responses.
library;

/// The single protocol version string currently supported by this client.
const String supportedProtocolVersion = '1';

/// JSON key for the protocol version field in a registry response.
const String kProtocolVersion = 'protocolVersion';

/// JSON key for the registry identifier field.
const String kRegistryId = 'registryId';

/// JSON key for the ISO-8601 generation timestamp.
const String kGeneratedAt = 'generatedAt';

/// JSON key for the templates array.
const String kTemplates = 'templates';

// ── Template record field keys ─────────────────────────────────────────────

/// Template unique identifier.
const String kId = 'id';

/// Template semantic version.
const String kVersion = 'version';

/// Human-readable display name.
const String kDisplayName = 'displayName';

/// Short description.
const String kDescription = 'description';

/// Publisher or author.
const String kPublisher = 'publisher';

/// Project archetype key.
const String kProjectType = 'projectType';

/// Category key (`community`, `local`, `builtin`).
const String kCategory = 'category';

/// Maturity level key.
const String kMaturity = 'maturity';

/// License identifier.
const String kLicense = 'license';

/// Tags array.
const String kTags = 'tags';

/// Capabilities array.
const String kCapabilities = 'capabilities';

/// Minimum Dart SDK constraint.
const String kMinimumDartSdk = 'minimumDartSdk';

/// Minimum Flutter SDK constraint (optional).
const String kMinimumFlutterSdk = 'minimumFlutterSdk';

/// Supported platforms array.
const String kSupportedPlatforms = 'supportedPlatforms';

/// Template dependency IDs.
const String kDependencies = 'dependencies';

/// Documentation URL.
const String kDocumentationUrl = 'documentationUrl';

/// Download count (informational).
const String kDownloadCount = 'downloadCount';

/// Star rating (0.0–5.0).
const String kRating = 'rating';

/// Allowed project type values in remote metadata.
const Set<String> allowedProjectTypes = {
  'flutter_package',
  'dart_package',
  'flutter_plugin',
  'dart_cli',
};

/// Allowed category values in remote metadata.
///
/// Builtin is intentionally excluded: remote registries cannot claim
/// builtin status.
const Set<String> allowedRemoteCategories = {
  'community',
  'local',
};

/// Allowed maturity level values.
const Set<String> allowedMaturityValues = {
  'stable',
  'preview',
  'experimental',
  'deprecated',
};
