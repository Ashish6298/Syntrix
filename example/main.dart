import 'package:syntrix/syntrix.dart';

void main() async {
  // 1. Initialize Dependency Injection Container
  final container = DependencyContainer();
  container.reset();
  container.registerSingleton<Logger>(Logger('SyntrixExample'));

  final logger = container.resolve<Logger>();
  logger.info('Syntrix Engine Initialized.');
  print('=== Syntrix Architecture & Verification Example ===');

  // 2. Discover Builtin Architecture Templates
  final catalogProvider = BuiltinCatalogProvider();
  final entries = catalogProvider.fetchEntries();
  print('Discovered ${entries.length} builtin architectural templates:');

  for (final entry in entries.take(3)) {
    final manifest = entry.template.manifest;
    print(
        ' - ${manifest.name} (v${manifest.version}): ${manifest.description}');
  }

  // 3. Plan Release Verification Pipeline
  final pipeline = ReleaseVerificationPipeline();
  final plan = pipeline.planPipeline(
    const ReleaseVerificationOptions(
      packageName: 'syntrix_sample',
      version: '1.0.0',
    ),
  );
  print('Planned ${plan.stages.length} release verification stages:');
  for (final stage in plan.stages) {
    print('   [${stage.id}] ${stage.name}');
  }

  // 4. Execute Verification Pipeline
  final result = pipeline.executePipeline(plan);
  print('Verification result: isReady = ${result.isReady}');
  print('=== Done ===');
}
