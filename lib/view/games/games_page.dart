import 'package:flutter/material.dart';

import 'game_registry.dart';

class GamesPage extends StatelessWidget {
  const GamesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final selectedGameId = Uri.base.queryParameters['game'] ?? 'snake';
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
              'Pick a game using URL query parameter.',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Examples: /games?game=bounce or /games?game=snake',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ...GameRegistry.games.map(
              (game) => Text(' - ${game.id}: ${game.label}'),
            ),
          ],
        ),
      ),
    );
  }
}

