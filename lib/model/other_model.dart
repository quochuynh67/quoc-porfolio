class OtherModel {
  final String name;
  final String type;
  final String date;
  final List<String> skills;
  final String link;

  OtherModel({
    required this.name,
    required this.type,
    required this.date,
    required this.skills,
    required this.link,
  });
}

List<OtherModel> otherList = [
  OtherModel(
    name: 'FlutterZaloMiniApp - Vlog',
    type: 'FlutterWeb',
    date: '6 Jul 2025',
    skills: ['Flutter', 'Dart', "canvaskit", 'Zalo Mini App'],
    link: 'https://zalo-mini-app-45606.web.app/',
  ),
  OtherModel(
    name: 'FlutterZaloMiniApp - MediaTool',
    type: 'FlutterWeb',
    date: '6 Jul 2025',
    skills: ['Flutter', 'Dart', "canvaskit", "Zalo Mini App", "ffmpeg", "video processing", "vlog maker", 'quote maker'],
    link: 'https://zalo-mini-app-mediatool.web.app/',
  ),
];
