import 'package:flutter_package_studio_core/src/utils/file_utils.dart';

/// Abstract filesystem interface for migration operations.
abstract interface class TemplateMigrationFileSystem implements FileUtils {
  /// Writes string content atomically if possible, backing up existing content if present.
  void writeStringAtomic(String path, String content);

  /// Backs up a file at [path] to a temporary backup path and returns the backup path.
  String backupFile(String path);

  /// Restores a file at [path] from a backup file at [backupPath].
  void restoreFile(String path, String backupPath);

  /// Removes temporary backup file at [backupPath].
  void removeBackup(String backupPath);
}

/// In-memory mock migration filesystem for isolated unit tests.
class MemoryMigrationFileSystem implements TemplateMigrationFileSystem {
  final Map<String, String> _files = {};
  final Map<String, String> _backups = {};

  MemoryMigrationFileSystem([Map<String, String>? initialFiles]) {
    if (initialFiles != null) {
      _files.addAll(initialFiles);
    }
  }

  Map<String, String> get files => Map.unmodifiable(_files);

  @override
  bool exists(String path) => _files.containsKey(_normalize(path));

  @override
  bool isDirectory(String path) => false;

  @override
  bool isFile(String path) => exists(path);

  @override
  String readAsString(String path) {
    final norm = _normalize(path);
    if (!_files.containsKey(norm)) {
      throw Exception('File not found: $path');
    }
    return _files[norm]!;
  }

  @override
  void writeString(String path, String content, {bool recursive = true}) {
    _files[_normalize(path)] = content;
  }

  @override
  void createDirectory(String path, {bool recursive = true}) {}

  @override
  void delete(String path, {bool recursive = true}) {
    _files.remove(_normalize(path));
  }

  @override
  void writeStringAtomic(String path, String content) {
    writeString(path, content);
  }

  @override
  String backupFile(String path) {
    final norm = _normalize(path);
    final backupKey = '$norm.bak';
    if (_files.containsKey(norm)) {
      _backups[backupKey] = _files[norm]!;
    }
    return backupKey;
  }

  @override
  void restoreFile(String path, String backupPath) {
    if (_backups.containsKey(backupPath)) {
      _files[_normalize(path)] = _backups[backupPath]!;
    }
  }

  @override
  void removeBackup(String backupPath) {
    _backups.remove(backupPath);
  }

  String _normalize(String path) => path.replaceAll('\\', '/');
}
