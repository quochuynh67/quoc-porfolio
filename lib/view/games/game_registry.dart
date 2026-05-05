import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_portfolio/view/bounce_game/bouncing_game.dart';
import 'package:flutter_portfolio/view/snake/main.dart';

import '../../view model/controller.dart';

class GameDefinition {
  final String id;
  final String label;
  final WidgetBuilder builder;

  const GameDefinition({
    required this.id,
    required this.label,
    required this.builder,
  });
}

class GameRegistry {
  static void _goHome() {
    controller.animateToPage(
      routeToPageIndex['/'] ?? 0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeIn,
    );
    SystemNavigator.routeInformationUpdated(uri: Uri(path: '/'));
  }

  static final List<GameDefinition> games = [
    GameDefinition(
      id: 'snake',
      label: 'Snake',
      builder: (_) => SnakeGame(),
    ),
    GameDefinition(
      id: 'bounce',
      label: 'Bounce',
      builder: (_) => const BouncingGame(),
    ),
  ];

  static GameDefinition? findById(String? id) {
    if (id == null || id.isEmpty) {
      return null;
    }

    for (final game in games) {
      if (game.id == id) {
        return game;
      }
    }

    return null;
  }
}


