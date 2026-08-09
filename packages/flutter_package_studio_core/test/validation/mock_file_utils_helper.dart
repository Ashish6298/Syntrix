import 'package:path/path.dart' as p;
import 'package:flutter_package_studio_core/src/utils/file_utils.dart';

/// In-memory mock implementation of [FileUtils] for unit testing.
class MapMemoryFileUtils implements FileUtils {
  final Map<String, String> _rawFiles;

  MapMemoryFileUtils([Map<String, String> files = const {}])
      : _rawFiles = files.map((k, v) => MapEntry(p.normalize(k), v));

  @override
  bool exists(String path) {
    final norm = p.normalize(path);
    if (_rawFiles.containsKey(norm)) return true;
    // Check if any registered file starts with this directory path
    final prefix = norm.endsWith(p.separator) ? norm : '$norm${p.separator}';
    return _rawFiles.keys.any((k) => k.startsWith(prefix)) || norm == '.';
  }

  @override
  bool isDirectory(String path) {
    final norm = p.normalize(path);
    if (norm == '.') return true;
    final prefix = norm.endsWith(p.separator) ? norm : '$norm${p.separator}';
    return _rawFiles.keys.any((k) => k.startsWith(prefix));
  }

  @override
  bool isFile(String path) => exists(path) && !isDirectory(path);

  @override
  String readAsString(String path) {
    final norm = p.normalize(path);
    return _rawFiles[norm] ?? '';
  }

  @override
  void writeString(String path, String content, {bool recursive = true}) {}

  @override
  void createDirectory(String path, {bool recursive = true}) {}

  @override
  void delete(String path, {bool recursive = true}) {}
}
