import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math.dart';

import 'force_calculator.dart';
import 'joint.dart';
import 'truss.dart';
import 'truss_painter.dart';

typedef void JointCallback(int jointId);

class ConstructArea extends StatefulWidget {
  _ConstructAreaState createState() => _ConstructAreaState();

  ConstructArea(this.snapMode, this.ortho, this.showAngles, this.addTruss, this.selectedJoint, this.jointSelected,
      this.trussAdded, this.onUpdate, this.constraints);

  final SnapMode snapMode;
  final bool ortho;
  final bool showAngles;
  final bool addTruss;
  final int selectedJoint;
  final JointCallback jointSelected;
  final VoidCallback trussAdded;
  final VoidCallback onUpdate;
  final BoxConstraints constraints;
}

class _ConstructAreaState extends State<ConstructArea> with SingleTickerProviderStateMixin {
  AnimationController _controller;
  Offset _lastGridPos;
  List<Truss> trusses;
  double scale = 12;
  Offset origin = Offset(30, 180);
  Offset curVelocity = Offset.zero;
  int panHitId;
  int firstJointId;

  @override
  void initState() {
    super.initState();
    scale = (widget.constraints.maxWidth / 35) + 5;
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 6000), upperBound: 1);
    _controller.addListener(() {
      if (_controller.value > 0)
        setState(() {
          var maths = min(pow(_controller.value + .7, -3), 0.6);
          origin = origin.translate(maths * curVelocity.dx * 0.014, maths * curVelocity.dy * 0.014);
        });
    });
    Truss.auto(0, 0, 2, 3)..chainStart(5, 3);
  }

  Widget build(BuildContext context) {
    scale = (widget.constraints.maxWidth / 35) + 5;
    return Listener(
      onPointerSignal: (evt) {
        if (evt is PointerScrollEvent) {
          setState(() {
            origin -= evt.scrollDelta / 1.5;
          });
        }
      },
      child: GestureDetector(
        dragStartBehavior: DragStartBehavior.down,
        child: CustomPaint(
            painter: TrussPainter(
                showAngles: widget.showAngles,
                scale: scale,
                origin: origin,
                selectedJoint: widget.selectedJoint,
                showAddTruss: widget.addTruss ? (firstJointId == null ? 1 : 2) : 0)),
        onTapUp: (tap) {
          var pos = findGridPos(context, tap.globalPosition);
          var hit = Joint.hitTestAllOffset(pos, 0.5);
          if (widget.addTruss && firstJointId == null) {
            setState(() {
              if (hit != null) {
                firstJointId = hit.id;
              } else {
                if (widget.snapMode == SnapMode.GRID) pos = snapToGrid(pos);
                firstJointId = Joint(pos.dx, pos.dy, JointType.STANDARD).id;
              }
            });
          } else if (widget.addTruss) {
            if (widget.snapMode == SnapMode.NEAREST || widget.snapMode == SnapMode.PERPENDICULAR) {
              var abs = (num i) => i >= 0 ? i : -i;
              // Find the closest truss to your tap point
              var l = Truss.all.values.map((t) {
                var ab = Offset(t.startX - t.endX, t.startY - t.endY);
                var ac = Offset(t.startX - pos.dx, t.startY - pos.dy);
                var bc = Offset(t.endX - pos.dx, t.endY - pos.dy);

                return MapEntry(abs(ab.distance - (ac.distance + bc.distance)), t);
              }).toList()
                ..sort((e1, e2) => e1.key.compareTo(e2.key));
              if (l.first.key < 0.5) {
                // The closest truss is close enough to register as a tap
                if (widget.snapMode == SnapMode.NEAREST) {
                  var t = l.first.value;
                  if (widget.ortho) {
                    // If Ortho and Nearest are enabled, find the point on the truss that makes the new truss vertical
                    // or horizontal
                    var ij = Joint.all[firstJointId];
                    // Determine whether to use vertical or horizontal snap
                    var tSlope = atan((ij.y - pos.dy) / (ij.x - pos.dx));
                    var vertical = abs(tSlope) >= (pi / 4) && (tSlope < (3 * pi) / 2);
                    if (vertical) {
                      var slope = (t.endY - t.startY) / (t.endX - t.startX);
                      var y3 = (slope) * ij.x - (t.startX * slope - t.startY);
                      Truss.embed(Truss.joinStart(Joint.all[firstJointId], ij.x, y3).endJoint);
                    } else {
                      var slope = (t.endY - t.startY) / (t.endX - t.startX);
                      var x3 = (ij.y + (t.startX * slope - t.startY)) * (1 / slope);
                      Truss.embed(Truss.joinStart(Joint.all[firstJointId], x3, ij.y).endJoint);
                    }
                  } else {
                    // Nearest snap, find the nearest point on the truss by creating a perpendicular line to it
                    var aToP = Vector2(pos.dx - t.startX, pos.dy - t.startY);
                    var aToB = Vector2(t.endX - t.startX, t.endY - t.startY);
                    var dist = aToP.dot(aToB) / aToB.length2;
                    if (dist < 0)
                      Truss(firstJointId, t.startId);
                    else if (dist > 1)
                      Truss(firstJointId, t.endId);
                    else {
                      Truss.embed(
                          Truss.joinStart(Joint.all[firstJointId], t.startX + aToB.x * dist, t.startY + aToB.y * dist)
                              .endJoint);
                    }
                  }
                  firstJointId = null;
                  widget.trussAdded();
                } else {
                  // Perpendicular snap, find the point on the Truss that makes the new Truss perpendicular to it
                  var t = l.first.value;
                  var j1 = Joint.all[firstJointId];
                  var k = ((t.endY - t.startY) * (j1.x - t.startX) - (t.endX - t.startX) * (j1.y - t.startY)) /
                      (pow(t.endY - t.startY, 2) + pow(t.endX - t.startX, 2));
                  var x4 = j1.x - k * (t.endY - t.startY);
                  var y4 = j1.y + k * (t.endX - t.startX);

                  Truss.embed(Truss.joinStart(Joint.all[firstJointId], x4, y4).endJoint);
                  firstJointId = null;
                  widget.trussAdded();
                }
              } else {
                // No truss is close enough to be hit, follow standard path
                Truss.joinStart(Joint.all[firstJointId], pos.dx, pos.dy);
                firstJointId = null;
                widget.trussAdded();
              }
            } else if (widget.ortho) {
              var abs = (num i) => i >= 0 ? i : -i;
              var ij = Joint.all[firstJointId];
              // Determine whether to use vertical or horizontal snap
              var tSlope = atan((ij.y - pos.dy) / (ij.x - pos.dx));
              var vertical = abs(tSlope) >= (pi / 4) && (tSlope < (3 * pi) / 2);
              var os = vertical ? Offset(ij.x, pos.dy) : Offset(pos.dx, ij.y);
              if (widget.snapMode == SnapMode.GRID) os = snapToGrid(os);
              Truss.joinStart(ij, os.dx, os.dy);
              firstJointId = null;
              widget.trussAdded();
            } else if (hit != null) {
              // Snap to joint
              Truss(firstJointId, hit.id);
              firstJointId = null;
              widget.trussAdded();
            } else {
              // Grid snap or standard
              if (widget.snapMode == SnapMode.GRID) pos = snapToGrid(pos);
              Truss.joinStart(Joint.all[firstJointId], pos.dx, pos.dy);
              firstJointId = null;
              widget.trussAdded();
            }
          } else {
            // If we're not adding a truss, callback with a hit or null (to clear selected)
            widget.jointSelected(hit?.id == widget.selectedJoint ? null : hit?.id);
          }
        },
        onPanStart: (event) {
          var gridPos = findGridPos(context, event.globalPosition);
          _lastGridPos = gridPos;
          panHitId = Joint.hitTestAllOffset(gridPos, 0.5)?.id;
        },
        onPanUpdate: (event) {
          setState(() {
            if (panHitId != null) {
              var gridPos = findGridPos(context, event.globalPosition);
              _lastGridPos = gridPos;
              Joint.all[panHitId]
                ..x = gridPos.dx
                ..y = gridPos.dy;
              ForceCalculator.calcForces(true);
            } else
              origin = origin.translate(event.delta.dx, event.delta.dy);
          });
        },
        onPanEnd: (event) {
          if (panHitId == null) {
            curVelocity = event.velocity.pixelsPerSecond;
            _controller.duration = Duration(milliseconds: event.velocity.pixelsPerSecond.distance.floor());
            _controller.reset();
            _controller.fling(velocity: 0.3).then((_) {
              _controller.stop();
              _controller.reset();
            });
          } else {
            if (widget.snapMode == SnapMode.GRID) {
              Joint.all[panHitId]
                ..x = snapToGrid(_lastGridPos).dx
                ..y = snapToGrid(_lastGridPos).dy;
            }
            ForceCalculator.calcForces();
            widget.onUpdate();
          }
        },
      ),
    );
  }

  Offset findGridPos(BuildContext context, Offset globalPosition) {
    var cvs = (context.findRenderObject() as RenderBox);
    var canvasPos = -cvs.localToGlobal(Offset.zero).translate(-globalPosition.dx, -globalPosition.dy);
    var exactPos = canvasPos.translate(-origin.dx, -origin.dy);
    return exactPos.scale(1 / (cvs.size.width ~/ scale), -1 / (cvs.size.width ~/ scale));
  }

  Offset snapToGrid(Offset gridPos) {
    return Offset(gridPos.dx.round().toDouble(), gridPos.dy.round().toDouble());
  }
}

enum SnapMode { NONE, GRID, NEAREST, PERPENDICULAR }
