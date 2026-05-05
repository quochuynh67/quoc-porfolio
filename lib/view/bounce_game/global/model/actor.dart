import 'package:flutter/cupertino.dart';

abstract class Actor {
  double dx;
  double? impactDx;
  double dy;
  String url;
  bool? isCollected;
  DismissDirection? direction;

  Actor(
      {required this.dx,
      required this.dy,
      required this.url,
      this.impactDx,
      this.direction,
      this.isCollected});

  @override
  String toString() => '${this.runtimeType}(dx: $dx, dy: $dy, url: $url)';

  void reset([double toDx, double toDy]);
}

class Ball extends Actor {
  Ball(
      {double dx = -1.0, double dy = 1.0, String url = 'assets/images/projects/bounce/ball_small.png'})
      : super(dx: dx, dy: dy, url: url);

  @override
  void reset([double? toDx, double? toDy]) {
    this.dx = -1.0;
    this.dy = 1.0;
    this.url = 'assets/images/projects/bounce/ball_small.png';
  }
}

class Ring extends Actor {
  Ring(
      {double dx = 0.25,
      double impactDx = 0.25 - 0.05,
      double dy = 0.9,
      String url = 'assets/images/projects/bounce/ring.png',
      bool isCollected = false})
      : super(
            dx: dx,
            dy: dy,
            url: url,
            isCollected: isCollected,
            impactDx: impactDx);

  @override
  void reset([double? toDx, double? toDy]) {
    this.dx = toDx ?? 0.25;
    this.dy = toDy ?? 0.9;
    this.url = 'assets/images/projects/bounce/ring.png';
    this.isCollected = false;
  }
}

class Wall extends Actor {
  Wall(
      {double dx = 1.0,
      final double dy = 1.0,
      final String url = 'assets/images/projects/bounce/wall.png'})
      : super(dx: dx, dy: dy, url: url);

  @override
  void reset([double? toDx, double? toDy]) {
    this.dx = 1.0;
  }
}

class Wall2x2 extends Actor {
  Wall2x2(
      {double dx = 0.975,
      final double dy = 1.0,
      final String url = 'assets/images/projects/bounce/wall_2x2.png'})
      : super(dx: dx, dy: dy, url: url);

  @override
  void reset([double? toDx, double? toDy]) {
    this.dx = 0.975;
  }
}

class Thorn extends Actor {
  Thorn(
      {double dx = 2.12,
      final double dy = 1.0,
      final String url = 'assets/images/projects/bounce/thorn.png',
      DismissDirection? direction})
      : super(dx: dx, dy: dy, url: url, direction: direction);

  @override
  void reset([double? toDx, double? toDy]) {
    this.dx = toDx ?? 2.12;
  }
}

class Finish extends Actor {
  Finish({
    double dx = 7.0,
    final double dy = 1.0,
    final String url = 'assets/images/projects/bounce/finish.png',
  }) : super(dx: dx, dy: dy, url: url);

  @override
  void reset([double? toDx, double? toDy]) {
    this.dx = toDx??7.0;
  }
}
