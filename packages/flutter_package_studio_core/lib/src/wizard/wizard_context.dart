/// Holds all project creation options collected during a wizard session.
class WizardContext {
  /// Package identifier name (e.g., `my_awesome_package`).
  String packageName;

  /// Project type (`flutter_package`, `dart_package`, `plugin`, `module`).
  String projectType;

  /// Package description text.
  String description;

  /// Organization reverse-domain prefix (e.g., `com.example`).
  String orgName;

  /// Primary author name.
  String author;

  /// Author contact email.
  String email;

  /// Open-source or private license type (e.g. `MIT`, `BSD-3-Clause`, `Apache-2.0`, `Proprietary`).
  String license;

  /// Git repository URL.
  String repoUrl;

  /// Package homepage URL.
  String homepage;

  /// Issue tracker URL.
  String issueTrackerUrl;

  /// Documentation URL.
  String documentationUrl;

  /// Dart SDK version constraint (e.g. `>=3.5.0 <4.0.0`).
  String dartSdkConstraint;

  /// Flutter SDK version constraint (e.g. `>=3.22.0`).
  String flutterSdkConstraint;

  /// Target platforms supported (e.g. `android`, `ios`, `linux`, `macos`, `web`, `windows`).
  List<String> platforms;

  /// Preferred package architectural pattern (`feature_first`, `clean_architecture`, `layered`, `simple`).
  String preferredArchitecture;

  /// Testing suite preferences (`unit`, `widget`, `integration`, `golden`).
  List<String> testingPreferences;

  /// CI/CD workflow provider options (`github_actions`, `gitlab_ci`, `none`).
  String ciCdPreferences;

  /// Code quality tools enabled (`very_good_analysis`, `pedantic`, `custom`).
  String codeQualityOptions;

  /// Documentation generation options (`dartdoc`, `custom`, `none`).
  String docGenPreferences;

  /// Package visibility (`public`, `private`).
  String packageVisibility;

  /// Chosen project template (`standard`, `minimal`, `advanced`, `plugin`).
  String templateSelection;

  /// Target output directory path.
  String outputDirectory;

  /// Additional custom key-value metadata.
  Map<String, dynamic> extraMetadata;

  /// Creates a [WizardContext] with customizable defaults.
  WizardContext({
    this.packageName = '',
    this.projectType = 'flutter_package',
    this.description = '',
    this.orgName = 'com.example',
    this.author = '',
    this.email = '',
    this.license = 'MIT',
    this.repoUrl = '',
    this.homepage = '',
    this.issueTrackerUrl = '',
    this.documentationUrl = '',
    this.dartSdkConstraint = '>=3.5.0 <4.0.0',
    this.flutterSdkConstraint = '>=3.22.0',
    List<String>? platforms,
    this.preferredArchitecture = 'feature_first',
    List<String>? testingPreferences,
    this.ciCdPreferences = 'github_actions',
    this.codeQualityOptions = 'very_good_analysis',
    this.docGenPreferences = 'dartdoc',
    this.packageVisibility = 'public',
    this.templateSelection = 'standard',
    this.outputDirectory = '.',
    Map<String, dynamic>? extraMetadata,
  })  : platforms =
            platforms ?? ['android', 'ios', 'web', 'windows', 'macos', 'linux'],
        testingPreferences = testingPreferences ?? ['unit'],
        extraMetadata = extraMetadata ?? {};

  /// Serializes context properties to a map.
  Map<String, dynamic> toMap() {
    return {
      'packageName': packageName,
      'projectType': projectType,
      'description': description,
      'orgName': orgName,
      'author': author,
      'email': email,
      'license': license,
      'repoUrl': repoUrl,
      'homepage': homepage,
      'issueTrackerUrl': issueTrackerUrl,
      'documentationUrl': documentationUrl,
      'dartSdkConstraint': dartSdkConstraint,
      'flutterSdkConstraint': flutterSdkConstraint,
      'platforms': List<String>.from(platforms),
      'preferredArchitecture': preferredArchitecture,
      'testingPreferences': List<String>.from(testingPreferences),
      'ciCdPreferences': ciCdPreferences,
      'codeQualityOptions': codeQualityOptions,
      'docGenPreferences': docGenPreferences,
      'packageVisibility': packageVisibility,
      'templateSelection': templateSelection,
      'outputDirectory': outputDirectory,
      'extraMetadata': Map<String, dynamic>.from(extraMetadata),
    };
  }

  /// Restores [WizardContext] from a serialized map.
  factory WizardContext.fromMap(Map<String, dynamic> map) {
    return WizardContext(
      packageName: map['packageName'] as String? ?? '',
      projectType: map['projectType'] as String? ?? 'flutter_package',
      description: map['description'] as String? ?? '',
      orgName: map['orgName'] as String? ?? 'com.example',
      author: map['author'] as String? ?? '',
      email: map['email'] as String? ?? '',
      license: map['license'] as String? ?? 'MIT',
      repoUrl: map['repoUrl'] as String? ?? '',
      homepage: map['homepage'] as String? ?? '',
      issueTrackerUrl: map['issueTrackerUrl'] as String? ?? '',
      documentationUrl: map['documentationUrl'] as String? ?? '',
      dartSdkConstraint:
          map['dartSdkConstraint'] as String? ?? '>=3.5.0 <4.0.0',
      flutterSdkConstraint:
          map['flutterSdkConstraint'] as String? ?? '>=3.22.0',
      platforms: (map['platforms'] as List?)?.map((e) => e.toString()).toList(),
      preferredArchitecture:
          map['preferredArchitecture'] as String? ?? 'feature_first',
      testingPreferences: (map['testingPreferences'] as List?)
          ?.map((e) => e.toString())
          .toList(),
      ciCdPreferences: map['ciCdPreferences'] as String? ?? 'github_actions',
      codeQualityOptions:
          map['codeQualityOptions'] as String? ?? 'very_good_analysis',
      docGenPreferences: map['docGenPreferences'] as String? ?? 'dartdoc',
      packageVisibility: map['packageVisibility'] as String? ?? 'public',
      templateSelection: map['templateSelection'] as String? ?? 'standard',
      outputDirectory: map['outputDirectory'] as String? ?? '.',
      extraMetadata: (map['extraMetadata'] as Map?)?.cast<String, dynamic>(),
    );
  }

  /// Returns a copy of [WizardContext] with modified values.
  WizardContext copyWith({
    String? packageName,
    String? projectType,
    String? description,
    String? orgName,
    String? author,
    String? email,
    String? license,
    String? repoUrl,
    String? homepage,
    String? issueTrackerUrl,
    String? documentationUrl,
    String? dartSdkConstraint,
    String? flutterSdkConstraint,
    List<String>? platforms,
    String? preferredArchitecture,
    List<String>? testingPreferences,
    String? ciCdPreferences,
    String? codeQualityOptions,
    String? docGenPreferences,
    String? packageVisibility,
    String? templateSelection,
    String? outputDirectory,
    Map<String, dynamic>? extraMetadata,
  }) {
    return WizardContext(
      packageName: packageName ?? this.packageName,
      projectType: projectType ?? this.projectType,
      description: description ?? this.description,
      orgName: orgName ?? this.orgName,
      author: author ?? this.author,
      email: email ?? this.email,
      license: license ?? this.license,
      repoUrl: repoUrl ?? this.repoUrl,
      homepage: homepage ?? this.homepage,
      issueTrackerUrl: issueTrackerUrl ?? this.issueTrackerUrl,
      documentationUrl: documentationUrl ?? this.documentationUrl,
      dartSdkConstraint: dartSdkConstraint ?? this.dartSdkConstraint,
      flutterSdkConstraint: flutterSdkConstraint ?? this.flutterSdkConstraint,
      platforms: platforms ?? List.from(this.platforms),
      preferredArchitecture:
          preferredArchitecture ?? this.preferredArchitecture,
      testingPreferences:
          testingPreferences ?? List.from(this.testingPreferences),
      ciCdPreferences: ciCdPreferences ?? this.ciCdPreferences,
      codeQualityOptions: codeQualityOptions ?? this.codeQualityOptions,
      docGenPreferences: docGenPreferences ?? this.docGenPreferences,
      packageVisibility: packageVisibility ?? this.packageVisibility,
      templateSelection: templateSelection ?? this.templateSelection,
      outputDirectory: outputDirectory ?? this.outputDirectory,
      extraMetadata: extraMetadata ?? Map.from(this.extraMetadata),
    );
  }
}
