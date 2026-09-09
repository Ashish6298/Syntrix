/// Defines metadata-driven capability tags for template archetypes.
class TemplateCapabilities {
  static const String package = 'package';
  static const String application = 'application';
  static const String plugin = 'plugin';
  static const String federatedPlugin = 'federated_plugin';
  static const String cli = 'cli';
  static const String library = 'library';

  /// Default standard capabilities.
  static const List<String> defaultCapabilities = [package, library];
}
