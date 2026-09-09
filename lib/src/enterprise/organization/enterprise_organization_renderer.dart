/// Pure dual-format (JSON + Markdown) renderer for Phase 9.8 Multi-Project & Organization.
library;

import 'dart:convert';
import 'package:syntrix/src/enterprise/organization/enterprise_organization_models.dart';

/// Pure Dual-Format Renderer for Enterprise Organizations.
class EnterpriseOrganizationRenderer {
  const EnterpriseOrganizationRenderer();

  /// Renders formatted JSON string.
  String renderJson(EnterpriseOrganization org) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(org.toJson());
  }

  /// Renders structured Markdown organization hierarchy report.
  String renderMarkdown(EnterpriseOrganization org) {
    final buffer = StringBuffer();

    buffer.writeln('# Enterprise Organization Hierarchy Report');
    buffer.writeln();
    buffer.writeln('**Organization Name**: `${org.name}`  ');
    buffer.writeln('**Organization ID**: `${org.organizationId}`  ');
    buffer.writeln('**Domain**: `${org.domain}`  ');
    buffer.writeln(
        '**Default Policy Profile**: `${org.defaultPolicy.profile.id}`  ');
    buffer.writeln('**Created At**: `${org.createdAt.toIso8601String()}`');
    buffer.writeln();

    buffer.writeln('## Executive Summary');
    buffer.writeln('```text');
    buffer.writeln('Total Teams: ${org.teams.length}');
    buffer.writeln('Total Shared Packages: ${org.sharedPackages.length}');
    buffer.writeln('Global Administrators: ${org.globalAdmins.length}');
    buffer.writeln('```');
    buffer.writeln();

    buffer.writeln('## Teams & Projects');
    if (org.teams.isEmpty) {
      buffer.writeln('*No teams configured in organization.*');
    } else {
      for (final team in org.teams) {
        buffer.writeln('### 👥 Team: `${team.name}` (`${team.teamId}`)');
        buffer.writeln('- **Lead**: `${team.leadUserId}`');
        buffer.writeln('- **Members**: ${team.members.length}');
        buffer.writeln('- **Project Count**: ${team.projectIds.length}');
        if (team.projectIds.isNotEmpty) {
          buffer.writeln('  - *Projects*: ${team.projectIds.join(", ")}');
        }
        if (team.teamPolicyOverride != null) {
          buffer.writeln(
              '- **Policy Override**: `${team.teamPolicyOverride!.profile.id}` (${team.teamPolicyOverride!.enforcementMode.id})');
        }
        buffer.writeln();
      }
    }

    buffer.writeln('## 📦 Shared Packages (${org.sharedPackages.length})');
    if (org.sharedPackages.isEmpty) {
      buffer.writeln('*No shared organization packages registered.*');
    } else {
      for (final pkg in org.sharedPackages) {
        buffer.writeln(
            '- **`${pkg.name}`** (`${pkg.currentVersion}`) — Owner: `${pkg.ownerTeamId}`');
      }
      buffer.writeln();
    }

    return buffer.toString();
  }
}
