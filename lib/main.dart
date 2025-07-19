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
import 'view/media_tool/ffmpeg_manager.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    FilePickerWeb.registerWith(Registrar());
    VideoPlayerPlugin.registerWith(Registrar());
  }

  await Supabase.initialize(
    url: supabaseOptions.url,
    anonKey: supabaseOptions.anonKey,
  );
  FfmpegManager.instance.loadFFmpeg(() {
    print('[main.dart] FFmpeg loaded successfully');
    // setState(() {
    //   isLoaded = FfmpegManager.instance.isLoaded;
    //   conversionStatus =
    //   FfmpegManager.instance.isLoaded ? 'Ready' : 'Loading FFmpeg...';
    // });
  }, onFailed: (e) {
    print('[main.dart] FFmpeg load failed: $e');
    // setState(() {
    //   isLoaded = FfmpegManager.instance.isLoaded;
    //   conversionStatus = 'FFmpeg load failed - $e';
    // });
  });
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
