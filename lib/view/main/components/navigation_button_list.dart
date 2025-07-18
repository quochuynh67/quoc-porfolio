import 'package:flutter/material.dart';
import 'package:flutter_portfolio/view%20model/controller.dart';
import 'package:flutter_portfolio/view%20model/responsive.dart';

import 'navigation_button.dart';
import 'dart:html' as html;

class NavigationButtonList extends StatelessWidget {
  const NavigationButtonList({super.key});
  void goToPage(int index) {
    controller.animateToPage(index,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeIn);
    final newPath = routeToPageIndex.entries.firstWhere((e) => e.value == index).key;
    // Updates the URL without reload
    final uri = Uri(path: newPath);
    html.window.history.pushState(null, '', uri.toString());
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 200),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Row(
            children: [
              NavigationTextButton(
                  onTap: () {
                    // controller.animateToPage(0,
                    //     duration: const Duration(milliseconds: 500),
                    //     curve: Curves.easeIn);
                    goToPage(0);
                  },
                  text: 'Home'),
              NavigationTextButton(
                  onTap: () {
                    // controller.animateToPage(1,
                    //     duration: const Duration(milliseconds: 500),
                    //     curve: Curves.easeIn);
                    goToPage(1);
                  },
                  text: 'Projects'),
              NavigationTextButton(
                  onTap: () {
                    // controller.animateToPage(2,
                    //     duration: const Duration(milliseconds: 500),
                    //     curve: Curves.easeIn);
                    goToPage(2);
                  },
                  text: 'Others'),
              NavigationTextButton(
                  onTap: () {
                    // controller.animateToPage(3,
                    //     duration: const Duration(milliseconds: 500),
                    //     curve: Curves.easeIn);
                    goToPage(3);
                  },
                  text: 'Tools'),
              NavigationTextButton(onTap: () {
                // controller.animateToPage(4,
                //     duration: const Duration(milliseconds: 500),
                //     curve: Curves.easeIn);
                goToPage(4);
              }, text: 'FlutterWeb_Vlogs'),
            ],
          ),
        );
      },
    );
  }
}
