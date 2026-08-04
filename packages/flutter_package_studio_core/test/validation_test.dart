import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';

class MockFileUtils extends Mock implements FileUtils {}

void main() {
  group('PackageNameValidator Tests', () {
    const validator = PackageNameValidator();

    test('Valid package names', () {
      expect(validator.validate('my_package').isValid, isTrue);
      expect(validator.validate('package123').isValid, isTrue);
      expect(validator.validate('a_long_snake_case_name').isValid, isTrue);
    });

    test('Invalid package names', () {
      expect(validator.validate('').isValid, isFalse);
      expect(validator.validate('   ').isValid, isFalse);
      // Capital letters
      expect(validator.validate('MyPackage').isValid, isFalse);
      // Starts with number
      expect(validator.validate('1package').isValid, isFalse);
      // Starts with underscore (usually rejected or discouraged)
      expect(validator.validate('_package').isValid, isFalse);
      // Contains dash
      expect(validator.validate('my-package').isValid, isFalse);
    });

    test('Reserved keywords are rejected', () {
      expect(validator.validate('class').isValid, isFalse);
      expect(validator.validate('import').isValid, isFalse);
      expect(validator.validate('void').isValid, isFalse);
      expect(validator.validate('var').isValid, isFalse);
    });
  });

  group('SemVerValidator Tests', () {
    const validator = SemVerValidator();

    test('Valid versions', () {
      expect(validator.validate('1.0.0').isValid, isTrue);
      expect(validator.validate('v1.2.3-beta.1').isValid, isTrue);
    });

    test('Invalid versions', () {
      expect(validator.validate('1.0').isValid, isFalse);
      expect(validator.validate('invalid').isValid, isFalse);
    });
  });

  group('DirectoryExistsValidator Tests', () {
    late MockFileUtils mockFileUtils;
    late DirectoryExistsValidator validator;

    setUp(() {
      mockFileUtils = MockFileUtils();
      validator = DirectoryExistsValidator(mockFileUtils);
    });

    test('Succeeds if directory exists', () {
      when(() => mockFileUtils.exists('/path/to/dir')).thenReturn(true);
      when(() => mockFileUtils.isDirectory('/path/to/dir')).thenReturn(true);

      final result = validator.validate('/path/to/dir');
      expect(result.isValid, isTrue);
    });

    test('Fails if directory does not exist', () {
      when(() => mockFileUtils.exists('/path/to/dir')).thenReturn(false);

      final result = validator.validate('/path/to/dir');
      expect(result.isValid, isFalse);
      expect(result.errors.first, contains('does not exist'));
    });

    test('Fails if path is a file, not a directory', () {
      when(() => mockFileUtils.exists('/path/to/file')).thenReturn(true);
      when(() => mockFileUtils.isDirectory('/path/to/file')).thenReturn(false);

      final result = validator.validate('/path/to/file');
      expect(result.isValid, isFalse);
      expect(result.errors.first, contains('not a directory'));
    });
  });

  group('CompositeValidator Tests', () {
    test('Merges multiple validation errors', () {
      final nameVal = PackageNameValidator();
      final semVal = SemVerValidator();

      final composite = CompositeValidator<String>([nameVal, semVal]);

      // 'class' is invalid package name, but 'class' is also invalid semver.
      final result = composite.validate('class');
      expect(result.isValid, isFalse);
      expect(result.errors.length, 2);
    });
  });
}
