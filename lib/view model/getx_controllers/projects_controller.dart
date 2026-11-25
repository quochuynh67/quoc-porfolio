import 'package:get/get.dart';

class ProjectController extends GetxController {
  final RxMap<String, bool> hovers = <String, bool>{}.obs;

  void onHover(String key, bool value) {
    hovers[key] = value;
  }

  bool isHovered(String key) => hovers[key] ?? false;
}
