/// Flutter Package Studio — Remote Template Marketplace subsystem.
///
/// This library provides the complete remote registry / marketplace
/// infrastructure for Phase 2.3. It extends the local catalog (Phase 2.2)
/// with secure, provider-based remote template discovery without introducing
/// real network dependencies into the core package — all network behavior is
/// injected via [RegistryTransport].
///
/// ## Key Abstractions
///
/// - [RemoteRegistryOptions] — immutable, validated registry configuration.
/// - [RegistryTransport] / [MockRegistryTransport] — injectable HTTP interface.
/// - [RemoteRegistryClient] — fetch, parse, map errors; bounded retries.
/// - [RegistryResponseParser] — JSON → [RemoteRegistryPayload]; protocol guard.
/// - [RemoteMetadataValidator] — security boundary; rejects malformed records.
/// - [RegistryMetadataCache] — TTL in-memory cache; stale/fresh/offline.
/// - [RegistryManager] — lifecycle, refresh, conflict resolution, status.
/// - [RemoteCatalogProvider] — [TemplateCatalogProvider] adapter for discovery.
/// - [RegistrySource] — provenance tracking.
/// - [RegistryStatus] — health status without credential exposure.
///
/// ## Security Model
///
/// Remote data is treated as untrusted at every layer:
/// 1. [RegistryResponseParser] enforces protocol version.
/// 2. [RemoteMetadataValidator] validates every field; rejects bad IDs,
///    versions, URLs, project types, and disallowed categories.
/// 3. Remote registries cannot claim `builtin` category.
/// 4. Credentials are never stored in cache, catalog entries, or logs.
/// 5. Registry URLs must use HTTPS and must not target private IP ranges.
/// 6. Response size is bounded to prevent memory exhaustion.
/// 7. No executable content is fetched or run from remote metadata.
///
/// ## Conflict Resolution
///
/// When the same `id@version` appears in multiple sources:
/// - Local (builtin) providers always win over remote.
/// - Among remote registries, first-registered wins.
/// This strategy is deterministic and documented.
library;

export 'http_registry_transport.dart'
    show
        RegistryTransport,
        TransportResponse,
        MockRegistryTransport,
        MutableMockRegistryTransport;
export 'registry_manager.dart'
    show RegistryManager, RegistryMutationPlan, RegistryRefreshResult;
export 'registry_metadata_cache.dart' show RegistryMetadataCache;
export 'registry_protocol.dart'
    show supportedProtocolVersion, allowedProjectTypes, allowedRemoteCategories;
export 'registry_response_parser.dart' show RegistryResponseParser;
export 'registry_source.dart' show RegistrySource;
export 'registry_status.dart' show RegistryStatus, RegistryHealthState;
export 'remote_catalog_provider.dart' show RemoteCatalogProvider, CatalogSource;
export 'remote_metadata_validator.dart'
    show RemoteMetadataValidator, MetadataValidationResult;
export 'remote_registry_client.dart'
    show RemoteRegistryClient, RegistryFetchResult;
export 'remote_registry_options.dart'
    show RemoteRegistryOptions, RegistryAuthMode, RegistryCachePolicy;
export 'remote_template_record.dart'
    show RemoteTemplateRecord, RemoteRegistryPayload;
