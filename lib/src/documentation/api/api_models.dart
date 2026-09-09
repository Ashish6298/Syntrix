/// Kinds of public Dart API symbols.

enum ApiSymbolKind {
  classSymbol,
  functionSymbol,
  enumSymbol,
  typedefSymbol,
  extensionSymbol,
  methodSymbol,
  propertySymbol,
}

/// Represents a parameter to a Dart method or function.
class ApiParameter {
  final String name;
  final String type;
  final bool isRequired;
  final bool isNamed;
  final String? defaultValue;
  final String? description;

  const ApiParameter({
    required this.name,
    required this.type,
    this.isRequired = true,
    this.isNamed = false,
    this.defaultValue,
    this.description,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type,
        'isRequired': isRequired,
        'isNamed': isNamed,
        if (defaultValue != null) 'defaultValue': defaultValue,
        if (description != null) 'description': description,
      };
}

/// Represents a documented public Dart API symbol.
class ApiSymbol implements Comparable<ApiSymbol> {
  final String name;
  final ApiSymbolKind kind;
  final String typeSignature;
  final String docComment;
  final bool isDeprecated;
  final String? deprecationReason;
  final List<ApiParameter> parameters;
  final List<ApiSymbol> members;

  const ApiSymbol({
    required this.name,
    required this.kind,
    required this.typeSignature,
    this.docComment = '',
    this.isDeprecated = false,
    this.deprecationReason,
    this.parameters = const [],
    this.members = const [],
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'kind': kind.name,
        'typeSignature': typeSignature,
        'docComment': docComment,
        'isDeprecated': isDeprecated,
        if (deprecationReason != null) 'deprecationReason': deprecationReason,
        'parameters': parameters.map((p) => p.toJson()).toList(),
        'members': members.map((m) => m.toJson()).toList(),
      };

  @override
  int compareTo(ApiSymbol other) {
    final k = kind.index.compareTo(other.kind.index);
    if (k != 0) return k;
    return name.compareTo(other.name);
  }
}

/// Options for configuring API documentation generation.
class ApiDocOptions {
  final String packageName;
  final String version;
  final bool includePrivate;
  final List<ApiSymbol> symbols;

  const ApiDocOptions({
    required this.packageName,
    this.version = '1.0.0',
    this.includePrivate = false,
    this.symbols = const [],
  });

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'version': version,
        'includePrivate': includePrivate,
        'symbolCount': symbols.length,
      };
}

/// Preview plan of API documentation.
class ApiDocPlan {
  final String packageName;
  final List<ApiSymbol> symbols;

  ApiDocPlan({
    required this.packageName,
    required List<ApiSymbol> symbols,
  }) : symbols = _sorted(symbols);

  static List<ApiSymbol> _sorted(List<ApiSymbol> list) {
    final copy = List<ApiSymbol>.from(list);
    copy.sort();
    return List.unmodifiable(copy);
  }

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'symbolCount': symbols.length,
        'symbols': symbols.map((s) => s.toJson()).toList(),
      };
}

/// Result of API documentation generation containing rendered Markdown.
class ApiDocResult {
  final String packageName;
  final String markdown;
  final int symbolCount;

  const ApiDocResult({
    required this.packageName,
    required this.markdown,
    required this.symbolCount,
  });

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'markdown': markdown,
        'symbolCount': symbolCount,
      };
}
