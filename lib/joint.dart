import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'truss.dart';

class Joint {
  static int lastId = 0;
  static Map<int, Joint> all = Map();
  static int globalCalcStep = 0;

  static Joint hitTestAll(double dx, double dy, double radius) =>
      all.values.toList().reversed.firstWhere((j) => j.hitTest(dx, dy, 0.5), orElse: () => null);

  static Joint hitTestAllOffset(Offset d, double radius) => hitTestAll(d.dx, d.dy, radius);

  static Iterable<Joint> hitTestMultiple(double dx, double dy, double radius) =>
      all.values.where((j) => j.hitTest(dx, dy, 0.5));

  static Iterable<Joint> hitTestMultipleOffset(Offset d, double radius) => hitTestMultiple(d.dx, d.dy, radius);

  factory Joint(double x, double y, JointType type, [int id]) {
    var pin = Joint._(x, y, type, id ?? lastId++);
    all[pin.id] = pin;
    return pin;
  }

  Joint._(this.x, this.y, this.type, this.id);

  double x;
  double y;
  int id;
  int tempId;
  int tempIdH;
  JointType type;
  AxisDirection exDir;
  double exAmount;
  int calcStep = 0;
  int rCalcStep = 0;
  int fCalcStep = 0;
  int fCalcStep2 = 0;
  double moment;
  double reactionForce = 0;
  double reactionAngle = 0;
  int sumaround = 0;
  int codepath = 0;
  double fx;
  double fy;
  int trussCacheKey = -1;
  List<Truss> cachedConnectedTruss;

  Iterable<Truss> get _connectedFast => Truss.all.values.where((t) => t.startId == id || t.endId == id);

  List<Truss> get connectedTrusses {
    if (Truss.maxId == trussCacheKey) {
      return cachedConnectedTruss;
    }
    trussCacheKey = Truss.maxId;
    return cachedConnectedTruss = _connectedFast.toList();
  }

  double get forceAngle => exDir == AxisDirection.right
      ? 0
      : exDir == AxisDirection.up ? math.pi / 2.0 : exDir == AxisDirection.left ? math.pi : math.pi * (3.0 / 2.0);

  static num abs(num x) => x < 0 ? -x : x;

  /// Calculate the moment that this joint exerts on Joint [j],
  /// accounting for this joint's external and reaction forces.
  double calcMomentOn(Joint j) {
    // Early bail if there is no external or reaction force
    if (exAmount == null && reactionForce <= 0.0001) return 0;

    // Calculate the angle from this joint to the other joint
    var angle = math.atan2((y - j.y), (x - j.x));

    // Force perpendicular component
    var p;
    if (exDir == AxisDirection.right || exDir == AxisDirection.left) {
      // If horizontal, force is the sine of the angle * force amount
      p = (exAmount ?? 0) * math.sin(angle) + (reactionForce * math.sin(reactionAngle));
    } else {
      // If vertical, force is the sine of the angle * (force amount - 90 degrees)
      p = (exAmount ?? 0) * math.sin(angle - math.pi / 2) + (reactionForce * math.sin(reactionAngle - math.pi / 2));
    }
    // Calculate sign based on Kiera's chart
    var sign;
    if (axisDirectionToAxis(exDir ?? AxisDirection.down) == Axis.vertical)
      sign = x - j.x < 0 != (exDir == AxisDirection.down) ? -1 : 1;
    else
      sign = y - j.y < 0 != (exDir == AxisDirection.left) ? 1 : -1;

    return abs(p) * Offset(x - j.x, y - j.y).distance * sign;
  }

  bool hitTest(double dx, double dy, double radius) =>
      x - radius < dx && x + radius > dx && y - radius < dy && y + radius > dy;

  void delete() {
    connectedTrusses.forEach((truss) => truss.delete());
    all.remove(id);
  }

  @override
  String toString() {
    return 'Pin{id: $id, type: $type}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Joint && runtimeType == other.runtimeType && id == other.id && type == other.type;

  @override
  int get hashCode => id.hashCode;
}

enum JointType { PINNED, STANDARD, ROLLER_V, ROLLER_H }
