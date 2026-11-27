import 'package:flutter/material.dart';
import 'package:flutter_portfolio/view/intro/components/subtitle_text.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../view model/responsive.dart';
import '../../../core/localization/app_locale.dart';

class CombineSubtitleText extends StatelessWidget {
  const CombineSubtitleText({super.key});

  @override
  Widget build(BuildContext context) {
    final rolePrefix = AppLocale.text('Mobile ', 'Lập trình viên ');
    final roleSuffix = AppLocale.text('Developer ', 'Mobile ');
    return Wrap(
      alignment: WrapAlignment.start,
      children: [
        Responsive(
          desktop: AnimatedSubtitleText(start: 30, end: 40, text: rolePrefix),
          largeMobile:
              AnimatedSubtitleText(start: 30, end: 25, text: rolePrefix),
          mobile: AnimatedSubtitleText(start: 25, end: 20, text: rolePrefix),
          tablet: AnimatedSubtitleText(start: 40, end: 30, text: rolePrefix),
        ),
        (kIsWeb && Responsive.isLargeMobile(context)
            ? Responsive(
                desktop: AnimatedSubtitleText(
                    start: 30, end: 40, text: roleSuffix, gradient: true),
                largeMobile: AnimatedSubtitleText(
                    start: 30, end: 25, text: roleSuffix, gradient: true),
                mobile: AnimatedSubtitleText(
                    start: 25, end: 20, text: roleSuffix, gradient: true),
                tablet: AnimatedSubtitleText(
                    start: 40, end: 30, text: roleSuffix, gradient: true),
              )
            : ShaderMask(
                shaderCallback: (bounds) {
                  return const LinearGradient(colors: [
                    Colors.pink,
                    Colors.blue,
                  ]).createShader(bounds);
                },
                child: Responsive(
                  desktop: AnimatedSubtitleText(
                      start: 30, end: 40, text: roleSuffix, gradient: false),
                  largeMobile: AnimatedSubtitleText(
                      start: 30, end: 25, text: roleSuffix, gradient: false),
                  mobile: AnimatedSubtitleText(
                      start: 25, end: 20, text: roleSuffix, gradient: true),
                  tablet: AnimatedSubtitleText(
                      start: 40, end: 30, text: roleSuffix, gradient: false),
                ),
              ))
      ],
    );
  }
}
