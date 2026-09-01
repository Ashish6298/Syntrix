import 'package:flutter_package_studio_cli/src/base_command.dart';
import 'package:flutter_package_studio_cli/src/commands/project_context_command.dart';

export 'package:flutter_package_studio_cli/src/commands/project_context_command.dart';

/// Top-level `fps project` command umbrella.
///
/// Hosts subcommands for project inspection, discovery, and intelligence.
class ProjectCommand extends FpsCommand {
  @override
  final String name = 'project';

  @override
  final String description =
      'Inspect, discover, and analyze project workspace context and intelligence.';

  ProjectCommand() {
    addSubcommand(ProjectContextCommand());
  }

  @override
  Future<int> run() async {
    print('Flutter Package Studio — Project Context & Intelligence CLI');
    print('');
    printUsage();
    return 0;
  }
}
