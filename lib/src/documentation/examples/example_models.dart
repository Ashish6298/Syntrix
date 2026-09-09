/// Supported code example types.
enum CodeExampleType {
  basicUsage,
  initialization,
  configuration,
  fullExample,
}

/// Structured code snippet block.
class CodeExampleSnippet {
  final List<String> imports;
  final String setup;
  final String usage;
  final String? comments;

  const CodeExampleSnippet({
    this.imports = const [],
    required this.setup,
    required this.usage,
    this.comments,
  });

  Map<String, dynamic> toJson() => {
        'imports': imports,
        'setup': setup,
        'usage': usage,
        if (comments != null) 'comments': comments,
      };
}

/// Options for configuring code example generation.
class CodeExampleOptions {
  final String packageName;
  final CodeExampleType exampleType;
  final List<String> imports;

  const CodeExampleOptions({
    required this.packageName,
    this.exampleType = CodeExampleType.basicUsage,
    this.imports = const [],
  });

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'exampleType': exampleType.name,
        'imports': imports,
      };
}

/// Preview plan of a code example before rendering.
class CodeExamplePlan {
  final String packageName;
  final CodeExampleType exampleType;
  final CodeExampleSnippet snippet;

  const CodeExamplePlan({
    required this.packageName,
    required this.exampleType,
    required this.snippet,
  });

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'exampleType': exampleType.name,
        'snippet': snippet.toJson(),
      };
}

/// Result of code example generation containing rendered Dart source code string.
class CodeExampleResult {
  final String packageName;
  final String code;

  const CodeExampleResult({
    required this.packageName,
    required this.code,
  });

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'code': code,
      };
}
