import 'dart:io' as io;
import 'package:test/test.dart';
import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';

void main() {
  group('SystemPlatformUtils Tests', () {
    const platform = SystemPlatformUtils();

    test('retrieves OS type', () {
      // Must match at least one since we run on a desktop OS
      expect(platform.isWindows || platform.isMac || platform.isLinux, isTrue);
    });

    test('pathSeparator is defined', () {
      expect(platform.pathSeparator, isNotEmpty);
    });

    test('getEnv and environment work', () {
      final env = platform.environment;
      expect(env, isNotEmpty);

      // Usually PATH/Path exists on all systems
      final pathEnv = platform.getEnv('PATH') ?? platform.getEnv('Path');
      expect(pathEnv, isNotNull);
    });
  });

  group('SystemTerminalUtils Tests', () {
    const terminal = SystemTerminalUtils();

    test('retrieves terminal capabilities', () {
      // Expect fallback values or actual values without crash
      expect(terminal.width, greaterThan(0));
      expect(terminal.height, greaterThan(0));
      // supportsAnsi is boolean
      expect(terminal.supportsAnsi, isA<bool>());
    });
  });

  group('SystemFileUtils Tests', () {
    const fileUtils = SystemFileUtils();
    late io.Directory tempDir;

    setUp(() {
      tempDir = io.Directory.systemTemp.createTempSync('fps_system_file_test');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('exists, writeString, readAsString, isFile, isDirectory, and delete',
        () {
      final testFilePath =
          '${tempDir.path}${io.Platform.pathSeparator}test.txt';
      final testSubDir = '${tempDir.path}${io.Platform.pathSeparator}subdir';

      expect(fileUtils.exists(testFilePath), isFalse);

      // Create dir
      fileUtils.createDirectory(testSubDir);
      expect(fileUtils.exists(testSubDir), isTrue);
      expect(fileUtils.isDirectory(testSubDir), isTrue);
      expect(fileUtils.isFile(testSubDir), isFalse);

      // Write string
      fileUtils.writeString(testFilePath, 'System File Utils Content');
      expect(fileUtils.exists(testFilePath), isTrue);
      expect(fileUtils.isFile(testFilePath), isTrue);
      expect(fileUtils.isDirectory(testFilePath), isFalse);

      // Read string
      final readContent = fileUtils.readAsString(testFilePath);
      expect(readContent, 'System File Utils Content');

      // Delete file
      fileUtils.delete(testFilePath);
      expect(fileUtils.exists(testFilePath), isFalse);

      // Delete dir
      fileUtils.delete(testSubDir);
      expect(fileUtils.exists(testSubDir), isFalse);
    });

    test('Throws StudioFileSystemException on invalid operations', () {
      expect(
        () => fileUtils.readAsString(
            '/nonexistent/path/to/file/that/does/not/exist/at/all.txt'),
        throwsA(isA<StudioFileSystemException>()),
      );

      // Write to invalid path
      expect(
        () => fileUtils.writeString('', 'content'),
        throwsA(isA<StudioFileSystemException>()),
      );

      // Create directory at invalid path
      expect(
        () => fileUtils.createDirectory(''),
        throwsA(isA<StudioFileSystemException>()),
      );
    });
  });
}
