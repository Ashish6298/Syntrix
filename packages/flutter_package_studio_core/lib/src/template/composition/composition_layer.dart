import 'package:flutter_package_studio_core/src/template/template_model.dart';

/// Represents the classification/role of a template layer in composition.
enum LayerType {
  base,
  extension,
  dependency,
}

/// Represents a distinct layer in the composition stack.
class CompositionLayer {
  /// 0-indexed position of this layer in composition order.
  final int layerIndex;

  /// The template associated with this layer.
  final Template template;

  /// Layer role (base, extension, dependency).
  final LayerType layerType;

  const CompositionLayer({
    required this.layerIndex,
    required this.template,
    required this.layerType,
  });

  String get templateId => template.id;
  String get version => template.version;

  @override
  String toString() =>
      'CompositionLayer(#$layerIndex, $templateId@$version, type: ${layerType.name})';
}
