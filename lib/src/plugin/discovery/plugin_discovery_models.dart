import 'package:syntrix/src/plugin/contract/plugin_contract_models.dart';

/// Categories of discovered plugin entries.
enum DiscoveredPluginStatus {
  valid,
  invalid,
  duplicate,
  unsupported,
}

/// Single discovered directory entry report.
class DiscoveredPluginEntry {
  final String directoryPath;
  final String manifestPath;
  final DiscoveredPluginStatus status;
  final PluginManifest? manifest;
  final List<String> details;

  const DiscoveredPluginEntry({
    required this.directoryPath,
    required this.manifestPath,
    required this.status,
    this.manifest,
    required this.details,
  });

  Map<String, dynamic> toJson() => {
        'directoryPath': directoryPath,
        'manifestPath': manifestPath,
        'status': status.name,
        if (manifest != null) 'manifest': manifest!.toJson(),
        'details': details,
      };
}

/// Aggregated discovery report across all scanned directory roots.
class DiscoveryResult {
  final List<String> scannedRoots;
  final List<DiscoveredPluginEntry> entries;

  const DiscoveryResult({
    required this.scannedRoots,
    required this.entries,
  });

  List<DiscoveredPluginEntry> get validEntries =>
      entries.where((e) => e.status == DiscoveredPluginStatus.valid).toList();

  List<DiscoveredPluginEntry> get invalidEntries =>
      entries.where((e) => e.status == DiscoveredPluginStatus.invalid).toList();

  List<DiscoveredPluginEntry> get duplicateEntries => entries
      .where((e) => e.status == DiscoveredPluginStatus.duplicate)
      .toList();

  List<DiscoveredPluginEntry> get unsupportedEntries => entries
      .where((e) => e.status == DiscoveredPluginStatus.unsupported)
      .toList();

  String toFormattedText() {
    final buf = StringBuffer();
    buf.writeln('PLUGIN DISCOVERY REPORT');
    buf.writeln('=======================');
    buf.writeln('Scanned Roots : ${scannedRoots.join(", ")}');
    buf.writeln('Total Entries : ${entries.length}');
    buf.writeln('Valid         : ${validEntries.length}');
    buf.writeln('Invalid       : ${invalidEntries.length}');
    buf.writeln('Duplicates    : ${duplicateEntries.length}');
    buf.writeln('Unsupported   : ${unsupportedEntries.length}');
    buf.writeln();

    for (final entry in entries) {
      final idStr = entry.manifest != null ? entry.manifest!.id.value : 'N/A';
      buf.writeln(
          '[${entry.status.name.toUpperCase()}] ID: $idStr (${entry.directoryPath})');
      for (final d in entry.details) {
        buf.writeln('  • $d');
      }
    }
    return buf.toString();
  }

  Map<String, dynamic> toJson() => {
        'scannedRoots': scannedRoots,
        'totalEntries': entries.length,
        'validCount': validEntries.length,
        'invalidCount': invalidEntries.length,
        'duplicateCount': duplicateEntries.length,
        'unsupportedCount': unsupportedEntries.length,
        'entries': entries.map((e) => e.toJson()).toList(),
      };
}
