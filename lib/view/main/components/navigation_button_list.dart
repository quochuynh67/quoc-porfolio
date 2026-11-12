import 'package:flutter/material.dart';
import 'package:flutter_portfolio/core/navigation/app_navigation.dart';

import 'navigation_button.dart';

class NavigationButtonList extends StatelessWidget {
  const NavigationButtonList({super.key});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 200),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.05),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white.withOpacity(.08)),
            ),
            child: Row(
              children: [
                NavigationTextButton(onTap: () => goToPage(0), text: 'Home'),
                NavigationTextButton(
                    onTap: () => goToPage(1), text: 'Projects'),
                NavigationTextButton(onTap: () => goToPage(2), text: 'Others'),
              ],
            ),
          ),
        );
      },
    );
  }
}
