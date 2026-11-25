import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../features/others/domain/other_item.dart';
import '../../../res/constants.dart';
import '../../../view model/getx_controllers/certification_controller.dart';
import '../../../core/navigation/app_navigation.dart';

class OtherStack extends StatelessWidget {
  final controller = Get.put(OtherController());

  OtherStack({super.key, required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final item = otherList[index];
    void openItem() {
      if (item.pageIndex != null) {
        goToPage(item.pageIndex!, queryParameters: item.queryParameters);
      } else if (item.link != null) {
        launchUrl(Uri.parse(item.link!));
      }
    }

    return InkWell(
      onHover: (value) {
        controller.onHover(index, value);
      },
      onTap: openItem,
      borderRadius: BorderRadius.circular(22),
      child: AnimatedContainer(
          padding: const EdgeInsets.all(defaultPadding),
          height: double.infinity,
          width: double.infinity,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(21), color: secondaryColor),
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
                Text(
                  '${item.type}  •  ${item.date}',
                  style:
                      const TextStyle(color: Colors.cyanAccent, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: defaultPadding / 2),
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
                    openItem();
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          item.pageIndex == null ? 'Open link' : 'Explore',
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
