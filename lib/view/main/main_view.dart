import 'dart:async';
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:flutter_portfolio/core/navigation/app_navigation.dart';
import 'package:flutter_portfolio/view/main/components/navigation_bar.dart';
import '../../view model/responsive.dart';
import 'components/drawer/drawer.dart';
import 'components/navigation_button_list.dart';

class MainView extends StatefulWidget {
  final List<Widget> pages;
  final int initialPage;
  final bool videoViewMode;

  const MainView({
    super.key,
    required this.pages,
    this.initialPage = 0,
    this.videoViewMode = false,
  });

  @override
  State<MainView> createState() => _MainViewState();
}

class _MainViewState extends State<MainView> {
  StreamSubscription<html.Event>? _popSub;

  /// Keep the visible page in sync with the URL on browser back/next instead
  /// of letting the router rebuild everything.
  void _syncPageWithUrl(html.Event _) {
    final uri = Uri.base;
    final game = uri.queryParameters['game'];
    final index = (game != null && game.isNotEmpty)
        ? routeToPageIndex['/games']
        : routeToPageIndex[uri.path];
    if (index == null || index >= widget.pages.length || !mounted) return;
    if (currentPage.value == index) return;
    currentPage.value = index;
    if (controller.positions.length == 1) controller.jumpToPage(index);
  }

  @override
  void dispose() {
    _popSub?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _popSub = html.window.on['app-popstate'].listen(_syncPageWithUrl);
    currentPage.value = widget.initialPage;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && controller.hasClients) {
        controller.jumpToPage(widget.initialPage);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: widget.videoViewMode ? null : const CustomDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            if (!widget.videoViewMode) ...[
              SizedBox(
                height: Responsive.useCompactNavigation(context) ? 64 : 76,
                child: TopNavigationBar(),
              ),
              if (Responsive.useCompactNavigation(context))
                const SizedBox(
                  height: 50,
                  child: Center(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: NavigationButtonList(),
                    ),
                  ),
                ),
            ],
            Expanded(
              flex: 9,
              child: PageView.builder(
                scrollDirection: Axis.vertical,
                physics: const NeverScrollableScrollPhysics(),
                controller: controller,
                itemCount: widget.pages.length,
                itemBuilder: (context, index) {
                  return ValueListenableBuilder<int>(
                    valueListenable: currentPage,
                    builder: (context, selectedPage, _) {
                      if (selectedPage != index) {
                        return const SizedBox.shrink();
                      }
                      return widget.pages[index];
                    },
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
