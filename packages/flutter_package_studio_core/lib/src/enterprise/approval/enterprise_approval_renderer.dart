/// Pure dual-format (JSON + Markdown) renderer for Phase 9.5 Approval requests.
library;

import 'dart:convert';
import 'package:flutter_package_studio_core/src/enterprise/approval/enterprise_approval_models.dart';

/// Pure Dual-Format Renderer for Approval & Release Governance.
class EnterpriseApprovalRenderer {
  const EnterpriseApprovalRenderer();

  /// Renders formatted JSON string.
  String renderJson(ApprovalRequest request) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(request.toJson());
  }

  /// Renders structured Markdown approval report.
  String renderMarkdown(ApprovalRequest request) {
    final buffer = StringBuffer();

    final statusIcon = request.status == ApprovalStatus.approved
        ? '✅'
        : (request.status == ApprovalStatus.rejected
            ? '❌'
            : (request.status == ApprovalStatus.cancelled ? '🚫' : '⏳'));

    buffer.writeln('# Enterprise Release Approval Report');
    buffer.writeln();
    buffer.writeln('**Request ID**: `${request.requestId}`  ');
    buffer.writeln(
        '**Target Candidate**: `${request.candidateName}@${request.candidateVersion}` (`${request.targetChannel}`)  ');
    buffer.writeln(
        '**Requester**: `${request.requester.displayName}` (`${request.requester.id}`)  ');
    buffer.writeln('**Status**: $statusIcon **${request.status.label}**  ');
    buffer
        .writeln('**Created At**: `${request.createdAt.toIso8601String()}`  ');
    buffer.writeln('**Expires At**: `${request.expiresAt.toIso8601String()}`');
    buffer.writeln();

    buffer.writeln('## Executive Approval Summary');
    buffer.writeln('```text');
    buffer.writeln('Status: ${request.status.label}');
    buffer.writeln(
        'Reviewer Approvals: ${request.reviewerApprovalCount} / ${request.policy.requiredReviewerApprovals}');
    buffer.writeln(
        'Release Manager Approvals: ${request.releaseManagerApprovalCount} / ${request.policy.requiredReleaseManagerApprovals}');
    buffer.writeln(
        'Satisfied Technical Gates: ${request.satisfiedTechnicalGates.join(", ")}');
    buffer.writeln('Has Rejection: ${request.hasRejection ? "YES" : "NO"}');
    buffer.writeln('Is Expired: ${request.isExpired ? "YES" : "NO"}');
    buffer.writeln('```');
    buffer.writeln();

    buffer.writeln('## Governance & Pre-Approval Technical Gates');
    for (final gate in request.policy.requiredPreApprovalGates) {
      final passed = request.satisfiedTechnicalGates.contains(gate);
      final icon = passed ? '✅' : '❌';
      buffer.writeln(
          '- $icon **`$gate`** (${passed ? "Satisfied" : "Pending/Failed"})');
    }
    buffer.writeln();

    buffer.writeln('## Recorded Votes (${request.votes.length})');
    if (request.votes.isEmpty) {
      buffer.writeln('*No votes recorded yet. Awaiting authorized reviews.*');
    } else {
      for (final vote in request.votes) {
        final voteIcon = vote.action == ApprovalVoteAction.approve
            ? '✅'
            : (vote.action == ApprovalVoteAction.reject
                ? '❌'
                : (vote.action == ApprovalVoteAction.override ? '⚡' : '📝'));
        buffer.writeln(
            '### $voteIcon ${vote.action.label} by `${vote.voterDisplayName}` (${vote.voterRole.displayName})');
        buffer
            .writeln('- **Timestamp**: `${vote.timestamp.toIso8601String()}`');
        if (vote.comment != null && vote.comment!.isNotEmpty) {
          buffer.writeln('- **Comment**: "${vote.comment}"');
        }
        buffer.writeln();
      }
    }

    if (request.cancellationReason != null) {
      buffer.writeln('## 🚫 Cancellation Reason');
      buffer.writeln('`${request.cancellationReason}`');
      buffer.writeln();
    }

    if (request.overrideReason != null) {
      buffer.writeln('## ⚡ Administrative Override');
      buffer.writeln('`${request.overrideReason}`');
      buffer.writeln();
    }

    return buffer.toString();
  }
}
