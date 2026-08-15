import 'package:flutter_package_studio_core/src/error/exceptions.dart';
import 'package:flutter_package_studio_core/src/documentation/mermaid/mermaid_models.dart';

/// Validates Mermaid diagram structure, node IDs, and edge connections.
class MermaidValidator {
  static final RegExp _validIdRegExp = RegExp(r'^[a-zA-Z0-9_]+$');

  /// Validates a list of [nodes] and [edges] for a Mermaid diagram.
  static void validate({
    required List<MermaidNode> nodes,
    required List<MermaidEdge> edges,
  }) {
    final seenNodeIds = <String>{};

    for (final node in nodes) {
      if (!_validIdRegExp.hasMatch(node.id)) {
        throw MermaidGenerationException(
            'Invalid Mermaid node ID "${node.id}". Node IDs must contain only alphanumeric characters and underscores.');
      }

      if (seenNodeIds.contains(node.id)) {
        throw MermaidGenerationException(
            'Duplicate Mermaid node ID detected: "${node.id}".');
      }
      seenNodeIds.add(node.id);
    }

    for (final edge in edges) {
      if (!seenNodeIds.contains(edge.fromId)) {
        throw MermaidGenerationException(
            'Mermaid edge source node ID "${edge.fromId}" does not exist in diagram nodes.');
      }
      if (!seenNodeIds.contains(edge.toId)) {
        throw MermaidGenerationException(
            'Mermaid edge target node ID "${edge.toId}" does not exist in diagram nodes.');
      }
    }
  }
}
