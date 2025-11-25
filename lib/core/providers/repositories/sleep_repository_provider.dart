import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data_sources/supabase_data_source_provider.dart';

/// Provider for sleep repository
/// 
/// Placeholder for sleep data operations.
final sleepRepositoryProvider = Provider((ref) {
  final supabase = ref.watch(supabaseDataSourceProvider);
  // TODO: Implement SleepRepository when needed
  return supabase;
});
