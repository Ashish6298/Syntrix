import 'package:test/test.dart';
import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';

void main() {
  group('Exceptions Tests', () {
    test('PackageStudioException toString', () {
      final exc1 = ValidationException('Error occurred');
      expect(exc1.toString(), 'Error occurred');

      final exc2 = ConfigurationException('Config failed', 'Invalid key "foo"');
      expect(exc2.toString(), 'Config failed\nDetails: Invalid key "foo"');
    });

    test('All concrete exceptions can be instantiated', () {
      final trace = StackTrace.current;

      final e1 = ConfigurationException('msg', 'details', trace);
      expect(e1.message, 'msg');
      expect(e1.details, 'details');
      expect(e1.stackTrace, trace);

      final e2 = ValidationException('msg', 'details', trace);
      expect(e2.message, 'msg');

      final e3 = CommandException('msg', 'details', trace);
      expect(e3.message, 'msg');

      final e4 = DependencyException('msg', 'details', trace);
      expect(e4.message, 'msg');

      final e5 = StudioFileSystemException('msg', 'details', trace);
      expect(e5.message, 'msg');
    });
  });
}
