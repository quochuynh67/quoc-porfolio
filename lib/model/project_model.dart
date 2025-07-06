class Project {
  final String name;
  final String description;
  final String image;
  final String? link;
  final String? githubLink;

  Project(this.name, this.description, this.image, this.link, {this.githubLink});
}

List<Project> projectList = [
  Project(
    'CRM Website',
    'A CRM (Customer Relationship Management) website is a web-based platform designed to help businesses manage their interactions with customers, streamline processes, and improve overall customer relationships. It typically includes features such as contact management, sales tracking, lead generation, and customer support.',
    'assets/images/crm.png',
    null,
  ),
  Project(
    'ViiV',
    'Connecting the world of travel through vlogs\nViiV, an all-in-one travel app just for you',
    'assets/images/viiv.png',
    'https://viiv.app',
  ),
  Project(
    'HanyBany',
    'HanyBany is a mind care chatbot that helps modern people increase their happiness through conversation. The chatbot conversation is designed based on interventions developed based on positive psychology.',
    'assets/images/chatbot.png',
    'https://apkpure.com/vn/해니-기업전용/com.bloomcompany.hanny',
  ),
  Project(
    'AloxideSDK',
    'description: While there are a lot of blockchain softwaresavailable and it\'s not uncommon to see a requirement to support variousblockchains, it still requires a significant amount of time to learn how towrite a smart contract just printing "Hello World" per blockchain. Aloxideprovides a pragmatic abstraction for various blockchain softwares includingCAN, EOS, ICON, and so on so that you can focus on business logic onsmart contracts without ties to specific blockchain natures. Also based onthe abstraction Aloxide offers useful tool-kits for dApp development such asAPI gateway and SDK.',
    'assets/images/aloxide.png',
    null,
    githubLink: 'https://github.com/lecle/aloxide-sdk-java'
  ),
];
