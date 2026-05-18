import 'package:flutter/material.dart';
import 'package:flutter_portfolio/view/others/others.dart';
import 'package:flutter_portfolio/view/intro/introduction.dart';
import 'package:flutter_portfolio/view/main/main_view.dart';
import 'package:flutter_portfolio/view/games/games_page.dart';
import 'package:flutter_portfolio/view/projects/project_view.dart';
import 'package:flutter_portfolio/view/retro_game/retro_game_page.dart';
import 'package:flutter_portfolio/view/vlog/feed_page.dart';

import '../../view model/controller.dart';
import '../customer_service/cs_screen.dart';
import '../media_tool/screen/screen.dart';
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  int _getPageIndexFromRoute(BuildContext context) {
    final uri = Uri.base;
    final path = uri.path; // e.g. "/projects"
    final game = uri.queryParameters['game'];

    if (game != null && game.isNotEmpty) {
      return routeToPageIndex['/games'] ?? 0;
    }

    print('_getPageIndexFromRoute Current path: $path');
    return routeToPageIndex[path] ?? 0;
  }

  bool isChillVideo() {
    final uri = Uri.base;
    final chill = uri.queryParameters['chill'];
    print('chill: $chill');
    return chill == '1';
  }

  bool isVideoViewMode() {
    final uri = Uri.base;
    final mode = uri.queryParameters['videoViewMode'];
    print('videoViewMode: $mode');
    return mode == '1';
  }

  bool isGameTabMode() {
    final uri = Uri.base;
    final game = uri.queryParameters['game'];
    return uri.path == '/games' || (game != null && game.isNotEmpty);
  }

  @override
  Widget build(BuildContext context) {
    final pageIndex = _getPageIndexFromRoute(context);
    final immersiveMode = isVideoViewMode() || isGameTabMode();

    return MainView(
      initialPage: pageIndex,
      videoViewMode: immersiveMode,
      pages: [
        const Introduction(),
        ProjectsView(),
        OthersView(),
        const MediaToolHomeScreen(),
        FeedPage(isPlayChillVideoAtFirst: isChillVideo()),
        const CsScreen(),
        const GamesPage(),
        const RetroGamePage(),
      ],
    );
  }
}

