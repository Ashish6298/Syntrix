import 'package:syntrix/src/studio_v2/studio_v2.dart';
import 'package:test/test.dart';

void main() {
  group('Phase 10.18: Studio Extension Models', () {
    test('Extension and prebuilt models serialize correctly', () {
      final ext = ShaderStudioExtension();
      expect(ext.name, equals('Shader Studio'));
      expect(ext.tools.length, equals(1));
      expect(ext.tools.first.title, equals('GLSL Shader Live Compiler'));

      final json = ext.toJson();
      expect(json['extension_id'], equals('ext_shader_studio'));
      expect(json['name'], equals('Shader Studio'));
      expect(json['tools_count'], equals(1));
    });
  });

  group('Phase 10.18: Studio Extension Engine Operations', () {
    test(
        'Registers default extensions and handles tool/action discovery and execution',
        () async {
      final controller = StudioV2Controller();
      final extEngine = StudioExtensionEngine(controller: controller);

      expect(extEngine.registeredExtensions.length, equals(5));
      final names =
          extEngine.registeredExtensions.values.map((e) => e.name).toSet();
      expect(names, contains('Shader Studio'));
      expect(names, contains('AI Assistant'));
      expect(names, contains('Animation Timeline'));
      expect(names, contains('Scene Timeline'));
      expect(names, contains('Advanced Profiler'));

      final tools = extEngine.getAllTools();
      expect(tools.length, greaterThanOrEqualTo(2));

      final actions = extEngine.getAllActions();
      expect(actions.length, greaterThanOrEqualTo(1));

      // Trigger AI Assistant action
      expect(controller.state.activeConfiguration.particleCount, equals(200));
      final triggered = await extEngine.triggerAction('action_ai_optimize');
      expect(triggered, isTrue);
      expect(controller.state.activeConfiguration.particleCount, equals(300));
      expect(controller.state.activeConfiguration.animationSpeed, equals(1.5));

      // Unregister extension
      await extEngine.unregisterExtension('ext_ai_assistant');
      expect(extEngine.registeredExtensions.containsKey('ext_ai_assistant'),
          isFalse);
    });
  });

  group('Phase 10.18: Studio Extension Renderer', () {
    test('Renders ASCII Extensions list, Markdown Catalog, and JSON schema',
        () {
      final controller = StudioV2Controller();
      final extEngine = StudioExtensionEngine(controller: controller);

      // 1. ASCII Extensions Wireframe
      final ascii = StudioExtensionRenderer.renderAsciiExtensions(extEngine);
      expect(ascii, contains('Studio Extensions'));
      expect(ascii, contains('• Shader Studio'));
      expect(ascii, contains('• AI Assistant'));
      expect(ascii, contains('• Animation Timeline'));
      expect(ascii, contains('• Scene Timeline'));
      expect(ascii, contains('• Advanced Profiler'));

      // 2. Markdown Catalog
      final markdown = StudioExtensionRenderer.renderMarkdown(extEngine);
      expect(markdown, contains('# Studio Extension Architecture Registry'));
      expect(markdown, contains('**Shader Studio**'));
      expect(markdown, contains('**AI Assistant**'));
      expect(markdown, contains('## Extension Details & Capabilities'));

      // 3. JSON
      final json = StudioExtensionRenderer.renderJson(extEngine);
      expect(json, contains('"extensions"'));
      expect(json, contains('"ext_shader_studio"'));
    });
  });
}
