import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../res/constants.dart';

class ConnectButton extends StatelessWidget {
  const ConnectButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: defaultPadding),
      child: InkWell(
        onTap: () {
          launchUrl(Uri.parse('https://zalo.me/0762985603'));
        },
        borderRadius: BorderRadius.circular(defaultPadding + 10),
        child: Container(
            height: 60,
            width: 150,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(defaultPadding),
                gradient: LinearGradient(colors: [
                  Colors.pink,
                  Colors.blue.shade900,
                ]),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.blue,
                      offset: Offset(0, -1),
                      blurRadius: defaultPadding / 4),
                  BoxShadow(
                      color: Colors.red,
                      offset: Offset(0, 1),
                      blurRadius: defaultPadding / 4),
                ]),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/icons/zalo.png',
                  height: 30,
                  width: 30,
                ),
                const SizedBox(width: defaultPadding / 4),
                Text(
                  'Zalo',
                  style: Theme.of(context).textTheme.labelSmall!.copyWith(
                      color: Colors.white,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: defaultPadding / 4),
                SizedBox.shrink()
              ],
            )),
      ),
    );
  }
}
