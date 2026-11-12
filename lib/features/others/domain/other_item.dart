class OtherModel {
  final String name;
  final String type;
  final String date;
  final List<String> skills;
  final String? link;
  final int? pageIndex;
  final Map<String, String>? queryParameters;

  OtherModel({
    required this.name,
    required this.type,
    required this.date,
    required this.skills,
    this.link,
    this.pageIndex,
    this.queryParameters,
  });
}

List<OtherModel> otherList = [
  OtherModel(
    name: 'Đa ngôn ngữ cho Flutter',
    type: 'Flutter Tool',
    date: '25 May 2026',
    skills: [
      'missing keys',
      'extra keys',
      'intl',
      'arb',
      'localization manager'
    ],
    pageIndex: 8,
  ),
  OtherModel(
    name: 'Media Tools',
    type: 'Flutter tools',
    date: 'Portfolio app',
    skills: ['FFmpeg', 'Video processing', 'Vlog maker', 'Quote maker'],
    pageIndex: 3,
  ),
  OtherModel(
    name: 'Jx2 Web 2D & 3D',
    type: 'Legendary MMORPG web experience',
    date: 'Web game',
    skills: ['Võ Lâm 2', '2D & 3D', 'Web game'],
    pageIndex: 4,
  ),
  OtherModel(
    name: 'Retro Game',
    type: 'Childhood arcade',
    date: 'Portfolio app',
    skills: ['Retro', 'Arcade', 'Web game'],
    pageIndex: 7,
  ),
];
