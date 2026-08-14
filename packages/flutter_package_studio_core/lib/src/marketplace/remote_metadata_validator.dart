import 'package:flutter_package_studio_core/src/error/exceptions.dart';
import 'package:flutter_package_studio_core/src/marketplace/registry_protocol.dart';
import 'package:flutter_package_studio_core/src/marketplace/remote_template_record.dart';
import 'package:flutter_package_studio_core/src/template/template_semver.dart';

/// Result of validating a single [RemoteTemplateRecord].
class MetadataValidationResult {
  /// Whether the record passed all validation checks.
  final bool isValid;

  /// If invalid, a human-readable explanation. Never contains credentials.
  final String? errorMessage;

  /// The validated record (only present when [isValid] is true).
  final RemoteTemplateRecord? record;

  const MetadataValidationResult._({
    required this.isValid,
    this.errorMessage,
    this.record,
  });

  /// Creates a successful result.
  factory MetadataValidationResult.valid(RemoteTemplateRecord record) =>
      MetadataValidationResult._(isValid: true, record: record);

  /// Creates a failed result.
  factory MetadataValidationResult.invalid(String reason) =>
      MetadataValidationResult._(isValid: false, errorMessage: reason);
}

/// Second security boundary for remote registry data.
///
/// [RemoteMetadataValidator] validates every [RemoteTemplateRecord] produced by
/// [RegistryResponseParser] before it is admitted into the catalog. Validation
/// is strict and fail-closed: any unexpected or malformed field causes the
/// record to be **rejected**, not silently coerced.
///
/// ## What is validated
///
/// - **ID**: matches `^[a-z][a-z0-9_]{0,63}$`
/// - **Version**: parseable by [TemplateSemVer]
/// - **displayName / description**: non-empty, bounded length
/// - **projectType**: in [allowedProjectTypes]
/// - **category**: in [allowedRemoteCategories] (remote cannot claim `builtin`)
/// - **maturity**: in [allowedMaturityValues] (if present)
/// - **tags / capabilities**: each element matches `^[a-z][a-z0-9_-]{0,63}$`
/// - **documentationUrl**: if present, must be an HTTPS URL
/// - **downloadCount / rating**: numeric bounds
/// - **dependencies**: each element is a valid ID
/// - **minimumDartSdk**: non-empty string (syntactic check only)
class RemoteMetadataValidator {
  static final _idPattern = RegExp(r'^[a-z][a-z0-9_]{0,63}$');
  static final _tagPattern = RegExp(r'^[a-z][a-z0-9_-]{0,63}$');
  static final _sdkConstraintPattern =
      RegExp(r'^[><=^~\d]'); // Starts with a constraint character

  const RemoteMetadataValidator();

  /// Validates [record] and returns a [MetadataValidationResult].
  ///
  /// Never throws; failures are expressed as [MetadataValidationResult.invalid].
  MetadataValidationResult validate(RemoteTemplateRecord record) {
    // ID
    if (!_idPattern.hasMatch(record.id)) {
      return MetadataValidationResult.invalid(
          'Invalid template ID "${record.id}". '
          'Must match ^[a-z][a-z0-9_]{0,63}\$.');
    }

    // Version
    try {
      TemplateSemVer.parse(record.version);
    } catch (_) {
      return MetadataValidationResult.invalid(
          'Invalid semantic version "${record.version}" for template "${record.id}".');
    }

    // displayName
    if (record.displayName.isEmpty) {
      return MetadataValidationResult.invalid(
          'Template "${record.id}" has an empty displayName.');
    }
    if (record.displayName.length > 128) {
      return MetadataValidationResult.invalid(
          'Template "${record.id}" displayName exceeds 128 characters.');
    }

    // description
    if (record.description.length > 512) {
      return MetadataValidationResult.invalid(
          'Template "${record.id}" description exceeds 512 characters.');
    }

    // projectType
    if (!allowedProjectTypes.contains(record.projectType)) {
      return MetadataValidationResult.invalid(
          'Template "${record.id}" has unsupported projectType '
          '"${record.projectType}". Allowed: $allowedProjectTypes.');
    }

    // category — remote cannot claim builtin
    if (!allowedRemoteCategories.contains(record.category)) {
      return MetadataValidationResult.invalid(
          'Template "${record.id}" has invalid or disallowed category '
          '"${record.category}". Remote registries may only use: '
          '$allowedRemoteCategories.');
    }

    // maturity
    if (record.maturity != null &&
        !allowedMaturityValues.contains(record.maturity)) {
      return MetadataValidationResult.invalid(
          'Template "${record.id}" has invalid maturity "${record.maturity}". '
          'Allowed: $allowedMaturityValues.');
    }

    // tags
    for (final tag in record.tags) {
      if (!_tagPattern.hasMatch(tag)) {
        return MetadataValidationResult.invalid(
            'Template "${record.id}" has invalid tag "$tag". '
            'Tags must match ^[a-z][a-z0-9_-]{0,63}\$.');
      }
    }

    // capabilities
    for (final cap in record.capabilities) {
      if (!_tagPattern.hasMatch(cap)) {
        return MetadataValidationResult.invalid(
            'Template "${record.id}" has invalid capability "$cap".');
      }
    }

    // dependencies
    for (final dep in record.dependencies) {
      if (!_idPattern.hasMatch(dep)) {
        return MetadataValidationResult.invalid(
            'Template "${record.id}" has invalid dependency ID "$dep". '
            'Must match ^[a-z][a-z0-9_]{0,63}\$.');
      }
    }

    // documentationUrl — must be HTTPS if present
    if (record.documentationUrl != null &&
        record.documentationUrl!.isNotEmpty) {
      try {
        final uri = Uri.parse(record.documentationUrl!);
        if (uri.scheme != 'https') {
          return MetadataValidationResult.invalid(
              'Template "${record.id}" documentationUrl must use HTTPS '
              '(got "${uri.scheme}").');
        }
      } catch (_) {
        return MetadataValidationResult.invalid(
            'Template "${record.id}" has a malformed documentationUrl.');
      }
    }

    // downloadCount
    if (record.downloadCount < 0) {
      return MetadataValidationResult.invalid(
          'Template "${record.id}" has negative downloadCount.');
    }

    // rating
    if (record.rating < 0.0 || record.rating > 5.0) {
      return MetadataValidationResult.invalid(
          'Template "${record.id}" rating must be between 0.0 and 5.0 '
          '(got ${record.rating}).');
    }

    // minimumDartSdk — must look like a constraint
    if (record.minimumDartSdk.isEmpty) {
      return MetadataValidationResult.invalid(
          'Template "${record.id}" has an empty minimumDartSdk.');
    }
    if (!_sdkConstraintPattern.hasMatch(record.minimumDartSdk)) {
      return MetadataValidationResult.invalid(
          'Template "${record.id}" minimumDartSdk '
          '"${record.minimumDartSdk}" does not look like a valid SDK constraint.');
    }

    return MetadataValidationResult.valid(record);
  }

  /// Validates a list of records, returning only those that pass.
  ///
  /// [onRejected] is called with each rejection reason for diagnostic logging.
  List<RemoteTemplateRecord> validateAll(
    List<RemoteTemplateRecord> records, {
    void Function(RemoteTemplateRecord record, String reason)? onRejected,
  }) {
    final valid = <RemoteTemplateRecord>[];
    for (final record in records) {
      final result = validate(record);
      if (result.isValid) {
        valid.add(record);
      } else {
        onRejected?.call(record, result.errorMessage!);
      }
    }
    return valid;
  }
}

/// Validates a registry URL for security (used by options AND transport).
///
/// Throws [RegistryConfigurationException] if [url] is unsafe.
void validateRegistryUrl(String url) {
  Uri parsed;
  try {
    parsed = Uri.parse(url);
  } catch (_) {
    throw RegistryConfigurationException(
        'Registry URL "$url" is not a valid URI.');
  }
  if (parsed.scheme != 'https') {
    throw RegistryConfigurationException(
        'Registry URL must use HTTPS. Got: "${parsed.scheme}".');
  }
  if (!parsed.hasAuthority || parsed.host.isEmpty) {
    throw RegistryConfigurationException(
        'Registry URL must include a valid hostname.');
  }
}
