import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../model/project_model.dart';

class ProjectLinks extends StatelessWidget {
  final int index;

  const ProjectLinks({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    String? link = projectList[index].link;
    String? githubLink = projectList[index].githubLink;
    return Row(
      children: [
        Row(
          children: [
            Text('Check on Github',
                style: TextStyle(
                    color: githubLink != null ? Colors.white : Colors.grey,
                    fontWeight: githubLink != null ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12),
                overflow: TextOverflow.ellipsis),
            IconButton(
                onPressed: () {
                  if (githubLink == null || githubLink.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('No link available for this project')));
                    return;
                  }
                  launchUrl(Uri.parse(githubLink));
                },
                icon: SvgPicture.asset('assets/icons/github.svg')),
          ],
        ),
        const Spacer(),
        TextButton(
            onPressed: () {
              if (link == null || link.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('No link available for this project')));
                return;
              }
              launchUrl(Uri.parse(link));
            },
            child: Text(
              'Read More>>',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: link != null ? Colors.amber : Colors.grey,
                  fontWeight: link != null ? FontWeight.bold : FontWeight.normal,
                  fontSize: 10),
            ))
      ],
    );
  }
}
