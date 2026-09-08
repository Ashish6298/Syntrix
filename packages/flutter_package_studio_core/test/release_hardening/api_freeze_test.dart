import 'package:flutter_package_studio_core/src/release_hardening/release_hardening.dart';
import 'package:test/test.dart';

void main() {
  group('Phase 11.1: Final API Freeze Models', () {
    test('FrozenApiSymbol and ApiFreezeAuditReport JSON roundtrip', () {
      const symbol = FrozenApiSymbol(
        name: 'DependencyContainer',
        kind: FrozenApiSymbolKind.publicClass,
        definedInFile: 'lib/src/di/dependency_container.dart',
        decision: ApiFreezeDecision.freezeAsPublic,
        isStable: true,
        rationale: 'Core IoC service locator.',
      );

      final report = ApiFreezeAuditReport(
        reportId: 'freeze_test_01',
        targetVersion: '1.0.0',
        isFrozen: true,
        totalSymbolsAudited: 1,
        publicSymbolsFrozen: 1,
        internalSymbolsRestricted: 0,
        auditedSymbols: [symbol],
        auditedAt: DateTime.parse('2026-09-08T12:00:00Z'),
      );

      final json = report.toJson();
      final restored = ApiFreezeAuditReport.fromJson(json);

      expect(restored.reportId, equals('freeze_test_01'));
      expect(restored.targetVersion, equals('1.0.0'));
      expect(restored.isFrozen, isTrue);
      expect(restored.totalSymbolsAudited, equals(1));
      expect(restored.publicSymbolsFrozen, equals(1));
      expect(restored.auditedSymbols.length, equals(1));
      expect(restored.auditedSymbols.first.name, equals('DependencyContainer'));
      expect(restored.auditedSymbols.first.kind, equals(FrozenApiSymbolKind.publicClass));
    });
  });

  group('Phase 11.1: Final API Freeze Engine Operations', () {
    test('Audits public symbols and marks entire public API surface as frozen', () {
      final engine = ApiFreezeEngine();
      final report = engine.runApiFreezeAudit(targetVersion: '1.0.0');

      expect(report.isFrozen, isTrue);
      expect(report.targetVersion, equals('1.0.0'));
      expect(report.totalSymbolsAudited, greaterThanOrEqualTo(15));
      expect(report.publicSymbolsFrozen, equals(report.totalSymbolsAudited));
      expect(report.internalSymbolsRestricted, equals(0));

      final names = report.auditedSymbols.map((s) => s.name).toSet();
      expect(names, contains('DependencyContainer'));
      expect(names, contains('Logger'));
      expect(names, contains('AiReviewEngine'));
      expect(names, contains('EnterprisePolicyEngine'));
      expect(names, contains('EnterpriseWorkflowEngine'));
      expect(names, contains('RbacEngine'));
      expect(names, contains('StudioV2Controller'));
      expect(names, contains('StudioThemeDescriptor'));
      expect(names, contains('StudioConfigurationDescriptor'));
      expect(names, contains('StudioLivePreviewEngine'));
      expect(names, contains('StudioCodeGenerator'));
      expect(names, contains('StudioPresetEngine'));
      expect(names, contains('StudioPersistenceEngine'));
      expect(names, contains('StudioExportEngine'));
      expect(names, contains('StudioExtensionEngine'));
      expect(names, contains('ReleaseCandidateAuditEngine'));

      for (final sym in report.auditedSymbols) {
        expect(sym.decision, equals(ApiFreezeDecision.freezeAsPublic));
        expect(sym.isStable, isTrue);
      }
    });
  });

  group('Phase 11.1: Final API Freeze Renderer', () {
    test('Renders ASCII Freeze Dashboard, Markdown report, and JSON schema', () {
      final engine = ApiFreezeEngine();
      final report = engine.runApiFreezeAudit(targetVersion: '1.0.0');

      // 1. ASCII Dashboard
      final ascii = ApiFreezeRenderer.renderAsciiFreezeDashboard(report);
      expect(ascii, contains('PHASE 11.1 — FINAL PUBLIC API FREEZE MATRIX'));
      expect(ascii, contains('DependencyContainer'));
      expect(ascii, contains('StudioV2Controller'));
      expect(ascii, contains('API Freeze Status: FROZEN FOR RELEASE (v1.0.0)'));

      // 2. Markdown Report
      final markdown = ApiFreezeRenderer.renderMarkdown(report);
      expect(markdown, contains('# Milestone 11 — Phase 11.1: Final API Freeze Report'));
      expect(markdown, contains('**API Freeze Status:** `FROZEN (Ready for Release Hardening)`'));
      expect(markdown, contains('## Public API Surface Summary'));
      expect(markdown, contains('**`DependencyContainer`**'));
      expect(markdown, contains('**Phase 11.2 — Breaking-Change Audit**'));

      // 3. JSON
      final json = ApiFreezeRenderer.renderJson(report);
      expect(json, contains('"report_id"'));
      expect(json, contains('"is_frozen": true'));
      expect(json, contains('"target_version": "1.0.0"'));
      expect(json, contains('"audited_symbols"'));
    });
  });
}
