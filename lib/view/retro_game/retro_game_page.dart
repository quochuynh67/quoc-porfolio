import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui' as ui;

class RetroGamePage extends StatefulWidget {
  const RetroGamePage({super.key});

  @override
  State<RetroGamePage> createState() => _RetroGamePageState();
}

class _RetroGamePageState extends State<RetroGamePage> {
  static const String _viewType = 'retro-game-iframe';
  static bool _isFactoryRegistered = false;

  @override
  void initState() {
    super.initState();
    if (kIsWeb && !_isFactoryRegistered) {
      _isFactoryRegistered = true;
      // ignore: undefined_prefixed_name
      ui.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
        final iframe = html.IFrameElement()
          ..src = 'https://quoc-research-retrogame.web.app'
          ..style.border = '0'
          ..style.width = '100%'
          ..style.height = '100%'
          ..allow = 'autoplay; fullscreen; gamepad';

        return iframe;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return const SizedBox.expand(
        child: HtmlElementView(viewType: _viewType),
      );
    }

    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Retro game is available on Flutter Web at https://quoc-research-retrogame.web.app',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

