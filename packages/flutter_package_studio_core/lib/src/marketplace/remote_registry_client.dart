import 'package:flutter_package_studio_core/src/error/exceptions.dart';
import 'package:flutter_package_studio_core/src/logging/logger.dart';
import 'package:flutter_package_studio_core/src/marketplace/http_registry_transport.dart';
import 'package:flutter_package_studio_core/src/marketplace/registry_response_parser.dart';
import 'package:flutter_package_studio_core/src/marketplace/registry_source.dart';
import 'package:flutter_package_studio_core/src/marketplace/remote_registry_options.dart';
import 'package:flutter_package_studio_core/src/marketplace/remote_template_record.dart';

/// Result of a [RemoteRegistryClient.fetchCatalog] call.
class RegistryFetchResult {
  /// The parsed payload (null on failure).
  final RemoteRegistryPayload? payload;

  /// Provenance information for entries in this fetch.
  final RegistrySource source;

  /// Whether the fetch succeeded without errors.
  final bool succeeded;

  /// Error message if the fetch failed (safe, no credentials).
  final String? errorMessage;

  const RegistryFetchResult._({
    required this.source,
    required this.succeeded,
    this.payload,
    this.errorMessage,
  });

  factory RegistryFetchResult.success(
          RemoteRegistryPayload payload, RegistrySource source) =>
      RegistryFetchResult._(payload: payload, source: source, succeeded: true);

  factory RegistryFetchResult.failure(RegistrySource source, String error) =>
      RegistryFetchResult._(
          source: source, succeeded: false, errorMessage: error);
}

/// Client responsible for fetching and parsing remote registry catalog metadata.
///
/// [RemoteRegistryClient] orchestrates:
/// 1. Sending a GET request via the injected [RegistryTransport].
/// 2. Checking HTTP status codes and mapping them to typed exceptions.
/// 3. Enforcing response size limits.
/// 4. Parsing the JSON body with [RegistryResponseParser].
/// 5. Building [RegistrySource] provenance.
///
/// ## Retry Behavior
///
/// Bounded retries (max 2) are performed only for:
/// - [RegistryNetworkException] (transient transport failures).
///
/// No retries for:
/// - 4xx HTTP errors (client errors — retrying is pointless).
/// - [RegistryAuthenticationException] / [RegistryProtocolException].
/// - Malformed responses.
class RemoteRegistryClient {
  final RegistryTransport _transport;
  final RegistryResponseParser _parser;
  final Logger _logger = Logger('RemoteRegistryClient');

  static const int _maxRetries = 2;

  /// Creates a [RemoteRegistryClient] with the given [transport] and optional [parser].
  RemoteRegistryClient({
    required RegistryTransport transport,
    RegistryResponseParser parser = const RegistryResponseParser(),
  })  : _transport = transport,
        _parser = parser;

  /// Fetches and parses the catalog from [options].
  ///
  /// Returns a [RegistryFetchResult]; never throws. Errors are captured in
  /// [RegistryFetchResult.errorMessage].
  Future<RegistryFetchResult> fetchCatalog(
      RemoteRegistryOptions options) async {
    final source = RegistrySource(
      registryId: options.id,
      registryBaseUrl: options.baseUrl,
      protocolVersion: '1',
      fetchedAt: DateTime.now().toUtc(),
    );

    if (!options.enabled) {
      return RegistryFetchResult.failure(
          source, 'Registry "${options.id}" is disabled.');
    }

    int attempt = 0;
    while (true) {
      attempt++;
      try {
        _logger.debug(
            'Fetching catalog from registry "${options.id}" (attempt $attempt).');
        final response = await _transport.fetchCatalog(options);
        return _processResponse(response, options, source);
      } on RegistryNetworkException catch (e) {
        if (attempt <= _maxRetries) {
          _logger.warning(
              'Network error fetching "${options.id}" (attempt $attempt): ${e.message}. Retrying...');
          continue;
        }
        _logger.error(
            'Network error fetching "${options.id}" after $attempt attempts: ${e.message}');
        return RegistryFetchResult.failure(source, e.message);
      } on RemoteRegistryException catch (e) {
        // Non-retryable: auth, protocol, config errors
        _logger.error('Registry "${options.id}" error: ${e.message}');
        return RegistryFetchResult.failure(source, e.message);
      } catch (e, st) {
        _logger.error('Unexpected error fetching "${options.id}": $e', e, st);
        return RegistryFetchResult.failure(
            source, 'Unexpected error: ${e.runtimeType}');
      }
    }
  }

  RegistryFetchResult _processResponse(
    TransportResponse response,
    RemoteRegistryOptions options,
    RegistrySource source,
  ) {
    // ── HTTP status mapping ────────────────────────────────────────────────
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw RegistryAuthenticationException(
          'Registry "${options.id}" returned HTTP ${response.statusCode}. '
          'Check authentication configuration.');
    }
    if (response.statusCode == 429) {
      throw RegistryRateLimitException(
          'Registry "${options.id}" is rate-limiting requests (HTTP 429).');
    }
    if (response.statusCode >= 500) {
      throw RegistryNetworkException(
          'Registry "${options.id}" returned server error HTTP ${response.statusCode}.');
    }
    if (!response.isSuccess) {
      return RegistryFetchResult.failure(source,
          'Registry "${options.id}" returned HTTP ${response.statusCode}.');
    }

    // ── Response size guard ────────────────────────────────────────────────
    final bodyBytes = response.body.length;
    if (bodyBytes > options.maxResponseBytes) {
      return RegistryFetchResult.failure(
          source,
          'Registry "${options.id}" response exceeded size limit '
          '(${bodyBytes} > ${options.maxResponseBytes} bytes).');
    }

    // ── JSON parsing ───────────────────────────────────────────────────────
    final payload = _parser.parse(response.body);
    _logger.info(
        'Registry "${options.id}" returned ${payload.templates.length} raw records.');

    return RegistryFetchResult.success(payload, source);
  }
}
