import 'package:flutter/material.dart';
import 'package:flutter_portfolio/view%20model/controller.dart';
import 'package:flutter_portfolio/res/constants.dart';
import 'package:flutter_portfolio/view/main/components/navigation_bar.dart';
import '../../view model/responsive.dart';
import 'components/drawer/drawer.dart';
import 'components/navigation_button_list.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
class MainView extends StatelessWidget {
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
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.jumpToPage(initialPage);
    });

    return Scaffold(
      drawer: videoViewMode ? null : const CustomDrawer(),
      body: Center(
        child: Column(
          children: [
            if (!videoViewMode) ...[
              kIsWeb && !Responsive.isLargeMobile(context) ? const SizedBox(height:defaultPadding*2,) : const SizedBox(height:defaultPadding/2,),
              const SizedBox(
                  height: 80,
                  child: TopNavigationBar(),
              ),
              if(Responsive.isLargeMobile(context))  const Row(children: [Spacer(),NavigationButtonList(),Spacer()],),
            ],
            Expanded(
                flex: 9,
                child: PageView(
                  scrollDirection: Axis.vertical,
                  physics: const NeverScrollableScrollPhysics(),
                  controller: controller,
                  children: [
                    ...pages
                  ],
                ),
            )
          ],
        ),
      ),
    );
  }
}








