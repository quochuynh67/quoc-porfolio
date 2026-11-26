import 'package:flutter/material.dart';

class AnimatedImageContainer extends StatefulWidget {
  const AnimatedImageContainer({super.key, this.width = 520});

  final double width;

  @override
  State<AnimatedImageContainer> createState() => AnimatedImageContainerState();
}

class AnimatedImageContainerState extends State<AnimatedImageContainer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _lampOn = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      child: AspectRatio(
        aspectRatio: 1.5,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final glow = 0.16 + (_controller.value * 0.1);
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xffff2d8d).withValues(alpha: glow),
                    offset: const Offset(-8, 8),
                    blurRadius: 36,
                  ),
                  BoxShadow(
                    color: const Color(0xff23a6ff).withValues(alpha: glow),
                    offset: const Offset(8, -4),
                    blurRadius: 38,
                  ),
                ],
              ),
              child: child,
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final height = constraints.maxHeight;
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      'assets/images/developer_workspace_mekong_lamp_v3.png',
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.high,
                    ),
                    Positioned(
                      left: width * 0.199,
                      top: height * 0.198,
                      width: width * 0.607,
                      height: height * 0.424,
                      child: _InteractiveMonitor(
                        lampOn: _lampOn,
                      ),
                    ),
                    Positioned(
                      left: width * .055,
                      top: height * .45,
                      width: width * .145,
                      height: height * .32,
                      child: _DeskHotspot(
                        onTap: () => setState(() => _lampOn = !_lampOn),
                      ),
                    ),
                    IgnorePointer(
                      child: AnimatedOpacity(
                        opacity: _lampOn ? 0 : .78,
                        duration: const Duration(milliseconds: 350),
                        child: Align(
                          alignment: const Alignment(-.84, .28),
                          child: Container(
                            width: width * .28,
                            height: height * .46,
                            decoration: const BoxDecoration(
                              gradient: RadialGradient(
                                colors: [Color(0xcc01040c), Color(0x0001040c)],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    IgnorePointer(
                      child: AnimatedOpacity(
                        opacity: _lampOn ? 1 : 0,
                        duration: const Duration(milliseconds: 350),
                        child: Align(
                          alignment: const Alignment(-.88, .42),
                          child: Container(
                            width: width * .22,
                            height: height * .32,
                            decoration: const BoxDecoration(
                              gradient: RadialGradient(
                                colors: [Color(0x55ff75bc), Color(0x00ff75bc)],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _DeskHotspot extends StatelessWidget {
  const _DeskHotspot({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
      ),
    );
  }
}

class _InteractiveMonitor extends StatefulWidget {
  const _InteractiveMonitor({
    required this.lampOn,
  });

  final bool lampOn;

  @override
  State<_InteractiveMonitor> createState() => _InteractiveMonitorState();
}

class _InteractiveMonitorState extends State<_InteractiveMonitor> {
  int _selectedPage = 0;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Interactive Quoc portfolio computer screen',
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xff020817), Color(0xff071126)],
            ),
            boxShadow: _hovered
                ? const [
                    BoxShadow(
                      color: Color(0xaa2d9cff),
                      blurRadius: 18,
                      spreadRadius: 1,
                    ),
                    BoxShadow(
                      color: Color(0x88ff2d8d),
                      blurRadius: 24,
                    ),
                  ]
                : const [],
          ),
          child: _MiniPortfolioHome(
            selectedPage: _selectedPage,
            lampOn: widget.lampOn,
            onPageSelected: (page) => setState(() => _selectedPage = page),
          ),
        ),
      ),
    );
  }
}

class _MiniPortfolioHome extends StatelessWidget {
  const _MiniPortfolioHome({
    required this.selectedPage,
    required this.lampOn,
    required this.onPageSelected,
  });

  final int selectedPage;
  final bool lampOn;
  final ValueChanged<int> onPageSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tiny = constraints.maxWidth < 250;
        return Stack(
          children: [
            Positioned(
              right: -24,
              bottom: -34,
              child: Container(
                width: constraints.maxWidth * 0.46,
                height: constraints.maxWidth * 0.46,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Color(0x663b82f6), Color(0x00244bff)],
                  ),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: tiny ? 13 : 17,
                      height: tiny ? 13 : 17,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        gradient: const LinearGradient(
                          colors: [Color(0xffff2d8d), Color(0xff269dff)],
                        ),
                      ),
                      child: const Icon(Icons.code_rounded,
                          color: Colors.white, size: 10),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'QUỐC',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: tiny ? 7 : 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .4,
                      ),
                    ),
                    const Spacer(),
                    ...['Home', 'Projects', 'Others'].indexed.map(
                          (entry) => Padding(
                            padding: const EdgeInsets.only(left: 3),
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => onPageSelected(entry.$1),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 4,
                                  ),
                                  child: Text(
                                    entry.$2,
                                    style: TextStyle(
                                      color: selectedPage == entry.$1
                                          ? const Color(0xff62c6ff)
                                          : Colors.white60,
                                      fontSize: tiny ? 5 : 6.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 3),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(99),
                        gradient: const LinearGradient(
                          colors: [Color(0xffdd1d72), Color(0xff245bc6)],
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 3,
                            height: 3,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: lampOn
                                  ? const Color(0xff8dffbd)
                                  : Colors.white38,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Text('Zalo',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: tiny ? 4.5 : 5.5,
                                fontWeight: FontWeight.w700,
                              )),
                        ],
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(.04, 0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                    child: switch (selectedPage) {
                      1 => _MiniProjects(
                          key: const ValueKey('projects'), tiny: tiny),
                      2 => _MiniOthers(
                          key: const ValueKey('others'),
                          tiny: tiny,
                        ),
                      _ => _MiniHome(
                          key: const ValueKey('home'),
                          tiny: tiny,
                          onExplore: () => onPageSelected(1),
                        ),
                    },
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _MiniHome extends StatelessWidget {
  const _MiniHome({super.key, required this.tiny, required this.onExplore});

  final bool tiny;
  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Spacer(),
        Text(
          'My Personal Portfolio',
          style: TextStyle(
            color: Colors.white,
            fontSize: tiny ? 8 : 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Mobile Developer',
          style: TextStyle(
            height: 1,
            foreground: Paint()
              ..shader = const LinearGradient(
                colors: [Color(0xffff2d8d), Color(0xff269dff)],
              ).createShader(const Rect.fromLTWH(0, 0, 120, 20)),
            fontSize: tiny ? 12 : 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          width: tiny ? 62 : 82,
          height: tiny ? 2 : 3,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(99),
            gradient: const LinearGradient(
              colors: [Color(0xffff2d8d), Color(0xff269dff)],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "I'm capable of creating excellent mobile apps,\nfrom concept to deployment.",
          style: TextStyle(color: Colors.white54, fontSize: tiny ? 5 : 6.5),
        ),
        const Spacer(),
        Align(
          alignment: Alignment.bottomLeft,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: onExplore,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: tiny ? 6 : 9,
                  vertical: tiny ? 3 : 4,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(99),
                  gradient: const LinearGradient(
                    colors: [Color(0xffd91b68), Color(0xff245bc6)],
                  ),
                ),
                child: Text(
                  'EXPLORE WORK',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: tiny ? 4.5 : 5.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .5,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniProjects extends StatelessWidget {
  const _MiniProjects({super.key, required this.tiny});

  final bool tiny;

  @override
  Widget build(BuildContext context) {
    const projects = [
      ('67Talk', 'AI Customer Service'),
      ('Media Studio', 'Realtime video tools'),
      ('Quê tôi 67K1', 'Personal hometown app'),
    ];
    return Padding(
      padding: const EdgeInsets.only(top: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SELECTED PROJECTS',
            style: TextStyle(
              color: Colors.white70,
              fontSize: tiny ? 5 : 6.5,
              fontWeight: FontWeight.w800,
              letterSpacing: .8,
            ),
          ),
          const SizedBox(height: 5),
          Expanded(
            child: Row(
              children: projects.indexed.map((entry) {
                return Expanded(
                  child: Container(
                    margin: EdgeInsets.only(right: entry.$1 == 2 ? 0 : 4),
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .06),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          [
                            Icons.forum_rounded,
                            Icons.movie_filter_rounded,
                            Icons.home_rounded
                          ][entry.$1],
                          color: const Color(0xff62c6ff),
                          size: tiny ? 9 : 12,
                        ),
                        const Spacer(),
                        Text(
                          entry.$2.$1,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: tiny ? 4.5 : 6,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          entry.$2.$2,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: tiny ? 3.5 : 4.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniOthers extends StatelessWidget {
  const _MiniOthers({
    super.key,
    required this.tiny,
  });

  final bool tiny;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: const Color(0xff050b13),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0x4445d89b)),
        ),
        child: DefaultTextStyle(
          style: TextStyle(
            color: const Color(0xff75e6b2),
            fontFamily: 'monospace',
            fontSize: tiny ? 4.5 : 6,
            height: 1.55,
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(r'$ whoami'),
              Text('Quốc — Flutter & AI builder',
                  style: TextStyle(color: Colors.white70)),
              Text(r'$ ls playground/'),
              Text('Journal  Media Tools  Jx2 Web',
                  style: TextStyle(color: Color(0xff62c6ff))),
              Spacer(),
              Text('● system online',
                  style: TextStyle(color: Color(0xffff4f9a))),
            ],
          ),
        ),
      ),
    );
  }
}
