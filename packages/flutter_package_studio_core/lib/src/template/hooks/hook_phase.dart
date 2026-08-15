/// Lifecycle phases supported by the Template Hook System.
library;

/// Represents distinct stages in the template generation pipeline where hooks can execute.
enum TemplateHookPhase {
  /// Executed prior to template resolution.
  preResolution,

  /// Executed after base and extension templates are resolved.
  postResolution,

  /// Executed before template composition layers are merged.
  preComposition,

  /// Executed after composition plan and file provenances are finalized.
  postComposition,

  /// Executed before user customization values and presets are evaluated.
  preCustomization,

  /// Executed after customization variables and path overrides are computed.
  postCustomization,

  /// Executed immediately before generation plan execution.
  preGeneration,

  /// Executed after file generation operations complete.
  postGeneration,

  /// Executed during quality assurance and validation phases.
  validation,

  /// Executed upon successful pipeline completion.
  completion,

  /// Executed when pipeline generation or validation fails.
  failure;

  /// Returns human-readable display name for this phase.
  String get displayName {
    switch (this) {
      case TemplateHookPhase.preResolution:
        return 'Pre-Resolution';
      case TemplateHookPhase.postResolution:
        return 'Post-Resolution';
      case TemplateHookPhase.preComposition:
        return 'Pre-Composition';
      case TemplateHookPhase.postComposition:
        return 'Post-Composition';
      case TemplateHookPhase.preCustomization:
        return 'Pre-Customization';
      case TemplateHookPhase.postCustomization:
        return 'Post-Customization';
      case TemplateHookPhase.preGeneration:
        return 'Pre-Generation';
      case TemplateHookPhase.postGeneration:
        return 'Post-Generation';
      case TemplateHookPhase.validation:
        return 'Validation';
      case TemplateHookPhase.completion:
        return 'Completion';
      case TemplateHookPhase.failure:
        return 'Failure';
    }
  }
}
