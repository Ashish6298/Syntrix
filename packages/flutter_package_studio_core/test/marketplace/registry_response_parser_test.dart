import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:test/test.dart';

// ── Fixture JSON builders ─────────────────────────────────────────────────

String _validCatalogJson({
  String protocolVersion = '1',
  String registryId = 'test-registry',
  int templateCount = 1,
  String? generatedAt,
}) {
  final templates = List.generate(
    templateCount,
    (i) => '''
    {
      "id": "template_${i + 1}",
      "version": "1.0.0",
      "displayName": "Template ${i + 1}",
      "description": "Description for template ${i + 1}.",
      "publisher": "Author",
      "projectType": "flutter_package",
      "category": "community",
      "maturity": "stable",
      "license": "MIT",
      "tags": ["flutter"],
      "capabilities": [],
      "minimumDartSdk": ">=3.5.0 <4.0.0",
      "supportedPlatforms": ["android", "ios"],
      "dependencies": [],
      "documentationUrl": "https://example.com/docs",
      "downloadCount": 100,
      "rating": 4.5
    }''',
  ).join(',');

  final gat = generatedAt ?? '"2025-01-01T00:00:00.000Z"';
  return '''
  {
    "protocolVersion": "$protocolVersion",
    "registryId": "$registryId",
    "generatedAt": $gat,
    "templates": [$templates]
  }''';
}

void main() {
  const parser = RegistryResponseParser();

  // ── Valid parsing ─────────────────────────────────────────────────────────

  group('RegistryResponseParser — valid responses', () {
    test('Parses single template response correctly', () {
      final payload = parser.parse(_validCatalogJson());
      expect(payload.protocolVersion, equals('1'));
      expect(payload.registryId, equals('test-registry'));
      expect(payload.templates.length, equals(1));
      expect(payload.templates.first.id, equals('template_1'));
      expect(payload.templates.first.version, equals('1.0.0'));
      expect(payload.templates.first.projectType, equals('flutter_package'));
      expect(payload.templates.first.rating, closeTo(4.5, 0.01));
      expect(payload.templates.first.downloadCount, equals(100));
    });

    test('Parses multiple templates', () {
      final payload = parser.parse(_validCatalogJson(templateCount: 5));
      expect(payload.templates.length, equals(5));
    });

    test('generatedAt is parsed as DateTime', () {
      final payload = parser.parse(_validCatalogJson());
      expect(payload.generatedAt, isNotNull);
      expect(payload.generatedAt!.year, equals(2025));
    });

    test('Empty templates array returns empty list', () {
      final json = '{"protocolVersion":"1","registryId":"r","templates":[]}';
      final payload = parser.parse(json);
      expect(payload.templates, isEmpty);
    });

    test('Non-object entries in templates array are skipped gracefully', () {
      final json = '''
      {
        "protocolVersion": "1",
        "registryId": "r",
        "templates": [42, null, "string", {"id":"valid","version":"1.0.0","displayName":"V","description":"d","projectType":"flutter_package","minimumDartSdk":">=3.0.0"}]
      }''';
      final payload = parser.parse(json);
      // Only the valid object should be parsed (non-objects are skipped)
      expect(payload.templates.length, equals(1));
    });

    test('Missing optional fields use defaults', () {
      final json = '''
      {
        "protocolVersion": "1",
        "registryId": "r",
        "templates": [{"id":"t","version":"1.0.0","displayName":"T","description":"","projectType":"flutter_package","minimumDartSdk":">=3.0.0"}]
      }''';
      final payload = parser.parse(json);
      expect(payload.templates.first.downloadCount, equals(0));
      expect(payload.templates.first.rating, equals(0.0));
      expect(payload.templates.first.tags, isEmpty);
      expect(payload.templates.first.category, equals('community'));
    });
  });

  // ── Protocol version guards ───────────────────────────────────────────────

  group('RegistryResponseParser — protocol version', () {
    test('Unsupported protocol version throws RegistryProtocolException', () {
      final json = _validCatalogJson(protocolVersion: '2');
      expect(
        () => parser.parse(json),
        throwsA(isA<RegistryProtocolException>()),
      );
    });

    test('Missing protocolVersion throws RegistryProtocolException', () {
      final json = '{"registryId":"r","templates":[]}';
      expect(
        () => parser.parse(json),
        throwsA(isA<RegistryProtocolException>()),
      );
    });

    test('Missing templates field throws RegistryProtocolException', () {
      final json = '{"protocolVersion":"1","registryId":"r"}';
      expect(
        () => parser.parse(json),
        throwsA(isA<RegistryProtocolException>()),
      );
    });

    test('Non-array templates field throws RegistryProtocolException', () {
      final json = '{"protocolVersion":"1","registryId":"r","templates":"bad"}';
      expect(
        () => parser.parse(json),
        throwsA(isA<RegistryProtocolException>()),
      );
    });
  });

  // ── Malformed JSON ────────────────────────────────────────────────────────

  group('RegistryResponseParser — malformed JSON', () {
    test('Invalid JSON throws RegistryProtocolException', () {
      expect(
        () => parser.parse('{not valid json'),
        throwsA(isA<RegistryProtocolException>()),
      );
    });

    test('JSON array root throws RegistryProtocolException', () {
      expect(
        () => parser.parse('[]'),
        throwsA(isA<RegistryProtocolException>()),
      );
    });

    test('JSON string root throws RegistryProtocolException', () {
      expect(
        () => parser.parse('"just a string"'),
        throwsA(isA<RegistryProtocolException>()),
      );
    });

    test('Empty string throws RegistryProtocolException', () {
      expect(
        () => parser.parse(''),
        throwsA(isA<RegistryProtocolException>()),
      );
    });
  });

  // ── Field extraction ──────────────────────────────────────────────────────

  group('RegistryResponseParser — field extraction', () {
    test('Tags are extracted as list', () {
      final json = '''
      {
        "protocolVersion": "1",
        "registryId": "r",
        "templates": [{
          "id": "t", "version": "1.0.0", "displayName": "T",
          "description": "d", "projectType": "flutter_package",
          "minimumDartSdk": ">=3.0.0",
          "tags": ["flutter", "widget", "animation"]
        }]
      }''';
      final payload = parser.parse(json);
      expect(payload.templates.first.tags,
          containsAll(['flutter', 'widget', 'animation']));
    });

    test('Rating is clamped to 0–5', () {
      final json = '''
      {
        "protocolVersion": "1", "registryId": "r",
        "templates": [{"id":"t","version":"1.0.0","displayName":"T","description":"d","projectType":"flutter_package","minimumDartSdk":">=3.0.0","rating": 99.9}]
      }''';
      final payload = parser.parse(json);
      expect(payload.templates.first.rating, equals(5.0));
    });

    test('Missing registryId defaults to "unknown"', () {
      final json = '{"protocolVersion":"1","templates":[]}';
      final payload = parser.parse(json);
      expect(payload.registryId, equals('unknown'));
    });
  });
}
