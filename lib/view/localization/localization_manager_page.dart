import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui' as ui;

/// Hosts the standalone Localization Manager tool (web/localization-manager.html)
/// in an iframe, like the other embedded tools.
class LocalizationManagerPage extends StatefulWidget {
  const LocalizationManagerPage({super.key});

  @override
  State<LocalizationManagerPage> createState() =>
      _LocalizationManagerPageState();
}

class _LocalizationManagerPageState extends State<LocalizationManagerPage> {
  static const String _viewType = 'localization-manager-iframe';
  static bool _isFactoryRegistered = false;

  @override
  void initState() {
    super.initState();
    if (kIsWeb && !_isFactoryRegistered) {
      _isFactoryRegistered = true;
      // ignore: undefined_prefixed_name
      ui.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
        return html.IFrameElement()
          ..src = Uri.base.resolve('localization-manager.html').toString()
          ..style.border = '0'
          ..style.width = '100%'
          ..style.height = '100%'
          ..allow = 'clipboard-read; clipboard-write; fullscreen';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return const SizedBox.expand(
        child: HtmlElementView(viewType: _viewType),
      );
    }
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text('Localization Manager is available on Flutter Web.',
            textAlign: TextAlign.center),
      ),
    );
  }
}
