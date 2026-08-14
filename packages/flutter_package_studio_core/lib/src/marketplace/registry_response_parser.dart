import 'dart:convert';

import 'package:flutter_package_studio_core/src/error/exceptions.dart';
import 'package:flutter_package_studio_core/src/marketplace/registry_protocol.dart';
import 'package:flutter_package_studio_core/src/marketplace/remote_template_record.dart';

/// Parses a raw JSON string from a remote registry into a [RemoteRegistryPayload].
///
/// [RegistryResponseParser] is the first security boundary for remote data.
/// It:
/// 1. Validates the JSON is a well-formed object.
/// 2. Checks that [kProtocolVersion] equals [supportedProtocolVersion].
/// 3. Extracts the template records array without interpreting field semantics.
///
/// Detailed field-level validation (semver, URL, ID format) is the
/// responsibility of [RemoteMetadataValidator].
class RegistryResponseParser {
  const RegistryResponseParser();

  /// Parses [jsonBody] and returns a [RemoteRegistryPayload].
  ///
  /// Throws:
  /// - [RegistryProtocolException] — if the JSON is malformed, missing
  ///   required top-level fields, or uses an unsupported protocol version.
  RemoteRegistryPayload parse(String jsonBody) {
    // ── JSON decode ───────────────────────────────────────────────────────
    dynamic root;
    try {
      root = jsonDecode(jsonBody);
    } catch (e) {
      throw RegistryProtocolException(
          'Registry response is not valid JSON.', e.toString());
    }

    if (root is! Map<String, dynamic>) {
      throw RegistryProtocolException(
          'Registry response root must be a JSON object; '
          'got ${root.runtimeType}.');
    }

    // ── Protocol version guard ─────────────────────────────────────────────
    final rawVersion = root[kProtocolVersion];
    if (rawVersion == null) {
      throw RegistryProtocolException(
          'Registry response is missing required field "$kProtocolVersion".');
    }
    final version = rawVersion.toString().trim();
    if (version != supportedProtocolVersion) {
      throw RegistryProtocolException(
          'Registry response uses unsupported protocol version "$version". '
          'Supported: "$supportedProtocolVersion".');
    }

    // ── Registry ID ────────────────────────────────────────────────────────
    final rawId = root[kRegistryId];
    final registryId = rawId != null ? rawId.toString().trim() : 'unknown';

    // ── Generated timestamp (optional) ─────────────────────────────────────
    DateTime? generatedAt;
    final rawTs = root[kGeneratedAt];
    if (rawTs is String && rawTs.isNotEmpty) {
      generatedAt = DateTime.tryParse(rawTs);
    }

    // ── Templates array ────────────────────────────────────────────────────
    final rawTemplates = root[kTemplates];
    if (rawTemplates == null) {
      throw RegistryProtocolException(
          'Registry response is missing required field "$kTemplates".');
    }
    if (rawTemplates is! List) {
      throw RegistryProtocolException(
          'Field "$kTemplates" must be a JSON array; '
          'got ${rawTemplates.runtimeType}.');
    }

    final records = <RemoteTemplateRecord>[];
    for (var i = 0; i < rawTemplates.length; i++) {
      final raw = rawTemplates[i];
      if (raw is! Map<String, dynamic>) {
        // Skip non-object entries with a warning-friendly approach.
        continue;
      }
      final record = _parseRecord(raw, index: i);
      if (record != null) records.add(record);
    }

    return RemoteRegistryPayload(
      protocolVersion: version,
      registryId: registryId,
      generatedAt: generatedAt,
      templates: records,
    );
  }

  // ── Private helpers ──────────────────────────────────────────────────────

  RemoteTemplateRecord? _parseRecord(Map<String, dynamic> raw,
      {required int index}) {
    // Extract and sanitize each field; return null if required fields are absent.
    final id = _str(raw, kId);
    final version = _str(raw, kVersion);
    final displayName = _str(raw, kDisplayName);
    final description = _str(raw, kDescription);
    final projectType = _str(raw, kProjectType);
    final minimumDartSdk = _str(raw, kMinimumDartSdk);

    if (id.isEmpty ||
        version.isEmpty ||
        displayName.isEmpty ||
        projectType.isEmpty ||
        minimumDartSdk.isEmpty) {
      // Skip records missing required fields — validator will report them.
      return null;
    }

    return RemoteTemplateRecord(
      id: id,
      version: version,
      displayName: displayName,
      description: description,
      publisher: _str(raw, kPublisher),
      projectType: projectType,
      category:
          _str(raw, kCategory).isNotEmpty ? _str(raw, kCategory) : 'community',
      maturity: _strOrNull(raw, kMaturity),
      license: _strOrNull(raw, kLicense),
      tags: _strList(raw, kTags),
      capabilities: _strList(raw, kCapabilities),
      minimumDartSdk: minimumDartSdk,
      minimumFlutterSdk: _strOrNull(raw, kMinimumFlutterSdk),
      supportedPlatforms: _strList(raw, kSupportedPlatforms),
      dependencies: _strList(raw, kDependencies),
      documentationUrl: _strOrNull(raw, kDocumentationUrl),
      downloadCount: _int(raw, kDownloadCount),
      rating: _double(raw, kRating).clamp(0.0, 5.0),
    );
  }

  String _str(Map<String, dynamic> m, String key) {
    final v = m[key];
    if (v == null) return '';
    return v.toString().trim();
  }

  String? _strOrNull(Map<String, dynamic> m, String key) {
    final v = m[key];
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  List<String> _strList(Map<String, dynamic> m, String key) {
    final v = m[key];
    if (v is! List) return const [];
    return v
        .whereType<Object>()
        .map((e) => e.toString().trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  int _int(Map<String, dynamic> m, String key) {
    final v = m[key];
    if (v is int) return v < 0 ? 0 : v;
    if (v is double) return v.floor().abs();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  double _double(Map<String, dynamic> m, String key) {
    final v = m[key];
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }
}
