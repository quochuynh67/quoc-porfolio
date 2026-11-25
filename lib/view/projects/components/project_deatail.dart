import 'package:flutter/material.dart';
import 'package:flutter_portfolio/view/projects/components/project_link.dart';

import '../../../features/projects/domain/project.dart';

class ProjectDetail extends StatelessWidget {
  final Project project;

  const ProjectDetail({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    final thumb = project.thumbnail;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (thumb != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 128,
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
          const SizedBox(height: 12),
        ],
        Text(
          project.name,
          style: Theme.of(context).textTheme.titleLarge!.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                height: 1.1,
              ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 7),
        Tooltip(
          message: project.description,
          child: Text(
            project.description,
            style: const TextStyle(color: Colors.white60, height: 1.35),
            maxLines: thumb != null ? 2 : 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 9),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: project.tags.take(3).map((tag) {
              return Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.cyanAccent.withOpacity(.08),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: Colors.cyanAccent.withOpacity(.18)),
                ),
                child: Text(tag,
                    style: const TextStyle(
                        color: Colors.cyanAccent, fontSize: 10)),
              );
            }).toList(),
          ),
        ),
        const Spacer(),
        ProjectLinks(project: project),
      ],
    );
  }
}
