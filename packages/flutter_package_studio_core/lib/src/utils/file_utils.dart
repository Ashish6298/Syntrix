import 'dart:io' as io;
import 'package:flutter_package_studio_core/src/error/exceptions.dart';

/// Interface for file system operations, allowing unit tests to use mocks.
abstract interface class FileUtils {
  /// Returns `true` if the file or directory at [path] exists.
  bool exists(String path);

  /// Returns `true` if the entity at [path] is a directory.
  bool isDirectory(String path);

  /// Returns `true` if the entity at [path] is a file.
  bool isFile(String path);

  /// Reads the content of the file at [path] as a string.
  ///
  /// Throws a [StudioFileSystemException] if reading fails.
  String readAsString(String path);

  /// Writes [content] as a string to the file at [path].
  ///
  /// Throws a [StudioFileSystemException] if writing fails.
  void writeString(String path, String content, {bool recursive = true});

  /// Creates a directory at [path].
  ///
  /// Throws a [StudioFileSystemException] if creation fails.
  void createDirectory(String path, {bool recursive = true});

  /// Deletes the file or directory at [path].
  ///
  /// Throws a [StudioFileSystemException] if deletion fails.
  void delete(String path, {bool recursive = true});
}

/// Production implementation of [FileUtils] delegating to [io.File] and [io.Directory].
class SystemFileUtils implements FileUtils {
  /// Creates a [SystemFileUtils] instance.
  const SystemFileUtils();

  @override
  bool exists(String path) {
    return io.FileSystemEntity.typeSync(path) !=
        io.FileSystemEntityType.notFound;
  }

  @override
  bool isDirectory(String path) {
    return io.FileSystemEntity.isDirectorySync(path);
  }

  @override
  bool isFile(String path) {
    return io.FileSystemEntity.isFileSync(path);
  }

  @override
  String readAsString(String path) {
    try {
      return io.File(path).readAsStringSync();
    } catch (e, st) {
      throw StudioFileSystemException('Failed to read file at "$path"', e, st);
    }
  }

  @override
  void writeString(String path, String content, {bool recursive = true}) {
    try {
      final file = io.File(path);
      if (recursive) {
        file.parent.createSync(recursive: true);
      }
      file.writeAsStringSync(content);
    } catch (e, st) {
      throw StudioFileSystemException(
          'Failed to write to file at "$path"', e, st);
    }
  }

  @override
  void createDirectory(String path, {bool recursive = true}) {
    try {
      io.Directory(path).createSync(recursive: recursive);
    } catch (e, st) {
      throw StudioFileSystemException(
          'Failed to create directory at "$path"', e, st);
    }
  }

  @override
  void delete(String path, {bool recursive = true}) {
    try {
      final type = io.FileSystemEntity.typeSync(path);
      if (type == io.FileSystemEntityType.directory) {
        io.Directory(path).deleteSync(recursive: recursive);
      } else if (type == io.FileSystemEntityType.file) {
        io.File(path).deleteSync();
      }
    } catch (e, st) {
      throw StudioFileSystemException(
          'Failed to delete path at "$path"', e, st);
    }
  }
}
