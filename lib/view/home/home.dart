import 'package:flutter/material.dart';
import 'package:flutter_portfolio/view/others/others.dart';
import 'package:flutter_portfolio/view/intro/introduction.dart';
import 'package:flutter_portfolio/view/main/main_view.dart';
import 'package:flutter_portfolio/view/projects/project_view.dart';
import 'package:flutter_portfolio/view/vlog/feed_page.dart';

import '../media_tool/screen/screen.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return  MainView(pages: [
      const Introduction(),
      ProjectsView(),
      OthersView(),
      const MediaToolHomeScreen(),
      const FeedPage(),
    ]);
  }
}
