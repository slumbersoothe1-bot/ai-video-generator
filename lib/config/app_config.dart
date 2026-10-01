/// Central place for app-wide configuration values.
class AppConfig {
  /// Base URL for the backend REST API (Supabase Edge Functions).
  /// Override at build time via --dart-define or by editing this value.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://ycfkgmdwknolxiugflqr.supabase.co/functions/v1',
  );

  /// Supabase anon public key. Required as the `apikey` header on every
  /// Edge Function request so the Supabase gateway accepts the call.
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_mgO6CO3rdcSLkxcMdbVHOQ_Tk5yr6t9',
  );

  static const String tokenStorageKey = 'jwt_access_token';
  static const String refreshTokenStorageKey = 'jwt_refresh_token';

  /// How often (ms) the video status is polled while a job is processing.
  static const int statusPollIntervalMs = 2500;
}
