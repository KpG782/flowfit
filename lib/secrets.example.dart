// secrets.example.dart — SAFE TO COMMIT (no real keys here)
//
// Setup:
//   1. Copy this file:   cp lib/secrets.example.dart lib/secrets.dart
//   2. Fill in your real values in secrets.dart
//   3. Never commit secrets.dart  (already in .gitignore)
//
// Supabase → https://supabase.com/dashboard → Settings → API
// OpenRouteService → https://openrouteservice.org/dev/#/home → API Keys

class SupabaseConfig {
  static const String url = 'https://YOUR_PROJECT_ID.supabase.co';
  static const String anonKey = 'YOUR_SUPABASE_ANON_KEY';
}

class OpenRouteConfig {
  static const String apiKey = 'YOUR_OPENROUTESERVICE_API_KEY';
}
