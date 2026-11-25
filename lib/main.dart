import 'dart:async';
import 'package:flutter/material.dart';

import 'package:file_picker/_internal/file_picker_web.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_portfolio/core/config/app_config.dart';
import 'package:flutter_portfolio/app/app.dart';
import 'package:flutter_portfolio/core/logging/app_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player_web/video_player_web.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    FilePickerWeb.registerWith(Registrar());
    VideoPlayerPlugin.registerWith(Registrar());
  }

  runApp(const PortfolioApp());
  unawaited(_initializeSupabase());
}

Future<void> _initializeSupabase() async {
  if (AppConfig.hasSupabaseClientConfig) {
    try {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        anonKey: AppConfig.supabasePublishableKey,
      );
    } catch (_) {
      AppLogger.configurationFailure('Supabase');
    }
  } else {
    AppLogger.warning('Supabase public client configuration is not set.');
  }
}
