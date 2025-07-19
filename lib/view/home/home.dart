import 'package:flutter/material.dart';
import 'package:flutter_portfolio/view/others/others.dart';
import 'package:flutter_portfolio/view/intro/introduction.dart';
import 'package:flutter_portfolio/view/main/main_view.dart';
import 'package:flutter_portfolio/view/projects/project_view.dart';
import 'package:flutter_portfolio/view/vlog/feed_page.dart';

import '../../view model/controller.dart';
import '../customer_service/cs_screen.dart';
import '../media_tool/screen/screen.dart';
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  int _getPageIndexFromRoute(BuildContext context) {
    final uri = Uri.base;
    final path = uri.path; // e.g. "/projects"

    print('_getPageIndexFromRoute Current path: $path');
    return routeToPageIndex[path] ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final pageIndex = _getPageIndexFromRoute(context);
    return MainView(
      initialPage: pageIndex,
      pages: [
        const Introduction(),
        ProjectsView(),
        OthersView(),
        const MediaToolHomeScreen(),
        const FeedPage(),
        const CsScreen(),
      ],
    );
  }
}

