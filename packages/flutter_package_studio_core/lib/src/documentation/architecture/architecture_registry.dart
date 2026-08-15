import 'package:flutter_package_studio_core/src/documentation/architecture/architecture_models.dart';

/// Registry holding Flutter Package Studio's canonical architecture metadata.
class ArchitectureRegistry {
  final List<ArchLayer> _layers = [];
  final List<ArchComponent> _components = [];
  final List<ArchDecision> _decisions = [];

  ArchitectureRegistry() {
    _initDefaultArchitecture();
  }

  List<ArchLayer> get layers => List.unmodifiable(_layers);
  List<ArchComponent> get components => List.unmodifiable(_components);
  List<ArchDecision> get decisions => List.unmodifiable(_decisions);

  void _initDefaultArchitecture() {
    _layers.addAll(const [
      ArchLayer(
        id: 'cli',
        name: 'CLI Layer (`flutter_package_studio_cli`)',
        description: 'Command line interface subcommands and formatting.',
        order: 10,
      ),
      ArchLayer(
        id: 'core',
        name: 'Core Engine (`flutter_package_studio_core`)',
        description:
            'Template engines, generators, validators, and life cycles.',
        order: 20,
      ),
      ArchLayer(
        id: 'documentation',
        name: 'Documentation Subsystem',
        description: 'README, API reference, and Architecture doc generators.',
        order: 30,
      ),
    ]);

    _components.addAll(const [
      ArchComponent(
        id: 'TemplateDiscoveryService',
        name: 'Template Discovery & Catalog',
        layerId: 'core',
        description: 'Discovers and indexes template catalog entries.',
      ),
      ArchComponent(
        id: 'TemplateResolver',
        name: 'Template Resolver',
        layerId: 'core',
        description: 'Resolves version constraints and inheritance.',
      ),
      ArchComponent(
        id: 'CompositionEngine',
        name: 'Composition Engine',
        layerId: 'core',
        description: 'Composes multi-layered feature templates.',
      ),
      ArchComponent(
        id: 'CustomizationEngine',
        name: 'Customization Engine',
        layerId: 'core',
        description: 'Evaluates variables, presets, and path overrides.',
      ),
      ArchComponent(
        id: 'QualityEngine',
        name: 'Quality Assurance Engine',
        layerId: 'core',
        description: 'Executes static security and structural rules.',
      ),
      ArchComponent(
        id: 'CertificationEngine',
        name: 'Certification Engine',
        layerId: 'core',
        description: 'Assesses tier eligibility for templates.',
      ),
      ArchComponent(
        id: 'TestingFramework',
        name: 'Testing Framework',
        layerId: 'core',
        description: 'Runs contract assertions and test suites.',
      ),
      ArchComponent(
        id: 'MigrationEngine',
        name: 'Migration Subsystem',
        layerId: 'core',
        description: 'Plans and executes project template upgrades.',
      ),
      ArchComponent(
        id: 'ReadmeGenerator',
        name: 'README Generator',
        layerId: 'documentation',
        description: 'Synthesizes Markdown README documentation.',
      ),
      ArchComponent(
        id: 'ApiDocGenerator',
        name: 'API Reference Generator',
        layerId: 'documentation',
        description: 'Extracts public Dart symbols and renders API docs.',
      ),
    ]);

    _decisions.addAll(const [
      ArchDecision(
        id: 'ADR-001',
        title: 'Plan-First Architecture',
        context:
            'Engine operations must be inspectable prior to disk mutation.',
        decision:
            'Every subsystem provides a planPreview mode with zero disk side-effects.',
      ),
      ArchDecision(
        id: 'ADR-002',
        title: 'Strict Path Security',
        context: 'Templates could contain path traversal attacks.',
        decision: 'All asset paths reject absolute paths and ".." traversal.',
      ),
    ]);
  }
}
