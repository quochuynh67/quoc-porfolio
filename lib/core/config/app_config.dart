/// Build-time application configuration.
///
/// Flutter Web bundles every `dart-define` value into client JavaScript. Only
/// public client values belong here. Service-role keys, admin passwords and
/// provider secrets must remain on a trusted backend.
final class AppConfig {
  const AppConfig._();

  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );

  static bool get hasSupabaseClientConfig =>
      _isHttpsUrl(supabaseUrl) && supabasePublishableKey.trim().isNotEmpty;

  static bool _isHttpsUrl(String value) {
    final uri = Uri.tryParse(value);
    return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty;
  }
}
