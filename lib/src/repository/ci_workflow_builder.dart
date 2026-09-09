/// Utility for generating CI workflow YAML files.
class CiWorkflowBuilder {
  /// Builds GitHub Actions workflow content for Flutter/Dart package CI.
  static String buildGitHubWorkflow({
    required String packageName,
    bool isFlutter = true,
    String dartSdkVersion = '3.0.0',
  }) {
    final sdkSetupStep = isFlutter
        ? '''
      - uses: subosito/flutter-action@v2
        with:
          channel: 'stable'
          cache: true
'''
        : '''
      - uses: dart-lang/setup-dart@v1
        with:
          sdk: stable
''';

    final getDependenciesCmd = isFlutter ? 'flutter pub get' : 'dart pub get';
    final formatCmd = 'dart format --output=none --set-exit-if-changed .';
    final analyzeCmd = 'dart analyze';
    final testCmd = isFlutter ? 'flutter test' : 'dart test';

    return '''
name: CI

on:
  push:
    branches: [ main, master ]
  pull_request:
    branches: [ main, master ]

jobs:
  build_and_test:
    name: Build & Test
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

$sdkSetupStep

      - name: Install dependencies
        run: $getDependenciesCmd

      - name: Check code formatting
        run: $formatCmd

      - name: Analyze code
        run: $analyzeCmd

      - name: Run unit tests
        run: $testCmd
''';
  }
}
