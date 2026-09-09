import 'package:args/command_runner.dart';
import 'package:flutter_package_studio_cli/flutter_package_studio_cli.dart';
import 'package:test/test.dart';

void main() {
  group('Phase 8.14 — AI Engineering Command Center CLI Tests', () {
    late CommandRunner<int> runner;

    setUp(() {
      runner = CommandRunner<int>('fps', 'Flutter Package Studio CLI')
        ..addCommand(AiCommand());
    });

    test('AiCommand registers with all 13 subcommands and alias ai-assistant',
        () {
      final cmd = runner.commands['ai'];
      expect(cmd, isNotNull);
      expect(cmd!.name, equals('ai'));
      expect(cmd.aliases, contains('ai-assistant'));

      // Check subcommands
      final subcommands = cmd.subcommands;
      expect(subcommands.containsKey('analyze'), isTrue);
      expect(subcommands.containsKey('review'), isTrue);
      expect(subcommands.containsKey('debug'), isTrue);
      expect(subcommands.containsKey('test'), isTrue);
      expect(subcommands.containsKey('document'), isTrue);
      expect(subcommands.containsKey('security'), isTrue);
      expect(subcommands.containsKey('architecture'), isTrue);
      expect(subcommands.containsKey('dependencies'), isTrue);
      expect(subcommands.containsKey('release'), isTrue);
      expect(subcommands.containsKey('plan'), isTrue);
      expect(subcommands.containsKey('explain'), isTrue);
      expect(subcommands.containsKey('memory'), isTrue);
      expect(subcommands.containsKey('modify'), isTrue);
    });

    test('fps ai analyze runs successfully and exits 0', () async {
      final code =
          await runner.run(['ai', 'analyze', '--prompt', 'analyze template']);
      expect(code, equals(0));
    });

    test('fps ai review runs successfully and exits 0', () async {
      final code =
          await runner.run(['ai', 'review', '--prompt', 'inspect code']);
      expect(code, equals(0));
    });

    test('fps ai security runs successfully and exits 0', () async {
      final code = await runner.run(['ai', 'security']);
      expect(code, equals(0));
    });

    test('fps ai release runs successfully and exits 0', () async {
      final code = await runner.run(['ai', 'release']);
      expect(code, equals(0));
    });

    test('fps ai plan runs successfully and exits 0', () async {
      final code = await runner.run(['ai', 'plan', '--prompt', 'Plan roadmap']);
      expect(code, equals(0));
    });
  });
}
