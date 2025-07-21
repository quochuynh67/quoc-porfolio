class SupabaseOptions {
  final String url;
  final String anonKey;

  SupabaseOptions({
    required this.url,
    required this.anonKey,
  });
}

final SupabaseOptions supabaseOptions = SupabaseOptions(
  url: 'https://meddohfaywowscwmefxn.supabase.co',
  anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1lZGRvaGZheXdvd3Njd21lZnhuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTI4NTg4NzQsImV4cCI6MjA2ODQzNDg3NH0.L22xnyWYSMbKAlopS1v_AitNhPLcDujNLPeS54Us-hY',
);
