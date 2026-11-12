enum ProjectSection { company, personal }

class Project {
  final String name;
  final String description;
  final List<String>? images;
  final List<String> tags;
  final String? link;
  final String? githubLink;
  final ProjectSection section;
  final String? cover;

  /// Small pre-scaled JPEG (`thumb_<name>.jpg` next to the original) used on
  /// cards. Avoids decoding multi-megapixel screenshots on the web, which
  /// triggers CanvasKit "texImage2D: source data has been detached" and
  /// renders black images.
  String? get thumbnail {
    final source =
        cover ?? ((images?.isNotEmpty ?? false) ? images!.first : null);
    if (source == null) return null;
    final slash = source.lastIndexOf('/');
    final dot = source.lastIndexOf('.');
    return '${source.substring(0, slash + 1)}thumb_${source.substring(slash + 1, dot)}.jpg';
  }

  Project(this.name, this.description, this.images, this.link,
      {this.githubLink,
      this.tags = const [],
      this.section = ProjectSection.company,
      this.cover});
}

List<Project> projectList = [
  // TODO: tạm tắt project CRM
  /*
  Project(
    'Customer service CRM',
    'Customer service CRM for agencies to manage customer requests via chat (human, bot, AI Agent)',
    [
      'assets/images/projects/cs/cs_1.png',
      'assets/images/projects/cs/cs_2.png',
      'assets/images/projects/cs/cs_3.png',
      'assets/images/projects/cs/cs_4.png',
      'assets/images/projects/cs/cs_5.png',
      'assets/images/projects/cs/cs_6.png',
      'assets/images/projects/cs/cs_7.png',
      'assets/images/projects/cs/cs_8.png',
    ],
    null,
    tags: ['flutter web canvaskit', 'web', 'websocket', 'chatting', 'livechat'],
  ),
  */
  Project(
    'ViiV',
    'Connecting the world of travel through vlogs\nViiV, an all-in-one travel app just for you',
    [
      'assets/images/projects/viiv/viiv.png',
      'assets/images/projects/viiv/viiv_1.jpg',
      'assets/images/projects/viiv/viiv_2.jpg',
      'assets/images/projects/viiv/viiv_3.jpg',
      'assets/images/projects/viiv/viiv_4.jpg',
      'assets/images/projects/viiv/viiv_5.jpg',
      'assets/images/projects/viiv/viiv_6.jpg',
      'assets/images/projects/viiv/viiv_7.jpg',
      'assets/images/projects/viiv/viiv_8.jpg',
      'assets/images/projects/viiv/viiv_9.jpg',
    ],
    'https://viiv.app',
    tags: ['mobile', 'android native', 'ios native', 'flutter'],
  ),
  Project(
    'HanyBany',
    'HanyBany is a mind care chatbot that helps modern people increase their happiness through conversation. The chatbot conversation is designed based on interventions developed based on positive psychology.',
    [
      'assets/images/projects/chatbot/chatbot_1.jpg',
      'assets/images/projects/chatbot/chatbot_2.jpg',
      'assets/images/projects/chatbot/chatbot_3.jpg',
      'assets/images/projects/chatbot/chatbot_4.jpg',
      'assets/images/projects/chatbot/chatbot_5.jpg',
      'assets/images/projects/chatbot/chatbot_6.jpg',
    ],
    'https://apkpure.com/vn/해니-기업전용/com.bloomcompany.hanny',
    tags: ['mobile', 'flutter only'],
  ),
  Project(
      'AloxideSDK',
      'While there are a lot of blockchain softwares available and it\'s not uncommon to see a requirement to support various blockchains, it still requires a significant amount of time to learn how to write a smart contract just printing "Hello World" per blockchain. Aloxide provides a pragmatic abstraction for various blockchain softwares includingCAN, EOS, ICON, and so on so that you can focus on business logic on smart contracts without ties to specific blockchain natures. Also based on the abstraction Aloxide offers useful tool-kits for dApp development such asAPI gateway and SDK.',
      [
        'assets/images/projects/aloxide/aloxide.png',
        'assets/images/projects/aloxide/aloxide_1.png',
        'assets/images/projects/aloxide/aloxide_2.png',
      ],
      null,
      tags: ['sdk', 'java', 'swift'],
      githubLink: 'https://github.com/lecle/aloxide-sdk-java'),
  Project(
    'App modular builder',
    'Build modular app with ease',
    [
      'assets/images/projects/modular/modular_builder.png',
      'assets/images/projects/modular/modular_builder_1.png',
    ],
    'https://lecle-app-modular-builder.web.app/',
    tags: ['web', 'flutter canvaskit only'],
  ),
  Project(
    'RB Land',
    'Karaoke and record your moment on RB Land',
    [
      'assets/images/projects/rbland/rbland.png',
      'assets/images/projects/rbland/rbland_1.jpg',
      'assets/images/projects/rbland/rbland_2.jpg',
      'assets/images/projects/rbland/rbland_3.jpg',
    ],
    'https://apkpure.com/vn/rbland/vn.com.rbland.app',
    tags: ['mobile', 'flutter only'],
  ),
  Project(
    'tattantat67k1',
    'A personal collection inspired by childhood memories, hometown culture, and the retro games I grew up with.',
    ['assets/images/quoc_logo.png'],
    'https://tattantat67k1.web.app/',
    githubLink: 'https://github.com/quochuynh67/quoc-porfolio',
    tags: ['personal', 'flutter web', 'retro game'],
    section: ProjectSection.personal,
  ),
  Project(
    '67Talk',
    'An omnichannel customer-service platform for managing realtime conversations, tickets, automations, teams, reports, and AI-assisted support across web, desktop, Android, and iOS.',
    [
      'assets/images/projects/67talk/67talk-device-mockup-16x9.png',
      'assets/images/projects/67talk/67talk-automation-report-square.png',
      'assets/images/projects/67talk/67talk-integrations-square.png',
      'assets/images/projects/67talk/67talk-facebook-poster-4x5.png',
      'assets/images/projects/67talk/67talk-facebook-poster-test1-v2.png',
      'assets/images/projects/67talk/67talk-automation-team-test1.png',
    ],
    'https://talk67talk.web.app/',
    githubLink: 'https://github.com/quocb14005xx/67talk',
    tags: ['personal', 'react', 'typescript', 'realtime', 'electron', 'AI'],
    section: ProjectSection.personal,
    cover: 'assets/images/projects/67talk/67talk-device-mockup-16x9.png',
  ),
];
