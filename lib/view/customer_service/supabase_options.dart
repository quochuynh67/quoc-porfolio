class SupabaseOptions {
  final String url;
  final String anonKey;

  SupabaseOptions({
    required this.url,
    required this.anonKey,
  });
}

final SupabaseOptions supabaseOptions = SupabaseOptions(
  url: const String.fromEnvironment('SUPABASE_URL', defaultValue: ''),
  anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: ''),
);

bool get isSupabaseConfigured =>
    supabaseOptions.url.isNotEmpty && supabaseOptions.anonKey.isNotEmpty;

