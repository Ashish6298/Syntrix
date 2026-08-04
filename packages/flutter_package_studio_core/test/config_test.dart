import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';

class MockPlatformUtils extends Mock implements PlatformUtils {}

class MockFileUtils extends Mock implements FileUtils {}

void main() {
  group('FpsConfig Tests', () {
    test('defaults properties', () {
      final config = FpsConfig.defaults();
      expect(config.outputDirectory, '.');
      expect(config.defaultAuthor, 'Flutter Package Studio Developer');
      expect(config.defaultLicense, 'MIT');
      expect(config.verbose, isFalse);
      expect(config.toString(), contains('output_directory'));
    });

    test('fromMap merges and fills custom fields', () {
      final map = {
        'output_directory': '/custom/out',
        'default_author': 'Alice',
        'default_license': 'BSD-3',
        'verbose': true,
        'custom': {'extra_flag': 42}
      };

      final config = FpsConfig.fromMap(map);
      expect(config.outputDirectory, '/custom/out');
      expect(config.defaultAuthor, 'Alice');
      expect(config.defaultLicense, 'BSD-3');
      expect(config.verbose, isTrue);
      expect(config.custom['extra_flag'], 42);
    });
  });

  group('ConfigLoader Tests', () {
    late MockPlatformUtils mockPlatform;
    late MockFileUtils mockFileUtils;
    late ConfigLoader loader;

    setUp(() {
      mockPlatform = MockPlatformUtils();
      mockFileUtils = MockFileUtils();
      loader = ConfigLoader(mockFileUtils, mockPlatform);

      // Default env mocks
      when(() => mockPlatform.getEnv('USERPROFILE'))
          .thenReturn('C:\\Users\\test');
      when(() => mockPlatform.getEnv('HOME')).thenReturn(null);
      when(() => mockPlatform.pathSeparator).thenReturn('\\');
      when(() => mockPlatform.getEnv(any())).thenReturn(null);
    });

    test('loads defaults if files and env are absent', () {
      when(() => mockFileUtils.exists(any())).thenReturn(false);

      final config = loader.load();
      expect(config.outputDirectory, '.');
      expect(config.defaultAuthor, 'Flutter Package Studio Developer');
    });

    test('loads and merges global and local yaml files', () {
      final globalPath = 'C:\\Users\\test\\.fps\\config.yaml';
      final localPath = 'fps.yaml';

      when(() => mockFileUtils.exists(globalPath)).thenReturn(true);
      when(() => mockFileUtils.readAsString(globalPath)).thenReturn('''
default_author: "Global Author"
default_license: "Apache-2.0"
verbose: false
''');

      when(() => mockFileUtils.exists(localPath)).thenReturn(true);
      when(() => mockFileUtils.readAsString(localPath)).thenReturn('''
default_author: "Local Author"
verbose: true
custom:
  project_id: "fps_project"
''');

      final config =
          loader.load(localConfigPath: localPath, globalConfigPath: globalPath);

      // Local author should overwrite global author
      expect(config.defaultAuthor, 'Local Author');
      // Global license should persist
      expect(config.defaultLicense, 'Apache-2.0');
      // Verbose from local config (true) should overwrite global config (false)
      expect(config.verbose, isTrue);
      // Custom mapping from local should be parsed
      expect(config.custom['project_id'], 'fps_project');
    });

    test('environment variables override files', () {
      when(() => mockFileUtils.exists(any())).thenReturn(false);

      when(() => mockPlatform.getEnv('FPS_OUTPUT_DIR')).thenReturn('/env/out');
      when(() => mockPlatform.getEnv('FPS_DEFAULT_AUTHOR'))
          .thenReturn('Env Author');
      when(() => mockPlatform.getEnv('FPS_DEFAULT_LICENSE'))
          .thenReturn('GPL-3');
      when(() => mockPlatform.getEnv('FPS_VERBOSE')).thenReturn('true');

      final config = loader.load();
      expect(config.outputDirectory, '/env/out');
      expect(config.defaultAuthor, 'Env Author');
      expect(config.defaultLicense, 'GPL-3');
      expect(config.verbose, isTrue);
    });

    test('throws ConfigurationException on invalid YAML map', () {
      when(() => mockFileUtils.exists('fps.yaml')).thenReturn(true);
      when(() => mockFileUtils.readAsString('fps.yaml'))
          .thenReturn('not a map string');

      expect(
        () => loader.load(localConfigPath: 'fps.yaml'),
        throwsA(isA<ConfigurationException>()),
      );
    });

    test('falls back to HOME if USERPROFILE is null', () {
      when(() => mockFileUtils.exists(any())).thenReturn(false);
      when(() => mockPlatform.getEnv('USERPROFILE')).thenReturn(null);
      when(() => mockPlatform.getEnv('HOME')).thenReturn('/home/test');
      when(() => mockPlatform.pathSeparator).thenReturn('/');

      final config = loader.load(globalConfigPath: null);
      expect(config.outputDirectory, '.');
    });

    test('handles empty YAML or syntax error', () {
      when(() => mockFileUtils.exists('fps.yaml')).thenReturn(true);
      when(() => mockFileUtils.readAsString('fps.yaml')).thenReturn('');

      final configEmpty = loader.load(localConfigPath: 'fps.yaml');
      expect(configEmpty.outputDirectory, '.');

      // Syntax error
      when(() => mockFileUtils.readAsString('fps.yaml'))
          .thenReturn('invalid: { {');
      expect(
        () => loader.load(localConfigPath: 'fps.yaml'),
        throwsA(isA<ConfigurationException>()),
      );
    });

    test('parses YAML lists', () {
      when(() => mockFileUtils.exists('fps.yaml')).thenReturn(true);
      when(() => mockFileUtils.readAsString('fps.yaml')).thenReturn('''
custom:
  list_value: [1, 2, 3]
''');

      final config = loader.load(localConfigPath: 'fps.yaml');
      expect(config.custom['list_value'], isA<List>());
      expect(config.custom['list_value'], [1, 2, 3]);
    });
  });
}
