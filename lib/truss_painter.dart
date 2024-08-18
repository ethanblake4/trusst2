import 'dart:math' as math;

import 'package:extended_math/extended_math.dart';
import 'package:flutter/material.dart';
import 'package:trusst/force_calculator.dart';

import 'joint.dart';
import 'text_layout_cache.dart';
import 'truss.dart';

class TrussPainter extends CustomPainter {
  TrussPainter(
      {required this.origin,
      required this.scale,
      this.selectedJoint,
      required this.showAddTruss,
      required this.showAngles,
      required this.showOrtho,
      this.firstAddJoint});

  static const double eqh = 0.86602540378;

  static TextLayoutCache textCache = TextLayoutCache(TextDirection.ltr, 25);

  static Paint background = Paint()..color = const Color(0xFFF4F4F4);

  //static Paint background = Paint()..color = const Color(0xFF4A4A4A);
  static Paint gridPaint = Paint()
    ..color = const Color(0xFFCCCCCC)
    ..strokeWidth = 1;
  static Paint axesPaint = Paint()
    ..color = const Color(0xFFCCCCCC)
    ..strokeWidth = 3;
  Paint trussPaint = Paint()
    ..color = Colors.deepOrange[400]!
    ..strokeWidth = 6;
  static Paint anglesPaint = Paint()
    ..color = Colors.orangeAccent
    ..strokeWidth = 6;
  static Paint momentPaint = Paint()
    ..color = Colors.blueAccent
    ..strokeWidth = 6;
  Paint ppfPain = Paint()
    ..color = Colors.purpleAccent[700]!
    ..strokeWidth = 2;
  Paint compressPaint = Paint()..color = Colors.deepOrange[600]!;
  Paint tensionPaint = Paint()..color = Colors.deepOrange[300]!;
  static Paint selPaint = Paint()
    ..color = Colors.lightGreen
    ..strokeWidth = 6;
  static Paint selIPaint = Paint()
    ..color = Colors.lightGreenAccent
    ..strokeWidth = 6;
  static Paint circleIPaint = Paint()..color = Colors.orange[100]!;
  final Paint exPaint = Paint()
    ..color = Colors.black
    ..strokeWidth = 2;
  static Paint dashPaint = Paint()
    ..color = Colors.orangeAccent
    ..strokeWidth = 2;

  final Offset origin;
  final double scale;
  final int? selectedJoint;
  final int showAddTruss;
  final bool showAngles;
  final bool showOrtho;
  final Joint? firstAddJoint;

  static TextPainter _addPaint1 = TextPainter(
      text: TextSpan(
          text: 'Select first joint position',
          style: TextStyle(color: Colors.white)),
      textAlign: TextAlign.left)
    ..textDirection = TextDirection.ltr
    ..layout();
  static TextPainter _addPaint2 = TextPainter(
      text: TextSpan(
          text: 'Select second joint position',
          style: TextStyle(color: Colors.white)),
      textAlign: TextAlign.left)
    ..textDirection = TextDirection.ltr
    ..layout();

  @override
  bool shouldRepaint(TrussPainter old) {
    return true;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final t = DateTime.now().millisecondsSinceEpoch;
    var sc = (size.width ~/ scale);
    print('scale: $scale, sc: $sc');

    // Background
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), background);

    // X-Axis
    canvas.drawLine(
        Offset(0, origin.dy), Offset(size.width, origin.dy), axesPaint);
    // Y-Axis
    canvas.drawLine(
        Offset(origin.dx, 0), Offset(origin.dx, size.height), axesPaint);

    // X-Grid
    for (var i = origin.dx.toInt() % sc; i < size.width; i += sc) {
      canvas.drawLine(Offset(i.toDouble(), 0),
          Offset(i.toDouble(), size.height), gridPaint);
    }
    // Y-Grid
    for (var i = origin.dy.toInt() % sc; i < size.height; i += sc) {
      canvas.drawLine(
          Offset(0, i.toDouble()), Offset(size.width, i.toDouble()), gridPaint);
    }

    if (showOrtho && showAddTruss == 2 && firstAddJoint != null) {
      // hz line
      var off = 0.0;
      while (off < size.width) {
        canvas.drawLine(
            origin.translate(off - origin.dx, -firstAddJoint!.y * sc - .5),
            origin.translate(off + 6 - origin.dx, -firstAddJoint!.y * sc - .5),
            dashPaint);
        off += 9;
      }
      off = 0.0;
      while (off < size.height) {
        canvas.drawLine(
            origin.translate(firstAddJoint!.x * sc - 1, off - origin.dy),
            origin.translate(firstAddJoint!.x * sc - 1, off + 6 - origin.dy),
            dashPaint);
        off += 9;
      }
    }

    // Connections
    Truss.all.values.forEach((Truss truss) {
      canvas.drawLine(origin.translate(truss.startX * sc, -truss.startY * sc),
          origin.translate(truss.endX * sc, -truss.endY * sc), trussPaint);
      if (truss.force != null && ForceCalculator.abs(truss.force!) > 0.001) {
        final ftext = truss.force! < 0
            ? '\u2192${(-truss.force!).toStringAsFixed(1)}\u2190'
            : '\u2190${truss.force!.toStringAsFixed(1)}\u2192';
        var tp = textCache.getOrPerformLayout(TextSpan(
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 11.0),
            text: ftext));

        canvas.save();
        canvas.translate(origin.dx + (truss.startX + truss.endX) * sc / 2,
            origin.dy - (truss.startY + truss.endY) * sc / 2);
        final tAngle = (truss.angle > math.pi / 2 || truss.angle < -math.pi / 2)
            ? (truss.angle < math.pi
                ? -math.pi + truss.angle
                : math.pi + truss.angle)
            : truss.angle;
        canvas.rotate(-tAngle);
        canvas.translate(-tp.width / 2, -tp.height / 2);
        canvas.drawRRect(
            RRect.fromLTRBR(
                -2, -1, tp.width + 2, tp.height + 2, Radius.circular(2)),
            truss.force! < 0 ? compressPaint : tensionPaint);

        tp.paint(canvas, Offset.zero);
        canvas.restore();
      }
    });

    double selectedX, selectedY;

    Joint.all.values.forEach((j) {
      var pt = selectedJoint == j.id ? selPaint : trussPaint;
      var ipt = selectedJoint == j.id ? selIPaint : circleIPaint;

      if (selectedJoint == j.id) {
        selectedX = j.x;
        selectedY = j.y;
      }

      final jOffset = origin.translate(j.x * sc, -j.y * sc);
      switch (j.type) {
        case JointType.STANDARD:
          //canvas.drawRect(Rect.fromCircle(center: origin.translate(j.x * sc, -j.y * sc), radius: 10), pt);
          canvas.drawCircle(jOffset, 10, pt);
          break;
        case JointType.PINNED:
          canvas.drawCircle(jOffset, 10, pt);
          var inner = Path()
            ..moveTo(origin.dx + j.x * sc - 6, origin.dy - j.y * sc + 4)
            ..relativeLineTo(12, 0)
            ..relativeLineTo(-6, -12 * eqh)
            ..close();
          //canvas.drawPath(tri, pt);
          canvas.drawPath(inner, ipt);
          break;
        case JointType.ROLLER_H:
          canvas.drawCircle(jOffset, 10, pt);
          canvas.drawCircle(jOffset + Offset(-4, 5), 1.5, ipt);
          canvas.drawCircle(jOffset + Offset(0, 5), 1.5, ipt);
          canvas.drawCircle(jOffset + Offset(4, 5), 1.5, ipt);
          var inner = Path()
            ..moveTo(origin.dx + j.x * sc - 5, origin.dy - j.y * sc + 1)
            ..relativeLineTo(10, 0)
            ..relativeLineTo(-5, -10 * eqh)
            ..close();
          canvas.drawPath(inner, ipt);
          break;
        case JointType.ROLLER_V:
          canvas.drawCircle(jOffset, 10, pt);
          canvas.drawCircle(jOffset + Offset(5, -4), 1.5, ipt);
          canvas.drawCircle(jOffset + Offset(5, 0), 1.5, ipt);
          canvas.drawCircle(jOffset + Offset(5, 4), 1.5, ipt);
          var inner = Path()
            ..moveTo(origin.dx + j.x * sc + 1, origin.dy - j.y * sc - 5)
            ..relativeLineTo(0, 10)
            ..relativeLineTo(-10 * eqh, -5)
            ..close();
          canvas.drawPath(inner, ipt);
          break;
      }

      if (showAngles) {
        final sortedCTruss = [...j.connectedTrusses];
        sortedCTruss
            .sort((t1, t2) => -t1.angleFrom(j).compareTo(t2.angleFrom(j)));
        if (sortedCTruss.length > 2) {
          sortedCTruss.add(sortedCTruss[0]);
        }
        //var s = (6 ~/ 3);

        //causing problems with not marking certain angles and overmarking some
        var prev = sortedCTruss[0];
        var anglist = anglelist(sortedCTruss);
        var angmax = anglemax(anglist);
        var angsum = anglesum(anglist);
        for (final st in sortedCTruss) {
          if (prev == st) {
            prev = st;
            continue;
          }
          if (sortedCTruss.length > 2) {
            final ang = st.angleBetween(prev);
            //angsum
            if ((ang - angmax < 0.01 &&
                angmax - ang < 0.01 &&
                angsum - 2 * angmax < 0.01 &&
                2 * angmax - angsum < 0.01)) {
              print("well it should skip");
              print(sortedCTruss);
              print(anglist);
              print(ang);
              prev = st;
              print(prev);
              continue;
            } else {
              print("nope");
            }
          }

          final oj1 = prev.startId == j.id ? prev.endJoint : prev.startJoint;
          final oj2 = st.startId == j.id ? st.endJoint : st.startJoint;
          final ang = prev.angleBetween(st);

          var a1 = (math.atan2(oj1.y - j.y, oj1.x - j.x));
          var a2 = (math.atan2(oj2.y - j.y, oj2.x - j.x));
          var theta_2 = (a1 + a2) / 2;
          if ((a1 - a2).abs() > math.pi) {
            theta_2 += 3.14;
          }
//            if (((ang).abs()+0.001)>math.pi) {
//              continue;
//            }
          var xoff = cos(theta_2);
          var yoff = sin(theta_2);
          var l = null;
          if (ang > math.pi / 18) {
            l = max(min(2 * math.tan(ang / 2), 1.5), 0.3);
          } else {
            l = 1.5;
          }
          var tp = textCache.getOrPerformLayout(TextSpan(
              style: TextStyle(
                  color: Colors.orangeAccent[700],
                  fontWeight: FontWeight.normal,
                  fontSize: 11.0),
              text: (180 * (ang) / math.pi).toStringAsFixed(0)));
          tp.paint(
              canvas,
              origin.translate(j.x * sc + xoff * sc / l - tp.width / 2,
                  -j.y * sc - yoff * sc / l - tp.height / 2));
          //}
          prev = st;
        }
      }

      /// this is not a math 'quadrant'
      /// it is this:
      /// |     0     |
      /// |  1     3  |
      /// |     2     |
      final quadrantOccupacity = [0.0, 0.0, 0.0, 0.0];

      for (final t in j.connectedTrusses) {
        var angleF = (t.angle + (t.startJoint.id == j.id ? math.pi : 0));
        if (angleF < 0) angleF = 2 * math.pi + angleF;
        if (angleF > 0 && angleF < math.pi) {
          quadrantOccupacity[0] = math.max(
              quadrantOccupacity[0],
              -1 +
                  math.exp(2 *
                      (math.pi / 2 -
                          ForceCalculator.abs(angleF - math.pi / 2)) /
                      (math.pi)));
        }
        if (angleF > math.pi / 2 && angleF < 3 * math.pi / 2) {
          quadrantOccupacity[1] = math.max(
              quadrantOccupacity[1],
              -1 +
                  math.exp(2 *
                      (math.pi / 2 - ForceCalculator.abs(angleF - math.pi)) /
                      (math.pi)));
        }
        if (angleF > math.pi && angleF < 2 * math.pi) {
          quadrantOccupacity[2] = math.max(
              quadrantOccupacity[2],
              -1 +
                  math.exp(2 *
                      (math.pi / 2 -
                          ForceCalculator.abs(angleF - 3 * math.pi / 2)) /
                      (math.pi)));
        }
        if (angleF > 3 * math.pi / 2) {
          quadrantOccupacity[3] = math.max(
              quadrantOccupacity[3],
              -1 +
                  math.exp(2 *
                      (math.pi / 2 -
                          ForceCalculator.abs(angleF - 2 * math.pi)) /
                      (math.pi)));
        } else if (angleF < math.pi / 2) {
          quadrantOccupacity[3] = math.max(
              quadrantOccupacity[3],
              -1 +
                  math.exp(2 *
                      (math.pi / 2 - ForceCalculator.abs(angleF)) /
                      (math.pi)));
        }
      }

      if (j.type == JointType.STANDARD &&
          j.exDir != null &&
          j.exAmount != null) {
        // draw external forces and force arrows
        var exX = j.exDir == AxisDirection.right
            ? 1
            : j.exDir == AxisDirection.left
                ? -1
                : 0.2;
        var exY = j.exDir == AxisDirection.down
            ? 1
            : j.exDir == AxisDirection.up
                ? -1
                : 0.2;

        if (j.exDir == AxisDirection.left || j.exDir == AxisDirection.right) {
          final tlh = (exX == 1) !=
                  (((quadrantOccupacity[3] - quadrantOccupacity[1])) > 0)
              ? -exX * 42
              : 0;
          canvas.drawRRect(
              RRect.fromRectAndRadius(
                  Rect.fromPoints(
                      origin.translate(
                          j.x * sc + (12 * exX) + tlh, -j.y * sc - (6 * exY)),
                      origin.translate(
                          j.x * sc + (28 * exX) + tlh, -j.y * sc + (6 * exY))),
                  Radius.circular(2)),
              exPaint);
          canvas.drawLine(
              origin.translate(j.x * sc + (28 * exX) + tlh, -j.y * sc),
              origin.translate(j.x * sc + (22 * exX) + tlh, -j.y * sc - 5),
              exPaint);
          canvas.drawLine(
              origin.translate(j.x * sc + (28 * exX) + tlh, -j.y * sc),
              origin.translate(j.x * sc + (22 * exX) + tlh, -j.y * sc + 5),
              exPaint);
          var tp = textCache.getOrPerformLayout(TextSpan(
              style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 11.0),
              text: j.exAmount.toString()));
          tp.paint(
              canvas,
              origin.translate(j.x * sc + (20 * exX) + tlh - tp.width / 2,
                  -j.y * sc + (22 * exY)));
        } else {
          final tlv = (exY == 1) !=
                  (((quadrantOccupacity[2] - quadrantOccupacity[0])) > 0)
              ? -exY * 42
              : 0;
          canvas.drawRRect(
              RRect.fromRectAndRadius(
                  Rect.fromPoints(
                      origin.translate(
                          j.x * sc - (6 * exX), -j.y * sc + (12 * exY) + tlv),
                      origin.translate(
                          j.x * sc + (6 * exX), -j.y * sc + (28 * exY) + tlv)),
                  Radius.circular(2)),
              exPaint);
          canvas.drawLine(
              origin.translate(j.x * sc, -j.y * sc + (28 * exY) + tlv),
              origin.translate(j.x * sc - 5, -j.y * sc + (22 * exY) + tlv),
              exPaint);
          canvas.drawLine(
              origin.translate(j.x * sc, -j.y * sc + (28 * exY) + tlv),
              origin.translate(j.x * sc + 5, -j.y * sc + (22 * exY) + tlv),
              exPaint);
          var tp = textCache.getOrPerformLayout(TextSpan(
              style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 11.0),
              text: j.exAmount.toString()));
          tp.paint(
              canvas,
              origin.translate(
                  j.x * sc + (36 * exX), -j.y * sc + (18 * exY) - 5 + tlv));
        }
      }

      //var exY = j.exDir == AxisDirection.down ? 1 : j.exDir == AxisDirection.up ? -1 : 0.2;
      if (j.fx != null && j.fx!.abs() > 0.00000001) {
        var rxX = j.fx! > 0 ? 1 : -1;
        final tlh = (rxX == 1) !=
                (((quadrantOccupacity[3] - quadrantOccupacity[1])) > 0)
            ? -rxX * 42
            : 0;
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromPoints(
                    origin.translate(
                        j.x * sc + (12 * rxX) + tlh, -j.y * sc - 1.2),
                    origin.translate(
                        j.x * sc + (28 * rxX) + tlh, -j.y * sc + 1.2)),
                Radius.circular(2)),
            ppfPain);
        canvas.drawLine(
            origin.translate(j.x * sc + (28 * rxX) + tlh, -j.y * sc),
            origin.translate(j.x * sc + (22 * rxX) + tlh, -j.y * sc - 5),
            ppfPain);
        canvas.drawLine(
            origin.translate(j.x * sc + (28 * rxX) + tlh, -j.y * sc),
            origin.translate(j.x * sc + (22 * rxX) + tlh, -j.y * sc + 5),
            ppfPain);
        var tp = textCache.getOrPerformLayout(TextSpan(
            style: TextStyle(
                color: Colors.purpleAccent[700],
                fontWeight: FontWeight.bold,
                fontSize: 11.0),
            text: ForceCalculator.abs(j.fx!).toStringAsFixed(1)));
        tp.paint(
            canvas,
            origin.translate(j.x * sc + (20 * rxX) + tlh - tp.width / 2,
                -j.y * sc + (22 * .2)));
      }

      if (j.fy != null && j.fy!.abs() > 0.00000001) {
        var rxY = j.fy! > 0 ? -1 : 1;
        final tlv = (rxY == 1) !=
                (((quadrantOccupacity[2] - quadrantOccupacity[0])) > 0)
            ? -rxY * 42
            : 0;
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromPoints(
                    origin.translate(
                        j.x * sc - 1.2, -j.y * sc + (12 * rxY) + tlv),
                    origin.translate(
                        j.x * sc + 1.2, -j.y * sc + (28 * rxY) + tlv)),
                Radius.circular(2)),
            ppfPain);
        canvas.drawLine(
            origin.translate(j.x * sc, -j.y * sc + (28 * rxY) + tlv),
            origin.translate(j.x * sc - 5, -j.y * sc + (22 * rxY) + tlv),
            ppfPain);
        canvas.drawLine(
            origin.translate(j.x * sc, -j.y * sc + (28 * rxY) + tlv),
            origin.translate(j.x * sc + 5, -j.y * sc + (22 * rxY) + tlv),
            ppfPain);
        var tp = textCache.getOrPerformLayout(TextSpan(
            style: TextStyle(
                color: Colors.purpleAccent[700],
                fontWeight: FontWeight.bold,
                fontSize: 11.0),
            text: ForceCalculator.abs(j.fy!).toStringAsFixed(2)));
        tp.paint(canvas,
            origin.translate(j.x * sc + 7.2, -j.y * sc + (18 * rxY) - 5 + tlv));
      }

      /*var tp = textCache.getOrPerformLayout(TextSpan(
          style: TextStyle(color: Colors.lightBlue, fontWeight: FontWeight.bold, fontSize: 11.0),
          text: j.id.toString()));
      tp.paint(canvas, origin.translate(j.x * sc - 20, -j.y * sc - 12));*/

      if (j.moment != 0 && j.moment != null) {
        var tp = textCache.getOrPerformLayout(TextSpan(
            style: TextStyle(
                color: Colors.blueGrey,
                fontWeight: FontWeight.bold,
                fontSize: 11.0),
            text: j.moment!.toStringAsFixed(2)));
        tp.paint(canvas, origin.translate(j.x * sc + 10, -j.y * sc));
      }

      if (j.reactionForce != 0 && j.reactionForce != null) {
        var tp = textCache.getOrPerformLayout(TextSpan(
            style: TextStyle(
                color: Colors.red, fontWeight: FontWeight.bold, fontSize: 11.0),
            text: j.reactionForce.toStringAsFixed(2) +
                "\n" +
                ((j.reactionAngle / math.pi) * 180).toStringAsFixed(2) +
                "\nFrom " +
                j.sumaround.toString()));
        tp.paint(canvas, origin.translate(j.x * sc + 18, -j.y * sc + 14));
      }

      /*if (j.fx != null || j.fy != null) {
        var tp = textCache.getOrPerformLayout(TextSpan(
            style: TextStyle(color: Colors.deepPurpleAccent, fontWeight: FontWeight.bold, fontSize: 11.0),
            text: "Fx: " +
                (j.fx?.toStringAsFixed(2) ?? "n/a") +
                "  Fy:" +
                (j.fy?.toStringAsFixed(2) ?? "n/a") +
                "\nPath " +
                j.codepath.toString()));
        tp.paint(canvas, origin.translate(j.x * sc - 10 - tp.width, -j.y * sc - 30));
      }*/
    });

    if (showAddTruss == 1) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(size.width / 2 - (_addPaint1.width + 12) / 2, 240,
                  _addPaint1.width + 12, 30),
              Radius.circular(5)),
          trussPaint);
      _addPaint1.paint(
          canvas, Offset(size.width / 2 - (_addPaint1.width) / 2, 246));
    } else if (showAddTruss == 2) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(size.width / 2 - (_addPaint2.width + 12) / 2, 240,
                  _addPaint2.width + 12, 30),
              Radius.circular(5)),
          trussPaint);
      _addPaint2.paint(
          canvas, Offset(size.width / 2 - (_addPaint2.width) / 2, 246));
    }

    //print('time: ${DateTime.now().millisecondsSinceEpoch - t}');
  }

  List<double> anglelist(List<Truss> list) {
    //sums list of angs
    var angsum = <double>[];
    var prev = list[0];
    for (final e in list) {
      if (e == prev) {
        continue;
      }
      final ang = prev.angleBetween(e);
      angsum.add(ang);
      prev = e;
    }
    return angsum;
  }

  double anglemax(List<double> list) {
    var max = 0.0;
    for (var e in list) {
      if (e > max) {
        max = e;
      }
    }
    return max;
  }

  double anglesum(List<double> list) {
    var sum = 0.0;
    for (var e in list) {
      sum += e;
    }
    return sum;
  }
}
