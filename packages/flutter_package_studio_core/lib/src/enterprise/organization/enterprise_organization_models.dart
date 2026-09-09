/// Domain models for Phase 9.8: Multi-Project & Organization Management.
library;

import 'package:flutter_package_studio_core/src/enterprise/policy/enterprise_policy_models.dart';
import 'package:flutter_package_studio_core/src/enterprise/identity/enterprise_identity_models.dart';

/// Represents a member within an enterprise team or project.
class OrganizationMember {
  final String userId;
  final String displayName;
  final String email;
  final EnterpriseRole role;
  final DateTime joinedAt;

  const OrganizationMember({
    required this.userId,
    required this.displayName,
    this.email = '',
    this.role = EnterpriseRole.developer,
    required this.joinedAt,
  });

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'display_name': displayName,
        'email': email,
        'role': role.id,
        'joined_at': joinedAt.toIso8601String(),
      };

  factory OrganizationMember.fromJson(Map<String, dynamic> json) {
    return OrganizationMember(
      userId: json['user_id'] as String? ?? 'unknown',
      displayName: json['display_name'] as String? ?? 'Unknown Member',
      email: json['email'] as String? ?? '',
      role: EnterpriseRole.fromString(json['role'] as String?),
      joinedAt: json['joined_at'] is String
          ? DateTime.parse(json['joined_at'] as String)
          : DateTime.now(),
    );
  }
}

/// Represents an individual package metadata record within a project.
class ManagedPackage {
  final String packageId;
  final String name;
  final String relativePath;
  final String currentVersion;
  final String? description;
  final String ownerTeamId;
  final EnterprisePolicyDocument? packagePolicyOverride;

  const ManagedPackage({
    required this.packageId,
    required this.name,
    required this.relativePath,
    this.currentVersion = '1.0.0',
    this.description,
    required this.ownerTeamId,
    this.packagePolicyOverride,
  });

  Map<String, dynamic> toJson() => {
        'package_id': packageId,
        'name': name,
        'relative_path': relativePath,
        'current_version': currentVersion,
        'description': description,
        'owner_team_id': ownerTeamId,
        'package_policy_override': packagePolicyOverride?.toJson(),
      };

  factory ManagedPackage.fromJson(Map<String, dynamic> json) {
    return ManagedPackage(
      packageId: json['package_id'] as String? ?? 'unknown_pkg',
      name: json['name'] as String? ?? 'unnamed_package',
      relativePath: json['relative_path'] as String? ?? '.',
      currentVersion: json['current_version'] as String? ?? '1.0.0',
      description: json['description'] as String?,
      ownerTeamId: json['owner_team_id'] as String? ?? 'shared',
      packagePolicyOverride:
          json['package_policy_override'] is Map<String, dynamic>
              ? EnterprisePolicyDocument.fromJson(
                  json['package_policy_override'] as Map<String, dynamic>)
              : null,
    );
  }
}

/// Represents a Project contained within a Team or Organization.
class ManagedProject {
  final String projectId;
  final String name;
  final String description;
  final String teamId;
  final String organizationId;
  final String projectRootPath;
  final List<ManagedPackage> packages;
  final List<OrganizationMember> members;
  final EnterprisePolicyDocument? projectPolicyOverride;
  final DateTime createdAt;

  const ManagedProject({
    required this.projectId,
    required this.name,
    this.description = '',
    required this.teamId,
    required this.organizationId,
    required this.projectRootPath,
    this.packages = const [],
    this.members = const [],
    this.projectPolicyOverride,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'project_id': projectId,
        'name': name,
        'description': description,
        'team_id': teamId,
        'organization_id': organizationId,
        'project_root_path': projectRootPath,
        'packages': packages.map((p) => p.toJson()).toList(),
        'members': members.map((m) => m.toJson()).toList(),
        'project_policy_override': projectPolicyOverride?.toJson(),
        'created_at': createdAt.toIso8601String(),
      };

  factory ManagedProject.fromJson(Map<String, dynamic> json) {
    return ManagedProject(
      projectId: json['project_id'] as String? ?? 'unknown_prj',
      name: json['name'] as String? ?? 'Unnamed Project',
      description: json['description'] as String? ?? '',
      teamId: json['team_id'] as String? ?? 'default_team',
      organizationId: json['organization_id'] as String? ?? 'default_org',
      projectRootPath: json['project_root_path'] as String? ?? '.',
      packages: (json['packages'] as List<dynamic>?)
              ?.map((p) => ManagedPackage.fromJson(p as Map<String, dynamic>))
              .toList() ??
          const [],
      members: (json['members'] as List<dynamic>?)
              ?.map(
                  (m) => OrganizationMember.fromJson(m as Map<String, dynamic>))
              .toList() ??
          const [],
      projectPolicyOverride:
          json['project_policy_override'] is Map<String, dynamic>
              ? EnterprisePolicyDocument.fromJson(
                  json['project_policy_override'] as Map<String, dynamic>)
              : null,
      createdAt: json['created_at'] is String
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }
}

/// Represents an Enterprise Team owning projects and packages.
class EnterpriseTeam {
  final String teamId;
  final String name;
  final String description;
  final String organizationId;
  final String leadUserId;
  final List<OrganizationMember> members;
  final List<String> projectIds;
  final EnterprisePolicyDocument? teamPolicyOverride;
  final DateTime createdAt;

  const EnterpriseTeam({
    required this.teamId,
    required this.name,
    this.description = '',
    required this.organizationId,
    required this.leadUserId,
    this.members = const [],
    this.projectIds = const [],
    this.teamPolicyOverride,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'team_id': teamId,
        'name': name,
        'description': description,
        'organization_id': organizationId,
        'lead_user_id': leadUserId,
        'members': members.map((m) => m.toJson()).toList(),
        'project_ids': projectIds,
        'team_policy_override': teamPolicyOverride?.toJson(),
        'created_at': createdAt.toIso8601String(),
      };

  factory EnterpriseTeam.fromJson(Map<String, dynamic> json) {
    return EnterpriseTeam(
      teamId: json['team_id'] as String? ?? 'unknown_team',
      name: json['name'] as String? ?? 'Unnamed Team',
      description: json['description'] as String? ?? '',
      organizationId: json['organization_id'] as String? ?? 'default_org',
      leadUserId: json['lead_user_id'] as String? ?? 'admin',
      members: (json['members'] as List<dynamic>?)
              ?.map(
                  (m) => OrganizationMember.fromJson(m as Map<String, dynamic>))
              .toList() ??
          const [],
      projectIds: (json['project_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      teamPolicyOverride: json['team_policy_override'] is Map<String, dynamic>
          ? EnterprisePolicyDocument.fromJson(
              json['team_policy_override'] as Map<String, dynamic>)
          : null,
      createdAt: json['created_at'] is String
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }
}

/// Top-level Enterprise Organization node.
class EnterpriseOrganization {
  final String organizationId;
  final String name;
  final String domain;
  final EnterprisePolicyDocument defaultPolicy;
  final List<EnterpriseTeam> teams;
  final List<ManagedPackage> sharedPackages;
  final List<OrganizationMember> globalAdmins;
  final DateTime createdAt;
  final Map<String, dynamic> metadata;

  const EnterpriseOrganization({
    required this.organizationId,
    required this.name,
    this.domain = 'enterprise.internal',
    this.defaultPolicy = const EnterprisePolicyDocument(),
    this.teams = const [],
    this.sharedPackages = const [],
    this.globalAdmins = const [],
    required this.createdAt,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() => {
        'organization_id': organizationId,
        'name': name,
        'domain': domain,
        'default_policy': defaultPolicy.toJson(),
        'teams': teams.map((t) => t.toJson()).toList(),
        'shared_packages': sharedPackages.map((p) => p.toJson()).toList(),
        'global_admins': globalAdmins.map((a) => a.toJson()).toList(),
        'created_at': createdAt.toIso8601String(),
        'metadata': metadata,
      };

  factory EnterpriseOrganization.fromJson(Map<String, dynamic> json) {
    return EnterpriseOrganization(
      organizationId: json['organization_id'] as String? ?? 'default_org',
      name: json['name'] as String? ?? 'Default Organization',
      domain: json['domain'] as String? ?? 'enterprise.internal',
      defaultPolicy: json['default_policy'] is Map<String, dynamic>
          ? EnterprisePolicyDocument.fromJson(
              json['default_policy'] as Map<String, dynamic>)
          : const EnterprisePolicyDocument(),
      teams: (json['teams'] as List<dynamic>?)
              ?.map((t) => EnterpriseTeam.fromJson(t as Map<String, dynamic>))
              .toList() ??
          const [],
      sharedPackages: (json['shared_packages'] as List<dynamic>?)
              ?.map((p) => ManagedPackage.fromJson(p as Map<String, dynamic>))
              .toList() ??
          const [],
      globalAdmins: (json['global_admins'] as List<dynamic>?)
              ?.map(
                  (a) => OrganizationMember.fromJson(a as Map<String, dynamic>))
              .toList() ??
          const [],
      createdAt: json['created_at'] is String
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      metadata: (json['metadata'] as Map<String, dynamic>?) ?? const {},
    );
  }
}
