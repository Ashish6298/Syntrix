import 'package:flutter_package_studio_core/src/documentation/architecture/architecture_models.dart';
import 'package:flutter_package_studio_core/src/documentation/architecture/architecture_registry.dart';
import 'package:flutter_package_studio_core/src/documentation/readme/readme_sanitizer.dart';
import 'package:flutter_package_studio_core/src/logging/logger.dart';

/// Core generator for architecture documentation and Mermaid diagrams.
class ArchitectureDocGenerator {
  final ArchitectureRegistry registry;
  final Logger _logger = Logger('ArchitectureDocGenerator');

  ArchitectureDocGenerator({ArchitectureRegistry? registry})
      : registry = registry ?? ArchitectureRegistry();

  /// Plans architecture documentation.
  ArchDocPlan planArchitectureDoc(ArchDocOptions options) {
    _logger.info('Planning architecture documentation');

    final sortedComps = List<ArchComponent>.from(registry.components)..sort();

    return ArchDocPlan(
      title: options.title,
      layers: registry.layers,
      components: List.unmodifiable(sortedComps),
      decisions: registry.decisions,
    );
  }

  /// Renders plan into deterministic Markdown document with Mermaid diagrams.
  ArchDocResult generateArchitectureDoc(ArchDocPlan plan) {
    _logger.info('Rendering architecture markdown');

    final buffer = StringBuffer();
    final cleanTitle = ReadmeSanitizer.escapeText(plan.title);

    buffer.writeln('# $cleanTitle\n');

    // System Overview
    buffer.writeln('## System Overview\n');
    buffer.writeln(
        'Flutter Package Studio (FPS) is a production-grade monorepo suite for creating, composing, customizing, validating, certifying, testing, migrating, and documenting Flutter packages.\n');

    // Mermaid Diagram
    buffer.writeln('## End-to-End Pipeline Workflow\n');
    buffer.writeln('```mermaid');
    buffer.writeln('graph TD');
    buffer.writeln(
        '  Discovery[Template Catalog] --> Resolution[Template Resolver]');
    buffer.writeln('  Resolution --> Composition[Composition Engine]');
    buffer.writeln('  Composition --> Customization[Customization Engine]');
    buffer.writeln('  Customization --> Quality[Quality QA Engine]');
    buffer.writeln('  Quality --> Certification[Certification Engine]');
    buffer.writeln('  Certification --> Testing[Testing Framework]');
    buffer.writeln('  Testing --> Generation[Project Generator]');
    buffer.writeln('```\n');

    // Layers & Components
    buffer.writeln('## Architecture Components\n');
    for (final c in plan.components) {
      buffer.writeln('### `${c.id}`');
      buffer.writeln('**Name**: ${c.name}');
      buffer.writeln('**Layer**: ${c.layerId}');
      buffer.writeln('${c.description}\n');
    }

    // Architectural Decisions
    if (plan.decisions.isNotEmpty) {
      buffer.writeln('## Architectural Decision Records (ADRs)\n');
      for (final d in plan.decisions) {
        buffer.writeln('### ${d.id}: ${d.title} `[${d.status}]`');
        buffer.writeln('**Context**: ${d.context}');
        buffer.writeln('**Decision**: ${d.decision}\n');
      }
    }

    final markdown = buffer.toString().trimRight();

    return ArchDocResult(
      title: plan.title,
      markdown: '$markdown\n',
      componentCount: plan.components.length,
    );
  }
}
