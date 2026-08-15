import 'package:flutter_package_studio_core/src/documentation/mermaid/mermaid_models.dart';
import 'package:flutter_package_studio_core/src/documentation/mermaid/mermaid_validator.dart';
import 'package:flutter_package_studio_core/src/documentation/readme/readme_sanitizer.dart';
import 'package:flutter_package_studio_core/src/logging/logger.dart';

/// Core generator for creating deterministic Mermaid diagram text source.
class MermaidDiagramGenerator {
  final Logger _logger = Logger('MermaidDiagramGenerator');

  /// Plans a Mermaid diagram without rendering source code.
  MermaidDiagramPlan planDiagram(MermaidDiagramOptions options) {
    _logger.info('Planning Mermaid diagram "${options.title}"');

    MermaidValidator.validate(
      nodes: options.nodes,
      edges: options.edges,
    );

    return MermaidDiagramPlan(
      title: options.title,
      type: options.type,
      nodes: options.nodes,
      edges: options.edges,
    );
  }

  /// Renders a [plan] into deterministic `.mmd` string source.
  MermaidDiagramResult generateDiagram(MermaidDiagramPlan plan) {
    _logger.info('Rendering Mermaid diagram source for "${plan.title}"');

    final buffer = StringBuffer();

    switch (plan.type) {
      case MermaidType.flowchartTD:
        buffer.writeln('graph TD');
        for (final edge in plan.edges) {
          final fromNode = plan.nodes.firstWhere((n) => n.id == edge.fromId);
          final toNode = plan.nodes.firstWhere((n) => n.id == edge.toId);

          final fromLabel = ReadmeSanitizer.escapeText(fromNode.label);
          final toLabel = ReadmeSanitizer.escapeText(toNode.label);

          buffer.writeln(
              '  ${fromNode.id}[$fromLabel] --> ${toNode.id}[$toLabel]');
        }
        break;
      case MermaidType.flowchartLR:
        buffer.writeln('graph LR');
        for (final edge in plan.edges) {
          final fromNode = plan.nodes.firstWhere((n) => n.id == edge.fromId);
          final toNode = plan.nodes.firstWhere((n) => n.id == edge.toId);

          final fromLabel = ReadmeSanitizer.escapeText(fromNode.label);
          final toLabel = ReadmeSanitizer.escapeText(toNode.label);

          buffer.writeln(
              '  ${fromNode.id}[$fromLabel] --> ${toNode.id}[$toLabel]');
        }
        break;
      case MermaidType.sequenceDiagram:
        buffer.writeln('sequenceDiagram');
        for (final node in plan.nodes) {
          buffer.writeln(
              '  participant ${node.id} as ${ReadmeSanitizer.escapeText(node.label)}');
        }
        for (final edge in plan.edges) {
          final msg = edge.label != null
              ? ': ${ReadmeSanitizer.escapeText(edge.label!)}'
              : '';
          buffer.writeln('  ${edge.fromId}->>${edge.toId}$msg');
        }
        break;
    }

    final source = buffer.toString().trimRight();

    return MermaidDiagramResult(
      title: plan.title,
      source: '$source\n',
    );
  }
}
