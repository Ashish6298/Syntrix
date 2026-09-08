/// Domain models and API freeze catalog for Phase 11.1: Final API Freeze.
library;

import 'dart:convert';

/// API artifact kind in the public surface.
enum FrozenApiSymbolKind {
  publicClass,
  constructor,
  enumeration,
  extension,
  typedefDeclaration,
  callback,
  configurationObject,
  controller,
  theme,
  loader,
  renderer,
  engine,
  utility;

  String get id => name;

  String get label {
    switch (this) {
      case FrozenApiSymbolKind.publicClass:
        return 'Class';
      case FrozenApiSymbolKind.constructor:
        return 'Constructor';
      case FrozenApiSymbolKind.enumeration:
        return 'Enum';
      case FrozenApiSymbolKind.extension:
        return 'Extension';
      case FrozenApiSymbolKind.typedefDeclaration:
        return 'Typedef';
      case FrozenApiSymbolKind.callback:
        return 'Callback';
      case FrozenApiSymbolKind.configurationObject:
        return 'Config Object';
      case FrozenApiSymbolKind.controller:
        return 'Controller';
      case FrozenApiSymbolKind.theme:
        return 'Theme';
      case FrozenApiSymbolKind.loader:
        return 'Loader';
      case FrozenApiSymbolKind.renderer:
        return 'Renderer';
      case FrozenApiSymbolKind.engine:
        return 'Engine';
      case FrozenApiSymbolKind.utility:
        return 'Utility';
    }
  }
}

/// Freeze decision for an audited API symbol.
enum ApiFreezeDecision {
  freezeAsPublic,
  privatizeToSrc,
  deprecate;

  String get id => name;

  String get label {
    switch (this) {
      case ApiFreezeDecision.freezeAsPublic:
        return 'FREEZE (Public API)';
      case ApiFreezeDecision.privatizeToSrc:
        return 'INTERNAL (Move to src/)';
      case ApiFreezeDecision.deprecate:
        return 'DEPRECATED';
    }
  }

  String get symbol => this == ApiFreezeDecision.freezeAsPublic ? '✓' : (this == ApiFreezeDecision.privatizeToSrc ? '🔒' : '⚠');
}

/// Description of an audited API symbol.
class FrozenApiSymbol {
  final String name;
  final FrozenApiSymbolKind kind;
  final String definedInFile;
  final ApiFreezeDecision decision;
  final bool isStable;
  final String rationale;

  const FrozenApiSymbol({
    required this.name,
    required this.kind,
    required this.definedInFile,
    this.decision = ApiFreezeDecision.freezeAsPublic,
    this.isStable = true,
    required this.rationale,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'kind': kind.id,
        'defined_in_file': definedInFile,
        'decision': decision.id,
        'is_stable': isStable,
        'rationale': rationale,
      };

  factory FrozenApiSymbol.fromJson(Map<String, dynamic> json) {
    return FrozenApiSymbol(
      name: json['name'] as String? ?? '',
      kind: FrozenApiSymbolKind.values.firstWhere(
        (k) => k.id == json['kind'] || k.name == json['kind'],
        orElse: () => FrozenApiSymbolKind.publicClass,
      ),
      definedInFile: json['defined_in_file'] as String? ?? '',
      decision: ApiFreezeDecision.values.firstWhere(
        (d) => d.id == json['decision'] || d.name == json['decision'],
        orElse: () => ApiFreezeDecision.freezeAsPublic,
      ),
      isStable: json['is_stable'] as bool? ?? true,
      rationale: json['rationale'] as String? ?? '',
    );
  }
}

/// Comprehensive Phase 11.1 API Freeze Audit Report.
class ApiFreezeAuditReport {
  final String reportId;
  final String targetVersion;
  final bool isFrozen;
  final int totalSymbolsAudited;
  final int publicSymbolsFrozen;
  final int internalSymbolsRestricted;
  final List<FrozenApiSymbol> auditedSymbols;
  final DateTime auditedAt;

  const ApiFreezeAuditReport({
    required this.reportId,
    required this.targetVersion,
    required this.isFrozen,
    required this.totalSymbolsAudited,
    required this.publicSymbolsFrozen,
    required this.internalSymbolsRestricted,
    required this.auditedSymbols,
    required this.auditedAt,
  });

  Map<String, dynamic> toJson() => {
        'report_id': reportId,
        'target_version': targetVersion,
        'is_frozen': isFrozen,
        'total_symbols_audited': totalSymbolsAudited,
        'public_symbols_frozen': publicSymbolsFrozen,
        'internal_symbols_restricted': internalSymbolsRestricted,
        'audited_symbols': auditedSymbols.map((s) => s.toJson()).toList(),
        'audited_at': auditedAt.toIso8601String(),
      };

  factory ApiFreezeAuditReport.fromJson(Map<String, dynamic> json) {
    return ApiFreezeAuditReport(
      reportId: json['report_id'] as String? ?? 'freeze_default',
      targetVersion: json['target_version'] as String? ?? '1.0.0',
      isFrozen: json['is_frozen'] as bool? ?? true,
      totalSymbolsAudited: json['total_symbols_audited'] as int? ?? 0,
      publicSymbolsFrozen: json['public_symbols_frozen'] as int? ?? 0,
      internalSymbolsRestricted: json['internal_symbols_restricted'] as int? ?? 0,
      auditedSymbols: (json['audited_symbols'] as List<dynamic>?)
              ?.map((s) => FrozenApiSymbol.fromJson(s as Map<String, dynamic>))
              .toList() ??
          const [],
      auditedAt: DateTime.parse(json['audited_at'] as String),
    );
  }
}
