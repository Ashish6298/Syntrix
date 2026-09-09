/// Central Multi-Project & Organization Management Engine for Phase 9.8.
library;

import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:syntrix/src/logging/logger.dart';
import 'package:syntrix/src/enterprise/policy/enterprise_policy_models.dart';
import 'package:syntrix/src/enterprise/organization/enterprise_organization_models.dart';

/// Central Enterprise Multi-Project & Organization Management Engine.
///
/// Features:
/// 1. Hierarchical organization tree: Organization -> Teams -> Projects -> Packages + Shared Packages.
/// 2. Deterministic policy inheritance: Org Defaults -> Team Policy -> Project Overrides -> Package Overrides.
/// 3. Project and team membership management.
/// 4. Persistent organization manifest storage in `.fps/organization/organization_manifest.json`.
class EnterpriseOrganizationEngine {
  final Logger _logger = Logger('EnterpriseOrganizationEngine');
  final String _projectRoot;
  EnterpriseOrganization _organization;

  String get projectRoot => _projectRoot;
  EnterpriseOrganization get organization => _organization;

  EnterpriseOrganizationEngine({
    required String projectRoot,
    EnterpriseOrganization? initialOrganization,
  })  : _projectRoot = p.normalize(projectRoot),
        _organization = initialOrganization ??
            EnterpriseOrganization(
              organizationId: 'default_org',
              name: 'Enterprise Organization',
              createdAt: DateTime.now(),
            ) {
    if (initialOrganization == null) {
      _loadOrganizationManifest();
    }
  }

  File get _manifestFile => File(p.join(
      _projectRoot, '.fps', 'organization', 'organization_manifest.json'));

  /// Registers or updates the organization root profile.
  void setOrganization(EnterpriseOrganization org) {
    _organization = org;
    _saveOrganizationManifest();
    _logger.info(
        'Updated organization profile: ${org.name} (${org.organizationId})');
  }

  /// Adds or updates a team within the organization.
  void registerTeam(EnterpriseTeam team) {
    final existingIndex =
        _organization.teams.indexWhere((t) => t.teamId == team.teamId);
    final updatedTeams = List<EnterpriseTeam>.from(_organization.teams);

    if (existingIndex >= 0) {
      updatedTeams[existingIndex] = team;
    } else {
      updatedTeams.add(team);
    }

    _organization = EnterpriseOrganization(
      organizationId: _organization.organizationId,
      name: _organization.name,
      domain: _organization.domain,
      defaultPolicy: _organization.defaultPolicy,
      teams: updatedTeams,
      sharedPackages: _organization.sharedPackages,
      globalAdmins: _organization.globalAdmins,
      createdAt: _organization.createdAt,
      metadata: _organization.metadata,
    );

    _saveOrganizationManifest();
    _logger.info('Registered enterprise team: ${team.name} (${team.teamId})');
  }

  /// Adds a shared package available to all teams across the organization.
  void registerSharedPackage(ManagedPackage package) {
    final updatedShared =
        List<ManagedPackage>.from(_organization.sharedPackages);
    final existingIndex =
        updatedShared.indexWhere((p) => p.packageId == package.packageId);

    if (existingIndex >= 0) {
      updatedShared[existingIndex] = package;
    } else {
      updatedShared.add(package);
    }

    _organization = EnterpriseOrganization(
      organizationId: _organization.organizationId,
      name: _organization.name,
      domain: _organization.domain,
      defaultPolicy: _organization.defaultPolicy,
      teams: _organization.teams,
      sharedPackages: updatedShared,
      globalAdmins: _organization.globalAdmins,
      createdAt: _organization.createdAt,
      metadata: _organization.metadata,
    );

    _saveOrganizationManifest();
    _logger.info('Registered shared enterprise package: ${package.name}');
  }

  /// Resolves the effective, composed policy for a specific target node in the hierarchy.
  ///
  /// Composition order (deterministic):
  ///   Organization Default Policy
  ///          ↓ (composed with)
  ///   Team Policy Override (if applicable)
  ///          ↓ (composed with)
  ///   Project Policy Override (if applicable)
  ///          ↓ (composed with)
  ///   Package Policy Override (if applicable)
  EnterprisePolicyDocument resolveEffectivePolicy({
    String? teamId,
    String? projectId,
    ManagedProject? project,
    ManagedPackage? package,
  }) {
    // 1. Start with Organization default policy
    var effective = _organization.defaultPolicy;

    // 2. Compose with Team Policy Override
    if (teamId != null) {
      final team = _organization.teams.firstWhere(
        (t) => t.teamId == teamId,
        orElse: () => EnterpriseTeam(
          teamId: 'unknown',
          name: 'Unknown',
          organizationId: _organization.organizationId,
          leadUserId: 'none',
          createdAt: DateTime.now(),
        ),
      );
      if (team.teamPolicyOverride != null) {
        effective = effective.composeWith(team.teamPolicyOverride!);
      }
    }

    // 3. Compose with Project Policy Override
    if (project?.projectPolicyOverride != null) {
      effective = effective.composeWith(project!.projectPolicyOverride!);
    }

    // 4. Compose with Package Policy Override
    if (package?.packagePolicyOverride != null) {
      effective = effective.composeWith(package!.packagePolicyOverride!);
    }

    return effective;
  }

  void _loadOrganizationManifest() {
    final file = _manifestFile;
    if (file.existsSync()) {
      try {
        final content = file.readAsStringSync();
        final jsonMap = jsonDecode(content) as Map<String, dynamic>;
        _organization = EnterpriseOrganization.fromJson(jsonMap);
      } catch (e) {
        _logger.warning('Failed to load organization manifest: $e');
      }
    }
  }

  void _saveOrganizationManifest() {
    try {
      final file = _manifestFile;
      if (!file.parent.existsSync()) {
        file.parent.createSync(recursive: true);
      }
      file.writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert(_organization.toJson()),
      );
    } catch (e) {
      _logger.warning('Failed to save organization manifest: $e');
    }
  }
}
