import 'package:args/command_runner.dart';
import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';

/// Base class for all commands in Flutter Package Studio CLI.
abstract class FpsCommand extends Command<int> {
  /// The logger instance specific to this command.
  late final Logger logger = Logger('Command:$name');

  /// Convenience getter to resolve dependencies from DI container.
  T resolve<T extends Object>() => DependencyContainer().resolve<T>();
}
