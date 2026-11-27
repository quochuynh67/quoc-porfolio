import 'package:flutter/material.dart';

import '../../../view model/responsive.dart';
import '../../../core/localization/app_locale.dart';

class AnimatedDescriptionText extends StatelessWidget {
  const AnimatedDescriptionText(
      {super.key, required this.start, required this.end});
  final double start;
  final double end;
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder(
      tween: Tween(begin: start, end: end),
      duration: const Duration(milliseconds: 200),
      builder: (context, value, child) {
        return Text(
          AppLocale.text(
            'I\'m capable of creating excellent mobile apps, handling every step from concept to deployment.',
            'Tôi xây dựng ứng dụng mobile chất lượng, đảm nhiệm toàn bộ quy trình từ ý tưởng đến triển khai.',
          ),
          maxLines: Responsive.isMobile(context) ? 4 : 3,
          style: TextStyle(color: Colors.grey, wordSpacing: 2, fontSize: value),
        );
      },
    );
  }
}
