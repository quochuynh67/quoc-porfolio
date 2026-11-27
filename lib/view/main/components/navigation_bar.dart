import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_portfolio/view%20model/responsive.dart';
import 'package:flutter_portfolio/view/intro/components/side_menu_button.dart';
import 'package:flutter_portfolio/view/main/components/connect_button.dart';
import 'navigation_button_list.dart';
import 'language_switch.dart';

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
                  ? SvgPicture.asset(
                      'assets/images/quoc67_brand.svg',
                      width: 148,
                      height: 46,
                      fit: BoxFit.contain,
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        MenuButton(
                          onTap: () => Scaffold.of(context).openDrawer(),
                        ),
                        const SizedBox(width: 8),
                        SvgPicture.asset(
                          'assets/images/quoc67_brand.svg',
                          width: 84,
                          height: 36,
                          fit: BoxFit.contain,
                        ),
                      ],
                    ),
            ),
            // if(Responsive.isLargeMobile(context)) MenuButton(),
            const Spacer(),
            if (!Responsive.useCompactNavigation(context))
              const NavigationButtonList(),
            const Spacer(),
            const ConnectButton(),
            const SizedBox(width: 10),
            const LanguageSwitch(),
          ],
        ),
      ),
    );
  }
}
