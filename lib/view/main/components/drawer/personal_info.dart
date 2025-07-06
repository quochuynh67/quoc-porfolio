import 'package:flutter/material.dart';

import '../../../../res/constants.dart';
import 'header_info.dart';

class PersonalInfo extends StatelessWidget {
  const PersonalInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: defaultPadding/2,),
        AreaInfoText(title: 'Contact', text: '0762985603'),
        AreaInfoText(title: 'Email', text: 'quocb14005xx@gmail.com'),
        AreaInfoText(title: 'LinkedIn', text: '@huynh-quoc-8480b1127'),
        AreaInfoText(title: 'Facebook', text: '@quochuynh1996'),
        AreaInfoText(title: 'Github', text: '@quochuynh67'),
        SizedBox(
          height: defaultPadding,
        ),
        Text('Skills',style: TextStyle(color: Colors.white),),
        SizedBox(
          height: defaultPadding,
        ),
      ],
    );
  }
}
