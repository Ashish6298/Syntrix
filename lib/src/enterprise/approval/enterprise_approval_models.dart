/// Domain models for Phase 9.5: Approval & Release Governance.
library;

import 'package:syntrix/src/enterprise/identity/enterprise_identity_models.dart';

/// Status of an approval request.
enum ApprovalStatus {
  pending,
  approved,
  rejected,
  cancelled,
  expired;

  String get label => name.toUpperCase();

  bool get isApproved => this == ApprovalStatus.approved;
  bool get isTerminal =>
      this == ApprovalStatus.approved ||
      this == ApprovalStatus.rejected ||
      this == ApprovalStatus.cancelled ||
      this == ApprovalStatus.expired;
}

/// Action taken during an approval vote/review.
enum ApprovalVoteAction {
  approve,
  reject,
  requestChanges,
  override;

  String get label => name.toUpperCase();
}

/// Single vote or decision in an approval record.
class ApprovalVote {
  final String voterId;
  final String voterDisplayName;
  final EnterpriseRole voterRole;
  final ApprovalVoteAction action;
  final String? comment;
  final DateTime timestamp;

  const ApprovalVote({
    required this.voterId,
    required this.voterDisplayName,
    required this.voterRole,
    required this.action,
    this.comment,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'voter_id': voterId,
        'voter_display_name': voterDisplayName,
        'voter_role': voterRole.id,
        'action': action.name,
        'comment': comment,
        'timestamp': timestamp.toIso8601String(),
      };

  factory ApprovalVote.fromJson(Map<String, dynamic> json) {
    return ApprovalVote(
      voterId: json['voter_id'] as String? ?? 'unknown',
      voterDisplayName:
          json['voter_display_name'] as String? ?? 'Unknown Voter',
      voterRole: EnterpriseRole.fromString(json['voter_role'] as String?),
      action: ApprovalVoteAction.values.firstWhere(
        (a) => a.name == json['action'],
        orElse: () => ApprovalVoteAction.approve,
      ),
      comment: json['comment'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

/// Policy governing requirements for granting an approval.
class ApprovalPolicy {
  final int requiredReviewerApprovals;
  final int requiredReleaseManagerApprovals;
  final bool allowAdminOverride;
  final Duration validityDuration;
  final List<String> requiredPreApprovalGates;

  const ApprovalPolicy({
    this.requiredReviewerApprovals = 1,
    this.requiredReleaseManagerApprovals = 1,
    this.allowAdminOverride = true,
    this.validityDuration = const Duration(days: 3),
    this.requiredPreApprovalGates = const [
      'security_audit',
      'release_verification',
      'pub_dev_validation',
    ],
  });

  Map<String, dynamic> toJson() => {
        'required_reviewer_approvals': requiredReviewerApprovals,
        'required_release_manager_approvals': requiredReleaseManagerApprovals,
        'allow_admin_override': allowAdminOverride,
        'validity_duration_seconds': validityDuration.inSeconds,
        'required_pre_approval_gates': requiredPreApprovalGates,
      };

  factory ApprovalPolicy.fromJson(Map<String, dynamic> json) {
    return ApprovalPolicy(
      requiredReviewerApprovals:
          json['required_reviewer_approvals'] as int? ?? 1,
      requiredReleaseManagerApprovals:
          json['required_release_manager_approvals'] as int? ?? 1,
      allowAdminOverride: json['allow_admin_override'] as bool? ?? true,
      validityDuration: Duration(
          seconds: json['validity_duration_seconds'] as int? ?? (3 * 86400)),
      requiredPreApprovalGates:
          (json['required_pre_approval_gates'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              const [
                'security_audit',
                'release_verification',
                'pub_dev_validation'
              ],
    );
  }
}

/// Request for controlled human authorization / release approval.
class ApprovalRequest {
  final String requestId;
  final String candidateName;
  final String candidateVersion;
  final String targetChannel;
  final EnterpriseIdentity requester;
  final ApprovalPolicy policy;
  final ApprovalStatus status;
  final List<ApprovalVote> votes;
  final List<String> satisfiedTechnicalGates;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String? cancellationReason;
  final String? overrideReason;
  final Map<String, dynamic> metadata;

  const ApprovalRequest({
    required this.requestId,
    required this.candidateName,
    required this.candidateVersion,
    this.targetChannel = 'stable',
    required this.requester,
    this.policy = const ApprovalPolicy(),
    this.status = ApprovalStatus.pending,
    this.votes = const [],
    this.satisfiedTechnicalGates = const [],
    required this.createdAt,
    required this.expiresAt,
    this.cancellationReason,
    this.overrideReason,
    this.metadata = const {},
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  int get reviewerApprovalCount => votes
      .where((v) =>
          (v.voterRole == EnterpriseRole.reviewer ||
              v.voterRole == EnterpriseRole.developer) &&
          v.action == ApprovalVoteAction.approve)
      .length;

  int get releaseManagerApprovalCount => votes
      .where((v) =>
          (v.voterRole == EnterpriseRole.releaseManager ||
              v.voterRole == EnterpriseRole.administrator) &&
          v.action == ApprovalVoteAction.approve)
      .length;

  bool get hasRejection =>
      votes.any((v) => v.action == ApprovalVoteAction.reject);

  ApprovalRequest copyWith({
    ApprovalStatus? status,
    List<ApprovalVote>? votes,
    List<String>? satisfiedTechnicalGates,
    String? cancellationReason,
    String? overrideReason,
  }) {
    return ApprovalRequest(
      requestId: requestId,
      candidateName: candidateName,
      candidateVersion: candidateVersion,
      targetChannel: targetChannel,
      requester: requester,
      policy: policy,
      status: status ?? this.status,
      votes: votes ?? this.votes,
      satisfiedTechnicalGates:
          satisfiedTechnicalGates ?? this.satisfiedTechnicalGates,
      createdAt: createdAt,
      expiresAt: expiresAt,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      overrideReason: overrideReason ?? this.overrideReason,
      metadata: metadata,
    );
  }

  Map<String, dynamic> toJson() => {
        'request_id': requestId,
        'candidate_name': candidateName,
        'candidate_version': candidateVersion,
        'target_channel': targetChannel,
        'requester': requester.toJson(),
        'policy': policy.toJson(),
        'status': status.name,
        'votes': votes.map((v) => v.toJson()).toList(),
        'satisfied_technical_gates': satisfiedTechnicalGates,
        'created_at': createdAt.toIso8601String(),
        'expires_at': expiresAt.toIso8601String(),
        'cancellation_reason': cancellationReason,
        'override_reason': overrideReason,
        'metadata': metadata,
      };

  factory ApprovalRequest.fromJson(Map<String, dynamic> json) {
    return ApprovalRequest(
      requestId: json['request_id'] as String? ?? '',
      candidateName: json['candidate_name'] as String? ?? 'unknown',
      candidateVersion: json['candidate_version'] as String? ?? '0.0.0',
      targetChannel: json['target_channel'] as String? ?? 'stable',
      requester: EnterpriseIdentity.fromJson(
          json['requester'] as Map<String, dynamic>),
      policy: json['policy'] is Map<String, dynamic>
          ? ApprovalPolicy.fromJson(json['policy'] as Map<String, dynamic>)
          : const ApprovalPolicy(),
      status: ApprovalStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => ApprovalStatus.pending,
      ),
      votes: (json['votes'] as List<dynamic>?)
              ?.map((v) => ApprovalVote.fromJson(v as Map<String, dynamic>))
              .toList() ??
          const [],
      satisfiedTechnicalGates:
          (json['satisfied_technical_gates'] as List<dynamic>?)
                  ?.map((g) => g.toString())
                  .toList() ??
              const [],
      createdAt: DateTime.parse(json['created_at'] as String),
      expiresAt: DateTime.parse(json['expires_at'] as String),
      cancellationReason: json['cancellation_reason'] as String?,
      overrideReason: json['override_reason'] as String?,
      metadata: (json['metadata'] as Map<String, dynamic>?) ?? const {},
    );
  }
}
