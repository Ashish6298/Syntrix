import 'package:flutter_package_studio_core/src/error/exceptions.dart';
import 'package:flutter_package_studio_core/src/marketplace/remote_registry_options.dart';

/// Result of a transport fetch operation.
class TransportResponse {
  /// HTTP status code (e.g. 200, 404, 429, 500).
  final int statusCode;

  /// Raw response body string.
  final String body;

  /// Response headers (lower-cased keys).
  final Map<String, String> headers;

  /// Creates a [TransportResponse].
  const TransportResponse({
    required this.statusCode,
    required this.body,
    this.headers = const {},
  });

  /// Whether the status code indicates success (2xx).
  bool get isSuccess => statusCode >= 200 && statusCode < 300;
}

/// Abstract HTTP transport interface for registry communication.
///
/// The single method [fetchCatalog] performs a GET request to a registry's
/// catalog endpoint. Implementations must:
/// - Enforce the timeout from [options].
/// - Reject responses exceeding [RemoteRegistryOptions.maxResponseBytes].
/// - Not follow redirects to private IP ranges.
/// - Never attach authorization headers to log output.
///
/// Use [MockRegistryTransport] in tests; provide a real HTTP implementation
/// for production use.
abstract class RegistryTransport {
  /// Fetches the raw catalog response from the given [options].
  ///
  /// The URL is formed as `options.baseUrl + /catalog`.
  ///
  /// Throws [RegistryNetworkException] on transport failures.
  /// Throws [RegistryConfigurationException] on invalid options.
  Future<TransportResponse> fetchCatalog(RemoteRegistryOptions options);
}

/// In-memory mock implementation of [RegistryTransport] for unit tests.
///
/// Configure it by supplying responses keyed by registry id.

/// Use [MockRegistryTransport.alwaysFail] to simulate network failures.
class MockRegistryTransport implements RegistryTransport {
  final Map<String, TransportResponse> _responses;
  final bool _alwaysFail;
  final Exception? _throwable;

  /// Number of times [fetchCatalog] has been called.
  int callCount = 0;

  /// Creates a [MockRegistryTransport] backed by a map of response data
  /// by registry id.
  MockRegistryTransport(Map<String, TransportResponse> responses)
      : _responses = responses,
        _alwaysFail = false,
        _throwable = null;

  /// Creates a transport that always throws [RegistryNetworkException].
  MockRegistryTransport.alwaysFail(
      {String reason = 'Simulated network failure'})
      : _responses = const {},
        _alwaysFail = true,
        _throwable = RegistryNetworkException(reason);

  /// Creates a transport that always throws the given [exception].
  MockRegistryTransport.throws(Exception exception)
      : _responses = const {},
        _alwaysFail = true,
        _throwable = exception;

  @override
  Future<TransportResponse> fetchCatalog(RemoteRegistryOptions options) async {
    callCount++;
    if (_alwaysFail) {
      throw _throwable ?? RegistryNetworkException('Mock transport failure');
    }
    final response = _responses[options.id];
    if (response == null) {
      throw RegistryNetworkException(
          'Mock transport: no response configured for registry "${options.id}".');
    }
    return response;
  }

  /// Adds or replaces a response for [registryId].
  void setResponse(String registryId, TransportResponse response) {
    _responses[registryId] = response;
  }
}

// ── In-process mock transport with mutable responses ──────────────────────

/// Mutable version of [MockRegistryTransport] useful for multi-step tests.
class MutableMockRegistryTransport implements RegistryTransport {
  final Map<String, TransportResponse> responses = {};
  bool alwaysFail = false;
  String failureReason = 'Simulated failure';
  int callCount = 0;

  @override
  Future<TransportResponse> fetchCatalog(RemoteRegistryOptions options) async {
    callCount++;
    if (alwaysFail) throw RegistryNetworkException(failureReason);
    final r = responses[options.id];
    if (r == null) {
      throw RegistryNetworkException('No mock response for "${options.id}".');
    }
    return r;
  }
}
