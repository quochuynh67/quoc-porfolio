import 'package:flutter/material.dart';
import 'dart:html' as html;

final PageController controller = PageController();
final ValueNotifier<int> currentPage = ValueNotifier<int>(0);
final Map<String, int> routeToPageIndex = {
  '/': 0,
  '/projects': 1,
  '/others': 2,
  '/mediaTools': 3,
  '/flutterVlogs': 4,
  '/jx2-web': 4,
  '/chatWithMe': 5,
  '/games': 6,
  '/retroGame': 7,
  '/localizationManager': 8,
};

void goToPage(int index, {Map<String, String>? queryParameters}) {
  currentPage.value = index;
  controller.animateToPage(
    index,
    duration: const Duration(milliseconds: 450),
    curve: Curves.easeInOutCubic,
  );
  final path =
      routeToPageIndex.entries.firstWhere((entry) => entry.value == index).key;
  html.window.history.pushState(
    null,
    '',
    Uri(path: path, queryParameters: queryParameters).toString(),
  );
}

/// Browser tab title for each page index (same indexes as [routeToPageIndex]).
const Map<int, String> pageTitles = {
  0: 'Home',
  1: 'Projects',
  2: 'Others',
  3: 'Media Tools',
  4: 'Vlogs',
  5: 'Chat With Me',
  6: 'Games',
  7: 'Retro Game',
  8: 'Localization Manager',
};

const String siteTitle = 'Quoc67k1';

void updateDocumentTitle(int index) {
  final title = pageTitles[index];
  if (title != null) html.document.title = '$siteTitle - $title';
}
