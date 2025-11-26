import 'package:flutter_test/flutter_test.dart';
import 'package:flowfit/secrets.dart';

void main() {
  group('Supabase Configuration', () {
    test('Supabase URL is configured correctly', () {
      expect(SupabaseConfig.url, isNotEmpty);
      expect(SupabaseConfig.url, startsWith('https://'));
      expect(SupabaseConfig.url, contains('supabase.co'));
    });

    test('Supabase anon key is configured correctly', () {
      expect(SupabaseConfig.anonKey, isNotEmpty);
      // JWT tokens start with 'eyJ'
      expect(SupabaseConfig.anonKey, startsWith('eyJ'));
    });

    test('Supabase URL matches expected project', () {
      expect(SupabaseConfig.url, equals('https://dnasghxxqwibwqnljvxr.supabase.co'));
    });
  });
}
