import 'package:flutter/material.dart';

import '../../global/model/actor.dart';

abstract class Object extends StatelessWidget {
  final Actor actor;

  const Object({ Key? key, required this.actor}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Image.asset(actor.url);
  }
}

class BallObject extends Object {
  BallObject({required Ball ball,  Key? key}) : super(actor: ball, key: key);
}

class WallObject extends Object {
  WallObject({required Wall wall,  Key? key}) : super(actor: wall, key: key);
}

class Wall2x2Object extends Object {
  Wall2x2Object({required Wall2x2 wall2x2,  Key? key}) : super(actor: wall2x2, key: key);
}

class RingObject extends Object {
  RingObject({required Actor ring,  Key? key}) : super(actor: ring, key: key);
}

class ThornObject extends Object {
  ThornObject({required Thorn thorn,  Key? key}) : super(actor: thorn, key: key);
}

class Finishbject extends Object {
  Finishbject({required Finish finish,  Key? key}) : super(actor: finish, key: key);
}
