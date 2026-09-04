/// Central Approval & Release Governance Engine for Phase 9.5.
library;

import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:flutter_package_studio_core/src/logging/logger.dart';
import 'package:flutter_package_studio_core/src/enterprise/identity/enterprise_identity_models.dart';
import 'package:flutter_package_studio_core/src/enterprise/approval/enterprise_approval_models.dart';

/// Central Approval & Release Governance Engine.
///
/// Features:
/// 1. Lifecycle management of release approval requests (Create, Vote, Reject, Cancel, Override, Expire).
/// 2. Clear boundary separating Technical Verification from Organizational Human Approval.
/// 3. Persistent approval history storage in `.fps/approval/approval_history.jsonl`.
/// 4. Release gate evaluation checking if an approval request is ready for publishing.
class EnterpriseApprovalEngine {
  final Logger _logger = Logger('EnterpriseApprovalEngine');
  final String _projectRoot;
  final Map<String, ApprovalRequest> _requests = {};

  String get projectRoot => _projectRoot;
  List<ApprovalRequest> get allRequests => _requests.values.toList();

  EnterpriseApprovalEngine({
    required String projectRoot,
  }) : _projectRoot = p.normalize(projectRoot) {
    _loadHistory();
  }

  File get _historyFile => File(p.join(_projectRoot, '.fps', 'approval', 'approval_history.jsonl'));

  /// Creates a new formal release approval request.
  Future<ApprovalRequest> createApprovalRequest({
    required String candidateName,
    required String candidateVersion,
    String targetChannel = 'stable',
    required EnterpriseIdentity requester,
    ApprovalPolicy policy = const ApprovalPolicy(),
    List<String> satisfiedTechnicalGates = const [],
    Map<String, dynamic> metadata = const {},
  }) async {
    final now = DateTime.now();
    final requestId = 'appr_${now.millisecondsSinceEpoch}_${candidateName}_$candidateVersion';

    // Verify pre-approval technical gates
    final missingGates = policy.requiredPreApprovalGates.where(
      (gate) => !satisfiedTechnicalGates.contains(gate),
    ).toList();

    if (missingGates.isNotEmpty) {
      _logger.warning('Creating approval request with missing technical gates: $missingGates');
    }

    final request = ApprovalRequest(
      requestId: requestId,
      candidateName: candidateName,
      candidateVersion: candidateVersion,
      targetChannel: targetChannel,
      requester: requester,
      policy: policy,
      status: ApprovalStatus.pending,
      votes: const [],
      satisfiedTechnicalGates: satisfiedTechnicalGates,
      createdAt: now,
      expiresAt: now.add(policy.validityDuration),
      metadata: metadata,
    );

    _requests[requestId] = request;
    _persistRequest(request);
    _logger.info('Created release approval request: $requestId for $candidateName@$candidateVersion');

    return request;
  }

  /// Submits an approval or rejection vote by an authorized identity.
  Future<ApprovalRequest> submitVote({
    required String requestId,
    required EnterpriseIdentity voter,
    required ApprovalVoteAction action,
    String? comment,
  }) async {
    final req = _requests[requestId];
    if (req == null) {
      throw StateError('Approval request "$requestId" not found.');
    }

    if (req.status != ApprovalStatus.pending) {
      throw StateError('Cannot vote on request in terminal status "${req.status.name}".');
    }

    if (req.isExpired) {
      final expired = req.copyWith(status: ApprovalStatus.expired);
      _requests[requestId] = expired;
      _persistRequest(expired);
      return expired;
    }

    final voterRole = voter.roles.isNotEmpty ? voter.roles.first : EnterpriseRole.readOnly;
    final vote = ApprovalVote(
      voterId: voter.id,
      voterDisplayName: voter.displayName,
      voterRole: voterRole,
      action: action,
      comment: comment,
      timestamp: DateTime.now(),
    );

    final updatedVotes = [...req.votes, vote];

    // Evaluate new status
    ApprovalStatus newStatus = ApprovalStatus.pending;

    if (action == ApprovalVoteAction.reject) {
      newStatus = ApprovalStatus.rejected;
    } else if (action == ApprovalVoteAction.override &&
        (voter.hasRole(EnterpriseRole.administrator) && req.policy.allowAdminOverride)) {
      newStatus = ApprovalStatus.approved;
    } else {
      // Check approval counts
      final revCount = updatedVotes
          .where((v) =>
              (v.voterRole == EnterpriseRole.reviewer || v.voterRole == EnterpriseRole.developer) &&
              v.action == ApprovalVoteAction.approve)
          .length;
      final relCount = updatedVotes
          .where((v) =>
              (v.voterRole == EnterpriseRole.releaseManager || v.voterRole == EnterpriseRole.administrator) &&
              v.action == ApprovalVoteAction.approve)
          .length;

      if (revCount >= req.policy.requiredReviewerApprovals &&
          relCount >= req.policy.requiredReleaseManagerApprovals) {
        newStatus = ApprovalStatus.approved;
      }
    }

    final updated = req.copyWith(
      status: newStatus,
      votes: updatedVotes,
    );

    _requests[requestId] = updated;
    _persistRequest(updated);
    _logger.info('Submitted vote on $requestId by ${voter.displayName} -> ${action.label}. Status: ${newStatus.label}');

    return updated;
  }

  /// Cancels an active approval request.
  Future<ApprovalRequest> cancelRequest({
    required String requestId,
    required EnterpriseIdentity actor,
    required String reason,
  }) async {
    final req = _requests[requestId];
    if (req == null) throw StateError('Approval request "$requestId" not found.');

    final cancelled = req.copyWith(
      status: ApprovalStatus.cancelled,
      cancellationReason: reason,
    );

    _requests[requestId] = cancelled;
    _persistRequest(cancelled);
    _logger.info('Cancelled approval request $requestId: $reason');
    return cancelled;
  }

  /// Overrides an approval request with Administrator authority.
  Future<ApprovalRequest> adminOverride({
    required String requestId,
    required EnterpriseIdentity adminActor,
    required String reason,
  }) async {
    if (!adminActor.hasRole(EnterpriseRole.administrator)) {
      throw StateError('Only Administrators can perform approval overrides.');
    }

    final req = _requests[requestId];
    if (req == null) throw StateError('Approval request "$requestId" not found.');

    final vote = ApprovalVote(
      voterId: adminActor.id,
      voterDisplayName: adminActor.displayName,
      voterRole: EnterpriseRole.administrator,
      action: ApprovalVoteAction.override,
      comment: reason,
      timestamp: DateTime.now(),
    );

    final overridden = req.copyWith(
      status: ApprovalStatus.approved,
      votes: [...req.votes, vote],
      overrideReason: reason,
    );

    _requests[requestId] = overridden;
    _persistRequest(overridden);
    _logger.info('Admin override executed on $requestId by ${adminActor.displayName}: $reason');
    return overridden;
  }

  /// Verifies whether release publishing is authorized by both Technical Verification AND Human Approval.
  bool isReleaseAuthorized({required String requestId}) {
    final req = _requests[requestId];
    if (req == null) return false;
    if (req.status != ApprovalStatus.approved) return false;

    // Verify all mandatory technical pre-gates are met
    final missingTechnicalGates = req.policy.requiredPreApprovalGates.where(
      (gate) => !req.satisfiedTechnicalGates.contains(gate),
    );

    return missingTechnicalGates.isEmpty;
  }

  void _loadHistory() {
    final file = _historyFile;
    if (file.existsSync()) {
      try {
        final lines = file.readAsLinesSync();
        for (final line in lines) {
          if (line.trim().isEmpty) continue;
          final jsonMap = jsonDecode(line) as Map<String, dynamic>;
          final req = ApprovalRequest.fromJson(jsonMap);
          _requests[req.requestId] = req;
        }
      } catch (_) {}
    }
  }

  void _persistRequest(ApprovalRequest request) {
    try {
      final file = _historyFile;
      if (!file.parent.existsSync()) {
        file.parent.createSync(recursive: true);
      }
      file.writeAsStringSync('${jsonEncode(request.toJson())}\n', mode: FileMode.append, flush: true);
    } catch (e) {
      _logger.warning('Failed to persist approval record: $e');
    }
  }
}
