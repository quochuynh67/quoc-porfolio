import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../features/others/domain/other_item.dart';
import '../../../res/constants.dart';
import '../../../view model/getx_controllers/certification_controller.dart';
import 'others_details.dart';

class OtherGrid extends StatelessWidget {
  OtherGrid({super.key});
  final controller = Get.put(OtherController());
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: otherList.length,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 420,
          mainAxisExtent: 235,
          crossAxisSpacing: defaultPadding,
          mainAxisSpacing: defaultPadding),
      itemBuilder: (context, index) {
        return Obx(() => AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: const LinearGradient(colors: [
                  Colors.pinkAccent,
                  Colors.blue,
                ]),
                boxShadow: [
                  BoxShadow(
                    color: Colors.cyanAccent
                        .withOpacity(controller.hovers[index] ? .28 : .10),
                    blurRadius: controller.hovers[index] ? 20 : 8,
                  ),
                ]),
            child: OtherStack(index: index)));
      },
    );
  }
}
