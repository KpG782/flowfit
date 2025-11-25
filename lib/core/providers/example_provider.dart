import 'package:riverpod_annotation/riverpod_annotation.dart';

// This file demonstrates the Riverpod code generation setup
// Run: flutter pub run build_runner build --delete-conflicting-outputs
// to generate the .g.dart file

part 'example_provider.g.dart';

/// Example provider demonstrating Riverpod code generation
/// This will be replaced with actual providers in later tasks
@riverpod
String exampleMessage(ExampleMessageRef ref) {
  return 'FlowFit Clean Architecture Setup Complete';
}

/// Example async provider
@riverpod
Future<String> exampleAsyncMessage(ExampleAsyncMessageRef ref) async {
  await Future.delayed(const Duration(milliseconds: 100));
  return 'Async provider working correctly';
}

/// Example stream provider
@riverpod
Stream<int> exampleCounter(ExampleCounterRef ref) async* {
  for (int i = 0; i < 5; i++) {
    await Future.delayed(const Duration(seconds: 1));
    yield i;
  }
}
