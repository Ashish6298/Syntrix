import 'package:test/test.dart';
import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';

class TestService {
  final String value;
  TestService(this.value);
}

class AnotherService {}

void main() {
  late DependencyContainer container;

  setUp(() {
    container = DependencyContainer();
    container.reset();
  });

  group('DependencyContainer Tests', () {
    test('registerSingleton & resolve', () {
      final service = TestService('singleton');
      container.registerSingleton<TestService>(service);

      expect(container.isRegistered<TestService>(), isTrue);
      final resolved = container.resolve<TestService>();
      expect(resolved, same(service));
      expect(resolved.value, 'singleton');
    });

    test('registerLazySingleton is lazy', () {
      var callCount = 0;
      container.registerLazySingleton<TestService>(() {
        callCount++;
        return TestService('lazy');
      });

      expect(container.isRegistered<TestService>(), isTrue);
      expect(callCount, 0);

      final resolved1 = container.resolve<TestService>();
      expect(callCount, 1);
      expect(resolved1.value, 'lazy');

      final resolved2 = container.resolve<TestService>();
      expect(callCount, 1);
      expect(resolved2, same(resolved1));
    });

    test('registerFactory resolves new instances', () {
      var callCount = 0;
      container.registerFactory<TestService>(() {
        callCount++;
        return TestService('factory_$callCount');
      });

      final resolved1 = container.resolve<TestService>();
      expect(resolved1.value, 'factory_1');

      final resolved2 = container.resolve<TestService>();
      expect(resolved2.value, 'factory_2');
      expect(resolved1, isNot(same(resolved2)));
    });

    test('Throws exception on duplicate registration', () {
      container.registerSingleton<TestService>(TestService('1'));
      expect(
        () => container.registerSingleton<TestService>(TestService('2')),
        throwsA(isA<DependencyException>()),
      );
      expect(
        () => container
            .registerLazySingleton<TestService>(() => TestService('2')),
        throwsA(isA<DependencyException>()),
      );
      expect(
        () => container.registerFactory<TestService>(() => TestService('2')),
        throwsA(isA<DependencyException>()),
      );
    });

    test('Throws exception when resolving unregistered type', () {
      expect(
        () => container.resolve<AnotherService>(),
        throwsA(isA<DependencyException>()),
      );
    });

    test('registerMock overrides existing registration', () {
      container.registerSingleton<TestService>(TestService('original'));
      expect(container.resolve<TestService>().value, 'original');

      final mockService = TestService('mocked');
      container.registerMock<TestService>(mockService);

      expect(container.resolve<TestService>(), same(mockService));
      expect(container.resolve<TestService>().value, 'mocked');
    });

    test('reset clears registry', () {
      container.registerSingleton<TestService>(TestService('1'));
      expect(container.isRegistered<TestService>(), isTrue);

      container.reset();
      expect(container.isRegistered<TestService>(), isFalse);
      expect(() => container.resolve<TestService>(),
          throwsA(isA<DependencyException>()));
    });
  });
}
