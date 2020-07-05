import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:scidart/numdart.dart';

import 'joint.dart';
import 'truss.dart';

class ForceCalculator {
  static var abs = (num x) => x < 0 ? -x : x;
  static bool debugMode;

  /// Calculates moment, reaction forces, and reaction sums
  static void calcForces([bool useFast = false]) {
    // Determine if we are in debug mode to choose the max number of iterations to calculate
    // Release mode is significantly faster, so we do more iterations there
    if (debugMode == null) {
      debugMode = _isInDebugMode;
      print("Debug : $debugMode");
    }

    // Reset joints
    Joint.all.values.forEach((j) {
      j.fx = null;
      j.fy = null;
      j.moment = null;
      j.reactionForce = 0;
      j.reactionAngle = 0;
      j.sumaround = -1;
      j.tempId = null;
    });

    var i = 0;

    var ss = '';

    for (final t in Truss.all.values) {
      ss += '${t.startId}-${t.endId},   ';
      t.tempId = i++;
    }

    for (final j in Joint.all.values) {
      if (j.type != JointType.STANDARD) {
        if (j.type == JointType.PINNED) {
          ss += 's${j.id}y,   s${j.id}x,   ';
          j.tempIdH = i++;
          j.tempId = i++;
          continue;
        }
        if (j.type == JointType.ROLLER_H) {
          ss += 's${j.id}x,   ';
          j.tempIdH = i++;
          continue;
        }
        if (j.type == JointType.ROLLER_V) {
          ss += 's${j.id}y,   ';
          j.tempId = i++;
        }
      }
    }

    var q = i;
    var debug = Random().nextInt(60) == 1;

    // Up = +, Right = +
    //Matrix(_data)
    final forceList = <double>[];
    final rowi = <String>[];
    final jointRows = <List<double>>[];

    for (final j in Joint.all.values) {
      final jRow = List.filled(q, 0.0);
      final jRowH = List.filled(q, 0.0);

      final cTrusses = j.connectedTrusses;
      for (final trc in cTrusses) {
        final sign = trc.startId == j.id ? 1 : -1;
        jRow[trc.tempId] = sin(trc.angle) * sign;
        jRowH[trc.tempId] = cos(trc.angle) * sign;
      }

      if (j.type == JointType.STANDARD && (j.exAmount ?? 0) > 0) {
        final vr = (j.exDir == AxisDirection.up ? -1 : j.exDir == AxisDirection.down ? 1 : 0) * j.exAmount;
        final hz = (j.exDir == AxisDirection.left ? 1 : j.exDir == AxisDirection.right ? -1 : 0) * j.exAmount;
        forceList.add(-vr);
        forceList.add(-hz);
      } else {
        forceList.add(0.0);
        forceList.add(0.0);
        if (j.type == JointType.ROLLER_H) {
          jRow[j.tempIdH] = 1;
        } else if (j.type == JointType.ROLLER_V) {
          jRowH[j.tempId] = 1;
        } else if (j.type == JointType.PINNED) {
          jRow[j.tempId] = 1;
          jRowH[j.tempIdH] = 1;
        }
      }
      jointRows.add(jRowH);
      jointRows.add(jRow);
      rowi.add('n${j.id}x');
      rowi.add('n${j.id}y');
    }

    var mat = [...jointRows];
    final mtrix = Array2d(mat.map((e) => Array(e)).toList());

    final lu = LU(mtrix);

    final lusolve = lu.solve(Array2d(forceList.map((f) => Array([f])).toList()));

    var pmat = mat.map((e) => e.map((ea) => (ea.isNegative ? '' : ' ') + ea.toStringAsFixed(2)));

    var o = 0;

    if (debug) {
      print('${mat.length} vs $q');
      print('      ${ss}F');
      pmat.forEach((m) {
        print('${rowi[o]} $m ${forceList[o].isNegative ? '' : ' '}${forceList[o]}');
        o++;
      });

      print('solved:');
      print(lusolve
          .toList()
          .map((e) => e.l)
          .reduce((value, element) => [...value.toList(), element[0]])
          .map((e) => e.toStringAsFixed(2)));
    }

    // Cache the All180 list of joints for each Joint, because it is slow to calculate
    /*var cachedAll180Joint = Map<int, List<Joint>>();

    /// =========================================================== ///
    /// ======== STEP 1: Calculate moment and reactions =========== ///
    /// =========================================================== ///
    cstep = Joint.globalCalcStep++;
    while (iteration < (useFast ? (debugMode ? 5 : 45) : Joint.all.length * (debugMode ? 5 : 15)) && !complete) {
      // Loop all the joints
      Joint.all.values.forEach((j) {
        // If the joint has not yet been calculated for this cycle
        if (j.calcStep < cstep) {
          // ==== Step 1a. ====
          // Find the list of Joints connected to this Joint, and any Joints connected to them at a 180-degree angle
          // (such that they effectively can be treated as part of the same Truss)
          // Referred to as all180Joint
          // This is slow to calculate so it is cached
          Iterable<Joint> all180Joint;
          if (cachedAll180Joint.containsKey(j.id))
            all180Joint = cachedAll180Joint[j.id];
          else {
            final all180 = j.connectedTrusses.expand((t) => _findAll180(t, j));
            all180Joint =
                all180.expand((t2) => [t2.startJoint, t2.endJoint]).toSet().where((j2) => j2.id != j.id).toList();
            cachedAll180Joint[j.id] = all180Joint;
          }

          // ==== Step 1b and 1c. ====
          // Calculate the moment from the all180Joint joints on this Joint,
          // and determine the number of unknowns (pinned/fixed/roller joints that have not been calculated)
          // These steps are combined for calculation efficiency
          var numUnknown = 0;
          j.moment = all180Joint.fold(0, (m, j3) {
            if (j3.type != JointType.STANDARD && (j3.rCalcStep < cstep || j3.calcStep < cstep)) numUnknown++;
            return m + j3.calcMomentOn(j);
          });

          // ==== Step 1d and 1e. ====
          // If there is only one unknown, calculate the reaction force this Joint induces in it,
          // and calculate fast-path (Path 0) reaction sums
          if (numUnknown == 1 && j.type != JointType.STANDARD) {
            var unknowns = all180Joint
                .where((j4) => j4.type != JointType.STANDARD && (j4.rCalcStep < cstep || j4.calcStep < cstep));
            var j6 = unknowns.first;
            var dist = Offset(j6.x - j.x, j6.y - j.y).distance;
            j6.reactionForce = -j.moment / dist;
            j6.reactionAngle =
                math.atan2(j6.y - j.y, j6.x - j.x) + (j6.reactionForce > 0 ? (-math.pi / 2) : (math.pi / 2));
            j6.sumaround = j.id;
            if (j6.type == JointType.ROLLER_H) {
              j6.reactionForce = j6.reactionForce * math.sin(j6.reactionAngle);
            } else if (j6.type == JointType.ROLLER_V) {
              j6.reactionForce = j6.reactionForce * math.cos(j6.reactionAngle);
            }
            // Fast-path reaction sum
            j6.fx = -math.cos(j6.reactionAngle) * abs(j6.reactionForce);
            j6.fy = -math.sin(j6.reactionAngle) * abs(j6.reactionForce);
            j6.codepath = 0;
            j6.fCalcStep = cstep;
            j6.rCalcStep = cstep;
          }

          // Mark this joint as having been calculated
          j.calcStep = cstep;
        }
      });

      cstep++;
      iteration++;
    }

    // ==== Step 1f. ====
    // Find lists of Joints that form unique contiguous structures.
    // We can't use a recursive algorithm here because paths can connect, forming infinite loops
    var accountedIds = Set<int>(); // all the joints we've looked at
    var contiguousStructures = <List<Joint>>[]; // the list of Lists of Joints forming contiguous structures
    Joint.all.values.forEach((j) {
      if (accountedIds.contains(j.id)) return;
      accountedIds.add(j.id);
      var clist = Set<Joint>();
      var llist = Queue<Truss>()..addAll(j.connectedTrusses);
      while (llist.isNotEmpty) {
        var t = llist.removeFirst();
        if (!accountedIds.contains(t.startId)) {
          // If we haven't seen the joint before, add it to the current structure
          accountedIds.add(t.startId);
          clist.add(t.startJoint);
          llist.addAll(t.startJoint.connectedTrusses);
        }
        if (!accountedIds.contains(t.endId)) {
          accountedIds.add(t.endId);
          clist.add(t.endJoint);
          llist.addAll(t.endJoint.connectedTrusses);
        }
      }

      contiguousStructures.add(clist.toList());
    });
    if (t0 % 30 == 0) print("Contiguous: ${contiguousStructures.length}");

    contiguousStructures.forEach((contiguousJoints) {
      // ==== Step 1g. ====
      // Sum forces in the vertical direction. and apply them to the unknown joint (if any) ("Path 1")
      Joint unknown;
      var numUnknowns = 0;
      double sumVertical = contiguousJoints.where((j) => j.type != JointType.ROLLER_V).fold(0.0, (v, j) {
        if (/*abs((j.reactionForce ?? 0) * math.sin(j.reactionAngle)) <= 0.0001*/ j.rCalcStep < cstep &&
            j.type != JointType.STANDARD) {
          if (unknown == null) {
            unknown = j;
            numUnknowns = 1;
            return v;
          } else {
            numUnknowns++;
            return v;
          }
        }
        return v +
            (j.fy ?? 0) +
            (j.exAmount ?? 0) * (j.exDir == AxisDirection.up ? 1 : j.exDir == AxisDirection.down ? -1 : 0);
      });
      if (t0 % 30 == 0) print("$numUnknowns unknowns fy");
      if (numUnknowns == 1) {
        unknown.fy = -sumVertical;
        unknown.fx = -math.cos(unknown.reactionAngle) * abs(unknown.reactionForce);
        unknown.fCalcStep2 = cstep;
        unknown.codepath = 1;
      }

      // ==== Step 1h. ====
      // Sum forces in the horizontal direction. and apply them to the unknown joint (if any) ("Path 2/3")
      numUnknowns = 0;
      unknown = null;
      var sumHorizontal = contiguousJoints.where((j) => j.type != JointType.ROLLER_H).fold(0, (v, j) {
        if (/*abs((j.reactionForce ?? 0) * math.cos(j.reactionAngle)) <= 0.0001*/ j.rCalcStep < cstep &&
            j.type != JointType.STANDARD) {
          if (unknown == null) {
            unknown = j;
            numUnknowns = 1;
          } else
            numUnknowns++;
          return v;
        }
        return v +
            (j.fx ?? 0) +
            (j.exAmount ?? 0) * (j.exDir == AxisDirection.right ? 1 : j.exDir == AxisDirection.left ? -1 : 0);
      });

      if (t0 % 30 == 0) print("$numUnknowns unknowns fy");
      if (numUnknowns == 1) {
        unknown.fx = sumHorizontal;
        // If we already used step 1g on this joint (eg. it is unknown in both vertical and horizontal),
        // don't fast-path the vertical calculation ("Path 3")
        unknown.fy =
            unknown.fCalcStep2 == cstep ? unknown.fy : -math.sin(unknown.reactionAngle) * abs(unknown.reactionForce);
        unknown.codepath = unknown.fCalcStep2 == cstep ? 3 : 2;
      }
    });*/
  }

  /// This function makes use of the fact that assert statements only run in debug mode, to test whether the
  /// app is running in debug mode
  static bool get _isInDebugMode {
    bool inDebugMode = false;
    assert(inDebugMode = true);
    return inDebugMode;
  }

  /// Finds all [Truss]es linked recursively to [t] at a 180 degree angle starting from the [Joint] opposite to [j]
  static Iterable<Truss> _findAll180(Truss t, Joint j) {
    final connectsAtStart = t.startId == j.id;
    final j180 = connectsAtStart
        ? t.endJoint.connectedTrusses.where((t2) =>
            t.dyDx.toStringAsFixed(3) == t2.dyDx.toStringAsFixed(3) && (t.startId != t2.startId || t.endId != t2.endId))
        : t.startJoint.connectedTrusses.where((t2) =>
            t.dyDx.toStringAsFixed(3) == t2.dyDx.toStringAsFixed(3) &&
            (t.startId != t2.startId || t.endId != t2.endId));
    final ll = <Truss>[t];
    if (j180.length == 0) return ll;
    ll.addAll(j180.toList().expand((t3) => _findAll180(t3, connectsAtStart ? t.endJoint : t.startJoint)));
    return ll;
  }
}
