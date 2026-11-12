import 'package:flutter/material.dart';
import 'package:flutter_portfolio/view%20model/responsive.dart';
import 'package:flutter_portfolio/view/intro/components/side_menu_button.dart';
import 'package:flutter_portfolio/view/main/components/connect_button.dart';
import '../../../res/constants.dart';
import 'navigation_button_list.dart';

class TopNavigationBar extends StatelessWidget {
  const TopNavigationBar({super.key});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: Responsive.useCompactNavigation(context) ? 12 : 28,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: !Responsive.useCompactNavigation(context)
                  ? Image.asset('assets/images/quoc_logo.png')
                  : MenuButton(
                      onTap: () => Scaffold.of(context).openDrawer(),
                    ),
            ),
            // if(Responsive.isLargeMobile(context)) MenuButton(),
            const Spacer(),
            if (!Responsive.useCompactNavigation(context))
              const NavigationButtonList(),
            const Spacer(),
            const ConnectButton(),
          ],
        ),
      ),
    );
  }
}
