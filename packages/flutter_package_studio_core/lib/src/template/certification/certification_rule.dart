/// Extensible certification rule contract.
library;

import 'package:flutter_package_studio_core/src/template/certification/certification_finding.dart';
import 'package:flutter_package_studio_core/src/template/certification/certification_request.dart';

/// Abstract contract for individual template certification checks.
abstract class TemplateCertificationRule {
  /// Unique rule identifier.
  String get id;

  /// Category of certification check.
  TemplateCertificationCategory get category;

  /// Description of the check performed by this rule.
  String get description;

  /// Evaluates [request] and returns findings.
  List<TemplateCertificationFinding> evaluate(
      TemplateCertificationRequest request);
}
