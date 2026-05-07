import 'package:flutter/widgets.dart';
import 'package:flutter_portfolio/view/bounce_game/bouncing_game.dart';
import 'package:flutter_portfolio/view/snake/main.dart';

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
  static final List<GameDefinition> games = [
    GameDefinition(
      id: 'tuoitho',
      label: 'Tuoi Tho (FBNeo)',
      builder: (_) => const SizedBox.shrink(),
    ),
    GameDefinition(
      id: 'snake',
      label: 'Snake',
      builder: (_) => const SnakeGame(),
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


