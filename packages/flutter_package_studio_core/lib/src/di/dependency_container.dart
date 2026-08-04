import 'package:flutter_package_studio_core/src/error/exceptions.dart';

/// Centralized dependency injection container for registering and resolving services.
class DependencyContainer {
  static final DependencyContainer _instance = DependencyContainer._internal();

  /// Returns the singleton instance of [DependencyContainer].
  factory DependencyContainer() => _instance;

  DependencyContainer._internal();

  final Map<Type, Object Function()> _factories = {};
  final Map<Type, Object> _singletons = {};

  /// Registers a pre-instantiated singleton [instance] for type [T].
  ///
  /// Throws a [DependencyException] if type [T] is already registered.
  void registerSingleton<T extends Object>(T instance) {
    if (isRegistered<T>()) {
      throw DependencyException('Type $T is already registered.');
    }
    _singletons[T] = instance;
  }

  /// Registers a lazy singleton [factory] for type [T].
  /// The factory will be invoked only when [resolve] is called for the first time.
  ///
  /// Throws a [DependencyException] if type [T] is already registered.
  void registerLazySingleton<T extends Object>(T Function() factory) {
    if (isRegistered<T>()) {
      throw DependencyException('Type $T is already registered.');
    }
    _factories[T] = () {
      final instance = factory();
      _singletons[T] = instance;
      return instance;
    };
  }

  /// Registers a factory function [factory] for type [T] which is executed on every [resolve] call.
  ///
  /// Throws a [DependencyException] if type [T] is already registered.
  void registerFactory<T extends Object>(T Function() factory) {
    if (isRegistered<T>()) {
      throw DependencyException('Type $T is already registered.');
    }
    _factories[T] = factory;
  }

  /// Resolves the registered instance or factory for type [T].
  ///
  /// Throws a [DependencyException] if type [T] is not registered.
  T resolve<T extends Object>() {
    if (_singletons.containsKey(T)) {
      return _singletons[T] as T;
    }
    if (_factories.containsKey(T)) {
      final factory = _factories[T]!;
      return factory() as T;
    }
    throw DependencyException('Type $T is not registered in the container.');
  }

  /// Registers a mock or override [instance] for type [T], bypassing normal duplicate check.
  /// This is intended for unit testing or dynamic service swapping.
  void registerMock<T extends Object>(T instance) {
    _factories.remove(T);
    _singletons[T] = instance;
  }

  /// Checks whether type [T] is registered in the container.
  bool isRegistered<T extends Object>() {
    return _singletons.containsKey(T) || _factories.containsKey(T);
  }

  /// Resets all registered factories and singletons in the container.
  void reset() {
    _factories.clear();
    _singletons.clear();
  }
}
