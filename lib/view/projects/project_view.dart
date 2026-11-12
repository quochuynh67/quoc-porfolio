import 'package:flutter/material.dart';
import 'package:flutter_portfolio/res/constants.dart';
import 'package:flutter_portfolio/view%20model/getx_controllers/projects_controller.dart';
import 'package:flutter_portfolio/view%20model/responsive.dart';
import 'package:flutter_portfolio/view/projects/components/title_text.dart';
import 'package:get/get.dart';
import '../../features/projects/domain/project.dart';
import 'components/projects_grid.dart';

class ProjectsView extends StatelessWidget {
  ProjectsView({super.key});
  final controller = Get.put(ProjectController());
  @override
  Widget build(BuildContext context) {
    final companyProjects = projectList
        .where((project) => project.section == ProjectSection.company)
        .toList();
    final personalProjects = projectList
        .where((project) => project.section == ProjectSection.personal)
        .toList();
    final width = MediaQuery.sizeOf(context).width;
    final columns = width >= 1180
        ? 3
        : width >= 680
            ? 2
            : 1;

    Widget section(String title, String subtitle, List<Project> projects) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 28,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.pinkAccent, Colors.cyanAccent],
                  ),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white, fontWeight: FontWeight.w700)),
                    Text(subtitle,
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: defaultPadding),
          ProjectGrid(
            projects: projects,
            crossAxisCount: columns,
            cardHeight: (columns == 1 ? 300 : 290) +
                (projects.any((p) => p.thumbnail != null) ? 190 : 0),
          ),
        ],
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.isLargeMobile(context) ? 16 : 30,
              vertical: defaultPadding,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (Responsive.isLargeMobile(context))
                  const SizedBox(
                    height: defaultPadding,
                  ),
                const TitleText(prefix: '', title: 'Projects'),
                const SizedBox(
                  height: defaultPadding * 1.5,
                ),
                section('Company', 'Products built with professional teams',
                    companyProjects),
                const SizedBox(height: defaultPadding * 2),
                section('Personal', 'Independent ideas and experiments',
                    personalProjects),
                const SizedBox(height: defaultPadding * 2),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
