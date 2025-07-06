import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../model/other_model.dart';
import '../../../res/constants.dart';
import '../../../view model/getx_controllers/certification_controller.dart';

class OtherStack extends StatelessWidget {
  final controller = Get.put(OtherController());

  OtherStack({super.key, required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onHover: (value) {
        controller.onHover(index, value);
      },
      onTap: () {},
      borderRadius: BorderRadius.circular(30),
      child: AnimatedContainer(
          padding: const EdgeInsets.all(defaultPadding),
          height: double.infinity,
          width: double.infinity,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30), color: bgColor),
          duration: const Duration(milliseconds: 500),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  otherList[index].name,
                  style: Theme.of(context).textTheme.titleSmall!.copyWith(
                      color: Colors.white, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(
                  height: defaultPadding / 2,
                ),
                Tooltip(
                  message: otherList[index].skills.join(', '),
                  child: Text.rich(
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    TextSpan(
                        text: 'Skills : ',
                        style: const TextStyle(
                          color: Colors.white,
                          overflow: TextOverflow.ellipsis,
                        ),
                        children: [
                          ...otherList[index].skills.map((skill) => TextSpan(
                                text: '$skill, ',
                                style: const TextStyle(
                                    color: Colors.grey,
                                    overflow: TextOverflow.ellipsis),
                              )),
                        ]),
                  ),
                ),
                const SizedBox(
                  height: defaultPadding,
                ),
                InkWell(
                  onTap: () {
                    launchUrl(Uri.parse(otherList[index].link));
                  },
                  child: Container(
                    height: 40,
                    width: 150,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        gradient: LinearGradient(colors: [
                          Colors.pink,
                          Colors.blue.shade900,
                        ]),
                        boxShadow: const [
                          BoxShadow(
                              color: Colors.blue,
                              offset: Offset(0, -1),
                              blurRadius: 5),
                          BoxShadow(
                              color: Colors.red,
                              offset: Offset(0, 1),
                              blurRadius: 5),
                        ]),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Details',
                          style: TextStyle(color: Colors.white, fontSize: 10),
                        ),
                        SizedBox(
                          width: 5,
                        ),
                        Icon(
                          CupertinoIcons.arrow_turn_up_right,
                          color: Colors.white,
                          size: 10,
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          )),
    );
  }
}
