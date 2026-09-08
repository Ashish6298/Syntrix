import 'package:flutter_package_studio_core/src/studio_v2/studio_v2.dart';
import 'package:test/test.dart';

void main() {
  group('Phase 10.19: Studio UX & Accessibility Hardening Models', () {
    test('UxAuditItem and StudioUxHardeningReport JSON roundtrip', () {
      const item = UxAuditItem(
        dimension: UxAuditDimension.themeCompatibility,
        status: UxAuditStatus.verified,
        complianceDetails: 'Contrast ratio >= 4.5:1 verified across all themes.',
        minimumContrastRatio: 4.8,
        keyboardAccessible: true,
      );

      final report = StudioUxHardeningReport(
        reportId: 'ux_test_01',
        overallCompliant: true,
        auditItems: [item],
        auditedAt: DateTime.parse('2026-09-08T12:00:00Z'),
      );

      final json = report.toJson();
      final restored = StudioUxHardeningReport.fromJson(json);

      expect(restored.reportId, equals('ux_test_01'));
      expect(restored.overallCompliant, isTrue);
      expect(restored.auditItems.length, equals(1));
      expect(restored.auditItems.first.dimension, equals(UxAuditDimension.themeCompatibility));
      expect(restored.auditItems.first.minimumContrastRatio, equals(4.8));
    });
  });

  group('Phase 10.19: Studio UX Hardening Engine Operations', () {
    test('Runs full audit covering all 13 UX and accessibility dimensions', () {
      final controller = StudioV2Controller();
      final uxEngine = StudioUxHardeningEngine(controller: controller);

      final report = uxEngine.runFullAudit();

      expect(report.overallCompliant, isTrue);
      expect(report.auditItems.length, equals(13));

      final dimensions = report.auditItems.map((i) => i.dimension).toSet();
      expect(dimensions, contains(UxAuditDimension.responsiveLayouts));
      expect(dimensions, contains(UxAuditDimension.desktopLayouts));
      expect(dimensions, contains(UxAuditDimension.mobileLayouts));
      expect(dimensions, contains(UxAuditDimension.keyboardNavigation));
      expect(dimensions, contains(UxAuditDimension.focusBehavior));
      expect(dimensions, contains(UxAuditDimension.readableTypography));
      expect(dimensions, contains(UxAuditDimension.overflowHandling));
      expect(dimensions, contains(UxAuditDimension.semanticLabels));
      expect(dimensions, contains(UxAuditDimension.accessibleControls));
      expect(dimensions, contains(UxAuditDimension.themeCompatibility));
      expect(dimensions, contains(UxAuditDimension.errorStates));
      expect(dimensions, contains(UxAuditDimension.loadingStates));
      expect(dimensions, contains(UxAuditDimension.emptyStates));

      for (final item in report.auditItems) {
        expect(item.status, equals(UxAuditStatus.verified));
      }
    });
  });

  group('Phase 10.19: Studio UX Hardening Renderer', () {
    test('Renders ASCII UX dashboard, Markdown report, and JSON schema', () {
      final controller = StudioV2Controller();
      final uxEngine = StudioUxHardeningEngine(controller: controller);

      final report = uxEngine.runFullAudit();

      // 1. ASCII Dashboard
      final ascii = StudioUxRenderer.renderAsciiDashboard(report);
      expect(ascii, contains('Studio UX & Accessibility Hardening Matrix'));
      expect(ascii, contains('Responsive Layouts'));
      expect(ascii, contains('Keyboard Navigation'));
      expect(ascii, contains('Overall Compliance: PRODUCTION READY (PASS)'));

      // 2. Markdown Report
      final markdown = StudioUxRenderer.renderMarkdown(report);
      expect(markdown, contains('# Studio UX & Accessibility Hardening Report'));
      expect(markdown, contains('**Audit Status:** `PASSED (Production-Grade)`'));
      expect(markdown, contains('## Verification & Hardening Dimension Matrix'));
      expect(markdown, contains('**Keyboard Navigation**'));

      // 3. JSON
      final json = StudioUxRenderer.renderJson(report);
      expect(json, contains('"report_id"'));
      expect(json, contains('"overall_compliant": true'));
      expect(json, contains('"audit_items"'));
    });
  });
}
