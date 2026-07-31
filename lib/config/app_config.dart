/// Central place for app-wide configuration values.
class AppConfig {
  /// Base URL for the backend REST API (Supabase Edge Functions).
  /// Override at build time via --dart-define or by editing this value.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue:
        'https://wticulinwirzzppxzapx.supabase.co/functions/v1',
  );

  /// Supabase anon public key. Required as the `apikey` header on every
  /// Edge Function request so the Supabase gateway accepts the call.
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind0aWN1bGlud2lyenpwcHh6YXB4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODUwNzYyNTEsImV4cCI6MjEwMDY1MjI1MX0.d1H5UuL7PAQ8QXZmOymEe7cEGuMtkqAlR82njR28HOE',
  );

  static const String tokenStorageKey = 'jwt_access_token';
  static const String refreshTokenStorageKey = 'jwt_refresh_token';

  /// How often (ms) the video status is polled while a job is processing.
  static const int statusPollIntervalMs = 2500;
}
