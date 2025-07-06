class Project {
  final String name;
  final String description;
  final String? image;
  final List<String> tags;
  final String? link;
  final String? githubLink;

  Project(this.name, this.description, this.image, this.link,
      {this.githubLink, this.tags = const []});
}

List<Project> projectList = [
  Project(
    'CRM Website',
    'A CRM (Customer Relationship Management) website is a web-based platform designed to help businesses manage their interactions with customers, streamline processes, and improve overall customer relationships. It typically includes features such as contact management, sales tracking, lead generation, and customer support.',
    null,
    null,
    tags: ['only flutter canvaskit', 'web'],
  ),
  Project(
    'ViiV',
    'Connecting the world of travel through vlogs\nViiV, an all-in-one travel app just for you',
    'assets/images/viiv.png',
    'https://viiv.app',
    tags: ['mobile', 'android native', 'ios native', 'flutter'],
  ),
  Project(
    'HanyBany',
    'HanyBany is a mind care chatbot that helps modern people increase their happiness through conversation. The chatbot conversation is designed based on interventions developed based on positive psychology.',
    'assets/images/chatbot.png',
    'https://apkpure.com/vn/해니-기업전용/com.bloomcompany.hanny',
    tags: ['mobile', 'flutter only'],
  ),
  Project(
      'AloxideSDK',
      'While there are a lot of blockchain softwares available and it\'s not uncommon to see a requirement to support various blockchains, it still requires a significant amount of time to learn how to write a smart contract just printing "Hello World" per blockchain. Aloxide provides a pragmatic abstraction for various blockchain softwares includingCAN, EOS, ICON, and so on so that you can focus on business logic on smart contracts without ties to specific blockchain natures. Also based on the abstraction Aloxide offers useful tool-kits for dApp development such asAPI gateway and SDK.',
      'assets/images/aloxide.png',
      null,
      tags: ['sdk', 'java', 'swift'],
      githubLink: 'https://github.com/lecle/aloxide-sdk-java'),
  Project(
      'App modular builder',
      'Build modular app with ease',
      'assets/images/modular_builder.png',
      'https://lecle-app-modular-builder.web.app/',
      tags: ['web', 'flutter canvaskit only'],
  ),
  Project(
      'RB Land',
      'Karaoke and record your moment on RB Land',
      'assets/images/rbland.png',
      'https://apkpure.com/vn/rbland/vn.com.rbland.app',
      tags: ['mobile', 'flutter only'],
  )
];
