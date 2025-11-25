// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'example_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$exampleMessageHash() => r'1ba91d33047d1dfda169f1cd7dae8433a79110a5';

/// Example provider demonstrating Riverpod code generation
/// This will be replaced with actual providers in later tasks
///
/// Copied from [exampleMessage].
@ProviderFor(exampleMessage)
final exampleMessageProvider = AutoDisposeProvider<String>.internal(
  exampleMessage,
  name: r'exampleMessageProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$exampleMessageHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ExampleMessageRef = AutoDisposeProviderRef<String>;
String _$exampleAsyncMessageHash() =>
    r'926cf12ea36b20548520637779d168a12b66be4c';

/// Example async provider
///
/// Copied from [exampleAsyncMessage].
@ProviderFor(exampleAsyncMessage)
final exampleAsyncMessageProvider = AutoDisposeFutureProvider<String>.internal(
  exampleAsyncMessage,
  name: r'exampleAsyncMessageProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$exampleAsyncMessageHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ExampleAsyncMessageRef = AutoDisposeFutureProviderRef<String>;
String _$exampleCounterHash() => r'1aa9b028a513a6e7b3b7bf308b50b143d90c8d6c';

/// Example stream provider
///
/// Copied from [exampleCounter].
@ProviderFor(exampleCounter)
final exampleCounterProvider = AutoDisposeStreamProvider<int>.internal(
  exampleCounter,
  name: r'exampleCounterProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$exampleCounterHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ExampleCounterRef = AutoDisposeStreamProviderRef<int>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
