/// Supported Mermaid diagram types.

enum MermaidType {
  flowchartTD,
  flowchartLR,
  sequenceDiagram,
}

/// Represents a node in a Mermaid flowchart or participant in a sequence diagram.
class MermaidNode implements Comparable<MermaidNode> {
  final String id;
  final String label;

  const MermaidNode({
    required this.id,
    required this.label,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
      };

  @override
  int compareTo(MermaidNode other) => id.compareTo(other.id);
}

/// Represents an edge/connection between two Mermaid nodes.
class MermaidEdge implements Comparable<MermaidEdge> {
  final String fromId;
  final String toId;
  final String? label;

  const MermaidEdge({
    required this.fromId,
    required this.toId,
    this.label,
  });

  Map<String, dynamic> toJson() => {
        'fromId': fromId,
        'toId': toId,
        if (label != null) 'label': label,
      };

  @override
  int compareTo(MermaidEdge other) {
    final f = fromId.compareTo(other.fromId);
    if (f != 0) return f;
    return toId.compareTo(other.toId);
  }
}

/// Options for configuring a Mermaid diagram.
class MermaidDiagramOptions {
  final String title;
  final MermaidType type;
  final List<MermaidNode> nodes;
  final List<MermaidEdge> edges;

  const MermaidDiagramOptions({
    this.title = 'System Diagram',
    this.type = MermaidType.flowchartTD,
    this.nodes = const [],
    this.edges = const [],
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'type': type.name,
        'nodeCount': nodes.length,
        'edgeCount': edges.length,
      };
}

/// Preview plan of a Mermaid diagram before rendering.
class MermaidDiagramPlan {
  final String title;
  final MermaidType type;
  final List<MermaidNode> nodes;
  final List<MermaidEdge> edges;

  MermaidDiagramPlan({
    required this.title,
    required this.type,
    required List<MermaidNode> nodes,
    required List<MermaidEdge> edges,
  })  : nodes = _sortNodes(nodes),
        edges = _sortEdges(edges);

  static List<MermaidNode> _sortNodes(List<MermaidNode> list) {
    final copy = List<MermaidNode>.from(list);
    copy.sort();
    return List.unmodifiable(copy);
  }

  static List<MermaidEdge> _sortEdges(List<MermaidEdge> list) {
    final copy = List<MermaidEdge>.from(list);
    copy.sort();
    return List.unmodifiable(copy);
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'type': type.name,
        'nodeCount': nodes.length,
        'edgeCount': edges.length,
        'nodes': nodes.map((n) => n.toJson()).toList(),
        'edges': edges.map((e) => e.toJson()).toList(),
      };
}

/// Result of Mermaid diagram generation containing raw `.mmd` string source.
class MermaidDiagramResult {
  final String title;
  final String source;

  const MermaidDiagramResult({
    required this.title,
    required this.source,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'source': source,
      };
}
