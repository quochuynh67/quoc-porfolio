import 'package:flutter/material.dart';
import 'package:flutter_portfolio/view/projects/components/project_link.dart';

import '../../../features/projects/domain/project.dart';
import '../../../res/constants.dart';
import '../../../view model/responsive.dart';

class ProjectDetail extends StatelessWidget {
  final Project project;

  const ProjectDetail({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.sizeOf(context);
    final thumb = project.thumbnail;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (thumb != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 160,
              width: double.infinity,
              child: Image.asset(thumb,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.medium,
                  errorBuilder: (_, __, ___) => const ColoredBox(
                      color: Color(0xFF1B2133),
                      child: Icon(Icons.image_not_supported_outlined,
                          color: Colors.white54))),
            ),
          ),
          const SizedBox(height: 10),
        ],
        Align(
          alignment: Alignment.topCenter,
          child: Text(
            project.name,
            style: Theme.of(context)
                .textTheme
                .headlineSmall!
                .copyWith(color: Colors.white, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Responsive.isMobile(context)
            ? const SizedBox(
                height: defaultPadding / 2,
              )
            : const SizedBox(
                height: defaultPadding,
              ),
        Tooltip(
          message: project.description,
          child: Text(
            project.description,
            style: const TextStyle(color: Colors.grey, height: 1.5),
            maxLines: thumb != null
                ? 2
                : size.width > 700 && size.width < 750
                    ? 3
                    : size.width < 470
                        ? 2
                        : size.width > 600 && size.width < 700
                            ? 6
                            : size.width > 900 && size.width < 1060
                                ? 6
                                : 4,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Tooltip(
          message: project.tags.join(', '),
          child: Text.rich(
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            TextSpan(
              text: 'Tag: ',
              style: const TextStyle(color: Colors.white),
              children: [
                TextSpan(
                  text: project.tags.join(', '),
                  style: const TextStyle(
                      color: Colors.grey, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
        ),
        const Spacer(),
        ProjectLinks(project: project),
        const SizedBox(
          height: defaultPadding / 2,
        ),
      ],
    );
  }
}
