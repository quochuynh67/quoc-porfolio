import 'package:flutter/material.dart';

class LeftButton extends StatelessWidget {
  static bool isHolding = false;
  final Function? function;

  const LeftButton({Key? key, this.function}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        isHolding = true;
        function?.call();
      },
      onTapUp: (_) {
        isHolding = false;
      },
      onPanUpdate: (_) {
        isHolding = false;
      },
      child: Image.asset(
        'assets/images/projects/bounce/control_left.png',
        height: 70,
        width: 70,
      ),
    );
  }
}

class RightButton extends StatelessWidget {
  static bool isHolding = false;
  final Function? function;

  const RightButton({Key? key, this.function}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        isHolding = true;
        function?.call();
      },
      onPanUpdate: (_) {
        isHolding = false;
      },
      onTapUp: (_) {
        isHolding = false;
      },
      child: Image.asset(
        'assets/images/projects/bounce/control_right.png',
        height: 70,
        width: 70,
      ),
    );
  }
}

class JumpButton extends StatelessWidget {
  final Function? function;

  const JumpButton({Key? key, this.function}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => function?.call(),
      child: Image.asset(
        'assets/images/projects/bounce/control_up.png',
        height: 70,
      ),
    );
  }
}
