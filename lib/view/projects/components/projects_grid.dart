import 'package:flutter/material.dart';
import 'package:flutter_portfolio/view/projects/components/project_info.dart';
import 'package:get/get.dart';
import '../../../features/projects/domain/project.dart';
import '../../../res/constants.dart';
import '../../../view model/getx_controllers/projects_controller.dart';

class ProjectGrid extends StatelessWidget {
  final int crossAxisCount;
  final double cardHeight;
  final List<Project> projects;
  ProjectGrid(
      {super.key,
      required this.projects,
      this.crossAxisCount = 3,
      this.cardHeight = 290});
  final controller = Get.put(ProjectController());
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: projects.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisExtent: cardHeight,
          crossAxisSpacing: defaultPadding,
          mainAxisSpacing: defaultPadding),
      itemBuilder: (context, index) {
        final project = projects[index];
        return Obx(() => AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: const LinearGradient(colors: [
                  Colors.pinkAccent,
                  Colors.blue,
                ]),
                boxShadow: [
                  BoxShadow(
                    color: Colors.cyanAccent.withOpacity(
                        controller.isHovered(project.name) ? .28 : .10),
                    blurRadius: controller.isHovered(project.name) ? 22 : 10,
                  )
                ]),
            child: ProjectStack(project: project)));
      },
    );
  }
}
