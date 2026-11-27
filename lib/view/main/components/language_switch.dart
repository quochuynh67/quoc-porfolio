import 'package:flutter/material.dart';

import '../../../core/localization/app_locale.dart';

class LanguageSwitch extends StatelessWidget {
  const LanguageSwitch({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: AppLocale.language,
      builder: (context, language, _) {
        final isVietnamese = language == AppLanguage.vietnamese;
        return Semantics(
          button: true,
          label: isVietnamese ? 'Switch to English' : 'Chuyển sang tiếng Việt',
          child: Tooltip(
            message: isVietnamese ? 'English' : 'Tiếng Việt',
            child: InkWell(
              onTap: AppLocale.toggle,
              borderRadius: BorderRadius.circular(999),
              child: Container(
                height: 38,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .06),
                  borderRadius: BorderRadius.circular(999),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: .12)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _LanguageOption(label: 'EN', selected: !isVietnamese),
                    _LanguageOption(label: 'VI', selected: isVietnamese),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({required this.label, required this.selected});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      width: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: selected
            ? const LinearGradient(
                colors: [Color(0xffff2d8d), Color(0xff245bc6)],
              )
            : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : Colors.white54,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
