import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/navigation/app_navigation.dart';
import '../../../features/projects/domain/project.dart';

class ProjectLinks extends StatelessWidget {
  final Project project;

  const ProjectLinks({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    String? link = project.link;
    String? githubLink = project.githubLink;
    return Row(
      children: [
        if (githubLink != null && githubLink.isNotEmpty)
          IconButton(
            tooltip: 'View source',
            visualDensity: VisualDensity.compact,
            onPressed: () => launchUrl(Uri.parse(githubLink)),
            icon: SvgPicture.asset('assets/icons/github.svg',
                width: 20, height: 20),
          ),
        const Spacer(),
        TextButton.icon(
          onPressed: project.pageIndex != null
              ? () => goToPage(project.pageIndex!)
              : link == null || link.isEmpty
                  ? null
                  : () => launchUrl(Uri.parse(link)),
          icon: const Icon(Icons.open_in_new_rounded, size: 16),
          label: const Text('Open project'),
          style: TextButton.styleFrom(
            foregroundColor: Colors.amber,
            visualDensity: VisualDensity.compact,
            textStyle:
                const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          ),
        ),
      ],
    );
  }
}
