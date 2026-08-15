/// Architectural layer in Flutter Package Studio.
class ArchLayer {
  final String id;
  final String name;
  final String description;
  final int order;

  const ArchLayer({
    required this.id,
    required this.name,
    required this.description,
    this.order = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'order': order,
      };
}

/// Architectural component in Flutter Package Studio.
class ArchComponent implements Comparable<ArchComponent> {
  final String id;
  final String name;
  final String layerId;
  final String description;
  final List<String> responsibilities;

  const ArchComponent({
    required this.id,
    required this.name,
    required this.layerId,
    required this.description,
    this.responsibilities = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'layerId': layerId,
        'description': description,
        'responsibilities': responsibilities,
      };

  @override
  int compareTo(ArchComponent other) => id.compareTo(other.id);
}

/// Key Architectural Decision Record (ADR).
class ArchDecision {
  final String id;
  final String title;
  final String context;
  final String decision;
  final String status;

  const ArchDecision({
    required this.id,
    required this.title,
    required this.context,
    required this.decision,
    this.status = 'ACCEPTED',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'context': context,
        'decision': decision,
        'status': status,
      };
}

/// Options for configuring Architecture documentation generation.
class ArchDocOptions {
  final String title;
  final bool includeDiagrams;
  final bool includeDecisions;

  const ArchDocOptions({
    this.title = 'Flutter Package Studio — System Architecture',
    this.includeDiagrams = true,
    this.includeDecisions = true,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'includeDiagrams': includeDiagrams,
        'includeDecisions': includeDecisions,
      };
}

/// Plan preview for architecture documentation.
class ArchDocPlan {
  final String title;
  final List<ArchLayer> layers;
  final List<ArchComponent> components;
  final List<ArchDecision> decisions;

  const ArchDocPlan({
    required this.title,
    required this.layers,
    required this.components,
    required this.decisions,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'layerCount': layers.length,
        'componentCount': components.length,
        'decisionCount': decisions.length,
        'layers': layers.map((l) => l.toJson()).toList(),
        'components': components.map((c) => c.toJson()).toList(),
        'decisions': decisions.map((d) => d.toJson()).toList(),
      };
}

/// Result of architecture documentation generation containing Markdown.
class ArchDocResult {
  final String title;
  final String markdown;
  final int componentCount;

  const ArchDocResult({
    required this.title,
    required this.markdown,
    required this.componentCount,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'markdown': markdown,
        'componentCount': componentCount,
      };
}
