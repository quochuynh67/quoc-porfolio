import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_portfolio/view%20model/getx_controllers/certification_controller.dart';
import 'package:flutter_portfolio/view/projects/components/title_text.dart';
import 'package:get/get.dart';
import '../../res/constants.dart';
import '../../view model/responsive.dart';
import 'components/others_grid.dart';

class OthersView extends StatelessWidget {
  final controller=Get.put(OtherController());
   OthersView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if(Responsive.isLargeMobile(context))const SizedBox(
            height: defaultPadding,
          ),
          const TitleText(prefix: 'Notes & ', title: 'Tools and Others'),
          const SizedBox(
            height: defaultPadding,
          ),
          Expanded(
              child: Responsive(
                  desktop: OtherGrid(crossAxisCount: 3,ratio: 1.5,),
                  extraLargeScreen: OtherGrid(crossAxisCount: 4,ratio: 1.6),
                  largeMobile: OtherGrid(crossAxisCount: 1,ratio: 1.8),
                  mobile: OtherGrid(crossAxisCount: 1,ratio: 1.4),
                  tablet: OtherGrid(ratio: 1.7,crossAxisCount: 2,)))
        ],
      ),
    );
  }
}










