// Compatibility facade. New code should import core/config/app_config.dart.
import '../../core/config/app_config.dart';

@Deprecated('Use AppConfig directly')
final SupabaseOptions supabaseOptions = SupabaseOptions(
  url: AppConfig.supabaseUrl,
  anonKey: AppConfig.supabasePublishableKey,
);

@Deprecated('Use AppConfig.hasSupabaseClientConfig')
bool get isSupabaseConfigured => AppConfig.hasSupabaseClientConfig;

@Deprecated('Use AppConfig directly')
final class SupabaseOptions {
  const SupabaseOptions({required this.url, required this.anonKey});

  final String url;
  final String anonKey;
}
