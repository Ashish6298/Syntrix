import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:test/test.dart';

void main() {
  group('CoverageAnalyzer Unit Tests', () {
    late CoverageAnalyzer analyzer;

    setUp(() {
      analyzer = CoverageAnalyzer();
    });

    test('Plans coverage analysis and validates input paths', () {
      const options = CoverageOptions(
          packageName: 'awesome_pkg', inputPath: 'coverage/lcov.info');
      final plan = analyzer.planCoverageAnalysis(options);

      expect(plan.packageName, equals('awesome_pkg'));
      expect(plan.inputPath, equals('coverage/lcov.info'));
    });

    test('Parses valid LCOV content and calculates line coverage correctly',
        () {
      const lcov = '''
TN:
SF:lib/src/sample.dart
DA:1,1
DA:2,1
DA:3,0
DA:4,1
end_of_record
''';

      const options = CoverageOptions(packageName: 'awesome_pkg');
      final plan = analyzer.planCoverageAnalysis(options);
      final result = analyzer.analyzeCoverage(plan, lcov);

      expect(result.packageName, equals('awesome_pkg'));
      expect(result.totalLines, equals(4));
      expect(result.coveredLines, equals(3));
      expect(result.overallPercentage, equals(75.0));
      expect(result.isPassed, isFalse); // threshold default 80.0%
    });

    test('Rejects absolute input paths', () {
      const options =
          CoverageOptions(packageName: 'pkg', inputPath: '/var/log/lcov.info');
      expect(() => analyzer.planCoverageAnalysis(options),
          throwsA(isA<CoverageAnalysisException>()));
    });

    test('Rejects path traversal ".." in input path', () {
      const options =
          CoverageOptions(packageName: 'pkg', inputPath: '../lcov.info');
      expect(() => analyzer.planCoverageAnalysis(options),
          throwsA(isA<CoverageAnalysisException>()));
    });
  });
}
