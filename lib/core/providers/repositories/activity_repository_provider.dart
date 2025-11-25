import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data_sources/supabase_data_source_provider.dart';

/// Provider for activity repository
/// 
/// Placeholder for activity data operations.
final activityRepositoryProvider = Provider((ref) {
  final supabase = ref.watch(supabaseDataSourceProvider);
  // TODO: Implement ActivityRepository when needed
  return supabase;
});
