import 'package:flutter/material.dart';
import 'package:flutter_portfolio/view%20model/getx_controllers/certification_controller.dart';
import 'package:flutter_portfolio/view/projects/components/title_text.dart';
import 'package:get/get.dart';
import '../../res/constants.dart';
import '../../view model/responsive.dart';
import 'components/others_grid.dart';
import '../../core/localization/app_locale.dart';

class OthersView extends StatelessWidget {
  final controller = Get.put(OtherController());
  OthersView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: Responsive.isLargeMobile(context) ? 16 : 30,
          vertical: defaultPadding,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (Responsive.isLargeMobile(context))
              const SizedBox(
                height: defaultPadding,
              ),
            TitleText(
              prefix: AppLocale.text('Notes & ', 'Ghi chú & '),
              title: AppLocale.text(
                  'Tools and Others', 'Công cụ và nội dung khác'),
            ),
            const SizedBox(
              height: defaultPadding,
            ),
            Expanded(child: OtherGrid())
          ],
        ),
      ),
    );
  }
}
