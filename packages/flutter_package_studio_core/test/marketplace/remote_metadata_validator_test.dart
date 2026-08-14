import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:test/test.dart';

// ── Test helpers ─────────────────────────────────────────────────────────────

RemoteTemplateRecord _validRecord({
  String id = 'my_template',
  String version = '1.0.0',
  String displayName = 'My Template',
  String description = 'A fine template.',
  String publisher = 'Alice',
  String projectType = 'flutter_package',
  String category = 'community',
  String? maturity = 'stable',
  String minimumDartSdk = '>=3.5.0 <4.0.0',
  List<String> tags = const ['flutter', 'widget'],
  List<String> capabilities = const [],
  List<String> dependencies = const [],
  String? documentationUrl,
  int downloadCount = 0,
  double rating = 4.5,
}) =>
    RemoteTemplateRecord(
      id: id,
      version: version,
      displayName: displayName,
      description: description,
      publisher: publisher,
      projectType: projectType,
      category: category,
      maturity: maturity,
      minimumDartSdk: minimumDartSdk,
      tags: tags,
      capabilities: capabilities,
      dependencies: dependencies,
      documentationUrl: documentationUrl,
      downloadCount: downloadCount,
      rating: rating,
    );

void main() {
  const validator = RemoteMetadataValidator();

  // ── Valid records ─────────────────────────────────────────────────────────

  group('RemoteMetadataValidator — valid records', () {
    test('Valid community flutter_package record is accepted', () {
      final result = validator.validate(_validRecord());
      expect(result.isValid, isTrue);
      expect(result.record, isNotNull);
    });

    test('Valid dart_package record is accepted', () {
      final result =
          validator.validate(_validRecord(projectType: 'dart_package'));
      expect(result.isValid, isTrue);
    });

    test('Valid flutter_plugin record is accepted', () {
      final result =
          validator.validate(_validRecord(projectType: 'flutter_plugin'));
      expect(result.isValid, isTrue);
    });

    test('Valid dart_cli record is accepted', () {
      final result = validator.validate(_validRecord(projectType: 'dart_cli'));
      expect(result.isValid, isTrue);
    });

    test('Documentation URL with HTTPS is accepted', () {
      final result = validator.validate(
        _validRecord(documentationUrl: 'https://example.com/docs'),
      );
      expect(result.isValid, isTrue);
    });

    test('Optional maturity null is accepted', () {
      final result = validator.validate(_validRecord(maturity: null));
      expect(result.isValid, isTrue);
    });

    test('validateAll returns only valid records', () {
      final records = [
        _validRecord(id: 'good_one'),
        _validRecord(id: 'BAD_ID'), // invalid
        _validRecord(id: 'good_two'),
      ];
      final rejections = <String>[];
      final accepted = validator.validateAll(
        records,
        onRejected: (_, reason) => rejections.add(reason),
      );
      expect(accepted.length, equals(2));
      expect(rejections.length, equals(1));
    });
  });

  // ── ID validation ─────────────────────────────────────────────────────────

  group('RemoteMetadataValidator — ID validation', () {
    test('ID starting with digit is rejected', () {
      final result = validator.validate(_validRecord(id: '1bad'));
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('Invalid template ID'));
    });

    test('ID with uppercase is rejected', () {
      final result = validator.validate(_validRecord(id: 'BadId'));
      expect(result.isValid, isFalse);
    });

    test('ID with spaces is rejected', () {
      final result = validator.validate(_validRecord(id: 'bad id'));
      expect(result.isValid, isFalse);
    });

    test('ID longer than 64 chars is rejected', () {
      final longId = 'a' * 65;
      final result = validator.validate(_validRecord(id: longId));
      expect(result.isValid, isFalse);
    });

    test('Valid ID with underscores is accepted', () {
      final result = validator.validate(_validRecord(id: 'my_cool_template'));
      expect(result.isValid, isTrue);
    });
  });

  // ── Version validation ────────────────────────────────────────────────────

  group('RemoteMetadataValidator — version validation', () {
    test('Invalid semver is rejected', () {
      final result = validator.validate(_validRecord(version: 'not-a-version'));
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('version'));
    });

    test('Semver missing patch is rejected', () {
      final result = validator.validate(_validRecord(version: '1.0'));
      expect(result.isValid, isFalse);
    });

    test('Pre-release semver is accepted', () {
      final result = validator.validate(_validRecord(version: '1.0.0-beta.1'));
      expect(result.isValid, isTrue);
    });
  });

  // ── Project type validation ───────────────────────────────────────────────

  group('RemoteMetadataValidator — projectType validation', () {
    test('Unknown projectType is rejected', () {
      final result = validator.validate(_validRecord(projectType: 'web_app'));
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('projectType'));
    });
  });

  // ── Category validation ───────────────────────────────────────────────────

  group('RemoteMetadataValidator — category validation', () {
    test('Remote record claiming builtin is rejected', () {
      final result = validator.validate(_validRecord(category: 'builtin'));
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('category'));
    });

    test('Community category is accepted', () {
      final result = validator.validate(_validRecord(category: 'community'));
      expect(result.isValid, isTrue);
    });

    test('Local category is accepted', () {
      final result = validator.validate(_validRecord(category: 'local'));
      expect(result.isValid, isTrue);
    });
  });

  // ── Maturity validation ───────────────────────────────────────────────────

  group('RemoteMetadataValidator — maturity validation', () {
    test('Invalid maturity is rejected', () {
      final result =
          validator.validate(_validRecord(maturity: 'experimental-alpha'));
      expect(result.isValid, isFalse);
    });

    test('deprecated maturity is accepted', () {
      final result = validator.validate(_validRecord(maturity: 'deprecated'));
      expect(result.isValid, isTrue);
    });
  });

  // ── Tag validation ────────────────────────────────────────────────────────

  group('RemoteMetadataValidator — tag validation', () {
    test('Tag with uppercase is rejected', () {
      final result = validator.validate(_validRecord(tags: ['Flutter']));
      expect(result.isValid, isFalse);
    });

    test('Tag with spaces is rejected', () {
      final result = validator.validate(_validRecord(tags: ['my tag']));
      expect(result.isValid, isFalse);
    });

    test('Valid hyphenated tag is accepted', () {
      final result =
          validator.validate(_validRecord(tags: ['state-management']));
      expect(result.isValid, isTrue);
    });
  });

  // ── Documentation URL ─────────────────────────────────────────────────────

  group('RemoteMetadataValidator — documentationUrl validation', () {
    test('HTTP documentation URL is rejected', () {
      final result = validator.validate(
        _validRecord(documentationUrl: 'http://example.com/docs'),
      );
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('HTTPS'));
    });

    test('Malformed URL is rejected', () {
      final result = validator.validate(
        _validRecord(documentationUrl: 'not a url'),
      );
      expect(result.isValid, isFalse);
    });
  });

  // ── Rating / downloadCount ────────────────────────────────────────────────

  group('RemoteMetadataValidator — numeric bounds', () {
    test('Negative downloadCount is rejected', () {
      final result = validator.validate(_validRecord(downloadCount: -1));
      expect(result.isValid, isFalse);
    });

    test('Rating above 5.0 is rejected', () {
      final result = validator.validate(_validRecord(rating: 5.1));
      expect(result.isValid, isFalse);
    });

    test('Rating of 0.0 is accepted', () {
      final result = validator.validate(_validRecord(rating: 0.0));
      expect(result.isValid, isTrue);
    });
  });

  // ── displayName bounds ─────────────────────────────────────────────────────

  group('RemoteMetadataValidator — displayName validation', () {
    test('Empty displayName is rejected', () {
      final result = validator.validate(_validRecord(displayName: ''));
      expect(result.isValid, isFalse);
    });

    test('displayName longer than 128 chars is rejected', () {
      final result = validator.validate(_validRecord(displayName: 'A' * 129));
      expect(result.isValid, isFalse);
    });
  });

  // ── Dependency validation ─────────────────────────────────────────────────

  group('RemoteMetadataValidator — dependency validation', () {
    test('Dependency with invalid ID format is rejected', () {
      final result =
          validator.validate(_validRecord(dependencies: ['Bad-Dep']));
      expect(result.isValid, isFalse);
    });

    test('Valid dependency ID is accepted', () {
      final result =
          validator.validate(_validRecord(dependencies: ['base_template']));
      expect(result.isValid, isTrue);
    });
  });

  // ── Minimum SDK validation ────────────────────────────────────────────────

  group('RemoteMetadataValidator — minimumDartSdk', () {
    test('Empty minimumDartSdk is rejected', () {
      final record = RemoteTemplateRecord(
        id: 'x',
        version: '1.0.0',
        displayName: 'X',
        description: 'desc',
        publisher: 'pub',
        projectType: 'flutter_package',
        category: 'community',
        minimumDartSdk: '',
      );
      final result = validator.validate(record);
      expect(result.isValid, isFalse);
    });

    test('Valid constraint string is accepted', () {
      final result =
          validator.validate(_validRecord(minimumDartSdk: '>=3.5.0 <4.0.0'));
      expect(result.isValid, isTrue);
    });
  });
}
