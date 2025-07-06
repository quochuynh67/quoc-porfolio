import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../model/other_model.dart';
import '../../../res/constants.dart';
import '../../../view model/getx_controllers/certification_controller.dart';
import 'others_details.dart';
class OtherGrid extends StatelessWidget {
  final int crossAxisCount;
  final double ratio;
  OtherGrid({super.key, this.crossAxisCount = 3,  this.ratio=1.3});
  final controller = Get.put(OtherController());
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      itemCount: otherList.length,
      gridDelegate:  SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount, childAspectRatio: ratio),
      itemBuilder: (context, index) {
        return Obx(() => AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(
                vertical: defaultPadding, horizontal: defaultPadding),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: const LinearGradient(colors: [
                  Colors.pinkAccent,
                  Colors.blue,
                ]),
                boxShadow:  [
                  BoxShadow(
                    color: Colors.pink,
                    offset: const Offset(-2, 0),
                    blurRadius: controller.hovers[index] ? 20 : 10,
                  ),
                  BoxShadow(
                    color: Colors.blue,
                    offset: const Offset(2, 0),
                    blurRadius: controller.hovers[index] ? 20 : 10,),
                ]),
            child: OtherStack(index: index)
        ));
      },
    );
  }
}