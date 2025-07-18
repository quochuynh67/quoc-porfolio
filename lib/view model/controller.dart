import 'package:flutter/material.dart';

final PageController controller=PageController();
final Map<String, int> routeToPageIndex = {
  '/': 0,
  '/projects': 1,
  '/others': 2,
  '/mediaTools': 3,
  '/flutterVlogs': 4,
};