import 'package:flutter/material.dart';
import 'package:flutter_portfolio/view/projects/components/project_deatail.dart';
import 'package:get/get.dart';
import '../../../features/projects/domain/project.dart';
import '../../../res/constants.dart';
import '../../../view model/getx_controllers/projects_controller.dart';
import 'image_viewer.dart';

class ProjectStack extends StatelessWidget {
  final controller = Get.put(ProjectController());
  ProjectStack({super.key, required this.project});
  final Project project;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onHover: (value) {
        controller.onHover(project.name, value);
      },
      onTap: () {
        List<String>? images = project.images;
        if (images == null || images.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('No image available for this project')));
          return;
        }

        ImageViewer(context, images: images);
      },
      borderRadius: BorderRadius.circular(22),
      child: AnimatedContainer(
        padding: const EdgeInsets.only(
            left: defaultPadding, right: defaultPadding, top: defaultPadding),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(21), color: secondaryColor),
        duration: const Duration(milliseconds: 500),
        child: ProjectDetail(project: project),
      ),
    );
  }
}
