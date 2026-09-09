import 'package:syntrix/src/release_hardening/release_hardening.dart';
import 'package:test/test.dart';

void main() {
  group('Phase 11.2: Breaking-Change Audit Models', () {
    test('BreakingChangeAuditItem and BreakingChangeAuditReport JSON roundtrip',
        () {
      const item = BreakingChangeAuditItem(
        dimension: BreakingChangeDimension.constructorSignatures,
        status: BreakingChangeStatus.compliant,
        auditedTarget: 'Public constructors',
        verificationDetails: 'Positional/named parameters match baseline.',
      );

      final report = BreakingChangeAuditReport(
        reportId: 'breaking_test_01',
        targetVersion: '1.0.0',
        isBackwardCompatible: true,
        totalDimensionsAudited: 1,
        totalViolationsFound: 0,
        auditItems: [item],
        auditedAt: DateTime.parse('2026-09-08T12:00:00Z'),
      );

      final json = report.toJson();
      final restored = BreakingChangeAuditReport.fromJson(json);

      expect(restored.reportId, equals('breaking_test_01'));
      expect(restored.targetVersion, equals('1.0.0'));
      expect(restored.isBackwardCompatible, isTrue);
      expect(restored.totalDimensionsAudited, equals(1));
      expect(restored.totalViolationsFound, equals(0));
      expect(restored.auditItems.length, equals(1));
      expect(restored.auditItems.first.dimension,
          equals(BreakingChangeDimension.constructorSignatures));
      expect(restored.auditItems.first.status,
          equals(BreakingChangeStatus.compliant));
    });
  });

  group('Phase 11.2: Breaking-Change Audit Engine Operations', () {
    test(
        'Audits all 10 breaking-change dimensions and confirms 100% backward compatibility',
        () {
      final engine = BreakingChangeAuditEngine();
      final report = engine.runBreakingChangeAudit(targetVersion: '1.0.0');

      expect(report.isBackwardCompatible, isTrue);
      expect(report.targetVersion, equals('1.0.0'));
      expect(report.totalDimensionsAudited, equals(10));
      expect(report.totalViolationsFound, equals(0));

      final dimensions = report.auditItems.map((i) => i.dimension).toSet();
      expect(
          dimensions, contains(BreakingChangeDimension.constructorSignatures));
      expect(dimensions, contains(BreakingChangeDimension.parameterNames));
      expect(dimensions, contains(BreakingChangeDimension.defaultValues));
      expect(dimensions, contains(BreakingChangeDimension.nullabilityTypes));
      expect(dimensions, contains(BreakingChangeDimension.enumValues));
      expect(dimensions, contains(BreakingChangeDimension.callbackSignatures));
      expect(dimensions, contains(BreakingChangeDimension.methodNames));
      expect(dimensions, contains(BreakingChangeDimension.returnTypes));
      expect(dimensions, contains(BreakingChangeDimension.publicInheritance));
      expect(dimensions, contains(BreakingChangeDimension.publicInterfaces));

      for (final item in report.auditItems) {
        expect(item.status, equals(BreakingChangeStatus.compliant));
      }
    });
  });

  group('Phase 11.2: Breaking-Change Renderer', () {
    test('Renders ASCII Audit Dashboard, Markdown report, and JSON schema', () {
      final engine = BreakingChangeAuditEngine();
      final report = engine.runBreakingChangeAudit(targetVersion: '1.0.0');

      // 1. ASCII Dashboard
      final ascii =
          BreakingChangeRenderer.renderAsciiBreakingChangeDashboard(report);
      expect(ascii, contains('PHASE 11.2 — BREAKING-CHANGE AUDIT MATRIX'));
      expect(ascii, contains('Constructor signatures'));
      expect(ascii, contains('Nullable/non-nullable types'));
      expect(
          ascii, contains('Backward Compatibility: PASSED (100% Compatible)'));

      // 2. Markdown Report
      final markdown = BreakingChangeRenderer.renderMarkdown(report);
      expect(
          markdown,
          contains(
              '# Milestone 11 — Phase 11.2: Breaking-Change Audit Report'));
      expect(
          markdown,
          contains(
              '**Backward Compatibility Status:** `PASSED (100% Compatible)`'));
      expect(markdown, contains('## Breaking-Change Evaluation Summary'));
      expect(markdown, contains('**Constructor signatures**'));
      expect(markdown, contains('**Phase 11.3 — Full Regression Testing**'));

      // 3. JSON
      final json = BreakingChangeRenderer.renderJson(report);
      expect(json, contains('"report_id"'));
      expect(json, contains('"is_backward_compatible": true'));
      expect(json, contains('"total_violations_found": 0'));
      expect(json, contains('"audit_items"'));
    });
  });
}
