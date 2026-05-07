import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui' as ui;

import 'game_registry.dart';

class GamesPage extends StatefulWidget {
  const GamesPage({super.key});

  @override
  State<GamesPage> createState() => _GamesPageState();
}

class _GamesPageState extends State<GamesPage> {
  static const String _viewType = 'tuoitho-fbneo-iframe';
  static bool _isFactoryRegistered = false;

  @override
  void initState() {
    super.initState();
    if (kIsWeb && !_isFactoryRegistered) {
      _isFactoryRegistered = true;
      // ignore: undefined_prefixed_name
      ui.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
        final iframe = html.IFrameElement()
          ..src = Uri.base.resolve('/tuoitho/EJS-fbneo.html').toString()
          ..style.border = '0'
          ..style.width = '100%'
          ..style.height = '100%'
          ..allow = 'autoplay; fullscreen; gamepad; clipboard-read; clipboard-write';

        return iframe;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedGameId = Uri.base.queryParameters['game'] ?? 'bounce';

    if (selectedGameId == 'tuoitho') {
      if (kIsWeb) {
        return const SizedBox.expand(
          child: HtmlElementView(viewType: _viewType),
        );
      }

      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Game "tuoitho" is available on Flutter Web at /tuoitho/EJS-fbneo.html',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final selectedGame = GameRegistry.findById(selectedGameId);
    if (selectedGame != null) {
      return selectedGame.builder(context);
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Unknown game id. Use URL query parameter "game".',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text('Examples: /games?game=bounce, /games?game=snake, /games?game=tuoitho'),
            const SizedBox(height: 12),
            ...GameRegistry.games.map((game) => Text('- ${game.id}: ${game.label}')),
          ],
        ),
      ),
    );
  }
}

