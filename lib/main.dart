import 'dart:async';
import 'package:flutter/material.dart';

import 'package:file_picker/_internal/file_picker_web.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_portfolio/res/constants.dart';
import 'package:flutter_portfolio/view/customer_service/supabase_options.dart';
import 'package:flutter_portfolio/view/splash/splash_view.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player_web/video_player_web.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    FilePickerWeb.registerWith(Registrar());
    VideoPlayerPlugin.registerWith(Registrar());
  }

  if (isSupabaseConfigured) {
    try {
      await Supabase.initialize(
        url: supabaseOptions.url,
        anonKey: supabaseOptions.anonKey,
      );
    } catch (e) {
      debugPrint('[WARN] Supabase init failed: $e');
    }
  } else {
    debugPrint(
      '[WARN] Supabase keys are not configured. '
      'Run/build with --dart-define-from-file=supabase_keys.json to enable Supabase features.',
    );
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          scaffoldBackgroundColor: bgColor,
          useMaterial3: true,
          textTheme: GoogleFonts.openSansTextTheme(Theme.of(context).textTheme)
              .apply(
                bodyColor: Colors.white,
              )
              .copyWith(
                bodyLarge: const TextStyle(color: bodyTextColor),
                bodyMedium: const TextStyle(color: bodyTextColor),
                bodySmall: const TextStyle(color: bodyTextColor),
              ),
        ),
        home: const SplashView());
  }
}