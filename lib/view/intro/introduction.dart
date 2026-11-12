import 'package:flutter/material.dart';
import 'package:flutter_portfolio/view%20model/responsive.dart';
import 'package:flutter_portfolio/view/intro/components/intro_body.dart';
import 'package:flutter_portfolio/view/intro/components/side_menu_button.dart';
import 'package:flutter_portfolio/view/intro/components/social_media_list.dart';

class Introduction extends StatelessWidget {
  const Introduction({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
          child: Row(
        children: [
          if (!Responsive.useCompactNavigation(context)) ...[
            const SizedBox(width: 12),
            MenuButton(onTap: () => Scaffold.of(context).openDrawer()),
            const SizedBox(width: 20),
            const SocialMediaIconList(),
            const SizedBox(width: 32),
          ],
          const Expanded(
            child: IntroBody(),
          ),
        ],
      )),
    );
  }
}
