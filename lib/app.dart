import 'package:flutter/material.dart';
import 'package:trusst/construct_area.dart';
import 'package:trusst/force_calculator.dart';

import 'coords_dialog.dart';
import 'force_calculator.dart';
import 'force_dialog.dart';
import 'joint.dart';
import 'truss.dart';

class TrusstHomePage extends StatefulWidget {
  TrusstHomePage({super.key, required this.title});

  final String title;

  @override
  _TrusstHomePageState createState() => _TrusstHomePageState();
}

class _TrusstHomePageState extends State<TrusstHomePage> {
  bool showAngles = false;
  int? selectedJoint;
  bool addTruss = false;
  SnapMode snapMode = SnapMode.GRID;
  bool ortho = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Trusst',
          style: TextStyle(fontFamily: 'FontinSansSC'),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0.0,
      ),
      body: LayoutBuilder(builder: (context, constraints) {
        return ListView(
          physics: const NeverScrollableScrollPhysics(),
          children: <Widget>[
            Padding(
                padding: const EdgeInsets.all(8.0),
                child: SizedBox(
                  child: ClipRRect(
                    child: ConstructArea(
                        snapMode, ortho, showAngles, addTruss, selectedJoint,
                        (jointId) {
                      setState(() {
                        selectedJoint = jointId;
                      });
                    },
                        () => setState(() {
                              ForceCalculator.calcForces();
                            }),
                        () => setState(() {
                              ForceCalculator.calcForces();
                            }),
                        constraints),
                    borderRadius: const BorderRadius.all(Radius.circular(8.0)),
                  ),
                  height: constraints.maxHeight / 1.15 - 230,
                )),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    "Options",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: <Widget>[
                      buildStateButton(
                          snapMode == SnapMode.GRID, "Snap", Icons.crop_free,
                          () {
                        setState(() {
                          if (snapMode == SnapMode.GRID)
                            snapMode = SnapMode.NONE;
                          else
                            snapMode = SnapMode.GRID;
                        });
                      }),
                      buildStateButton(showAngles, "Angles", Icons.threesixty,
                          () {
                        setState(() {
                          showAngles = !showAngles;
                        });
                      }),
                      buildStateButton(ortho, "Ortho", Icons.border_inner, () {
                        setState(() {
                          ortho = !ortho;
                          if (snapMode == SnapMode.PERPENDICULAR)
                            snapMode = SnapMode.NONE;
                        });
                      }),
                    ],
                  ),
                ]..addAll(createDynamicControlStrips(context)),
              ),
            )
          ],
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            addTruss = !addTruss;
          });
        },
        shape: const CircleBorder(),
        tooltip: 'Add truss',
        child: Icon(addTruss ? Icons.check : Icons.add),
        backgroundColor: Theme.of(context).colorScheme.secondary,
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  Iterable<Widget> createDynamicControlStrips(BuildContext context) sync* {
    if (addTruss) {
      yield Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          "Add Truss",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      );
      yield ConstrainedBox(
        constraints: BoxConstraints(maxHeight: 36.0),
        child: ListView(
          scrollDirection: Axis.horizontal,
          shrinkWrap: true,
          children: <Widget>[
            buildStateButton(
                snapMode == SnapMode.NEAREST, "Nearest", Icons.adjust, () {
              setState(() {
                if (snapMode == SnapMode.NEAREST)
                  snapMode = SnapMode.NONE;
                else
                  snapMode = SnapMode.NEAREST;
              });
            }),
            buildStateButton(
                snapMode == SnapMode.PERPENDICULAR, "Right", Icons.title, () {
              setState(() {
                if (snapMode == SnapMode.PERPENDICULAR)
                  snapMode = SnapMode.NONE;
                else {
                  snapMode = SnapMode.PERPENDICULAR;
                  ortho = false;
                }
              });
            }),
          ],
        ),
      );
    }
    if (selectedJoint != null) {
      var j = Joint.all[selectedJoint]!;
      yield Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          "Selected Joint",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      );
      yield ConstrainedBox(
        constraints: BoxConstraints(maxHeight: 36.0),
        child: ListView(
          scrollDirection: Axis.horizontal,
          shrinkWrap: true,
          children: <Widget>[
            buildStateButton(j.type == JointType.STANDARD, "Joint",
                Icons.fiber_manual_record, () {
              if (j.type != JointType.STANDARD)
                setState(() {
                  j.type = JointType.STANDARD;
                  ForceCalculator.calcForces();
                });
            }),
            buildStateButton(j.type == JointType.PINNED, "Pin", Icons.details,
                () {
              if (j.type != JointType.PINNED)
                setState(() {
                  j.type = JointType.PINNED;
                  ForceCalculator.calcForces();
                });
            }),
            buildStateButton(
                j.type == JointType.ROLLER_H, "Roll H", Icons.swap_horiz, () {
              if (j.type != JointType.ROLLER_H)
                setState(() {
                  j.type = JointType.ROLLER_H;
                  ForceCalculator.calcForces();
                });
            }),
            buildStateButton(
                j.type == JointType.ROLLER_V, "Roll V", Icons.swap_vert, () {
              if (j.type != JointType.ROLLER_V)
                setState(() {
                  j.type = JointType.ROLLER_V;
                  ForceCalculator.calcForces();
                });
            })
          ],
        ),
      );
      yield Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: 36.0),
          child: ListView(
            scrollDirection: Axis.horizontal,
            shrinkWrap: true,
            children: <Widget>[
              buildStateButton(true, "Delete", Icons.delete_forever, () {
                setState(() {
                  Joint.all[selectedJoint]!.delete();
                  Joint.all.values.toList().forEach((j) {
                    if (j.connectedTrusses.length == 0)
                      j.delete();
                    else
                      j.trussCacheKey = -1;
                  });
                  selectedJoint = null;
                  ForceCalculator.calcForces();
                });
              }, Colors.red),
              buildStateButton(
                  Joint.all[selectedJoint]!.type == JointType.STANDARD,
                  "Force",
                  Icons.assignment_returned, () async {
                if (Joint.all[selectedJoint]!.type != JointType.STANDARD)
                  return;
                Force? force = await showDialog(
                    context: context,
                    builder: (context) => ForceDialog(Force(
                        Joint.all[selectedJoint]!.exDir ?? AxisDirection.down,
                        Joint.all[selectedJoint]!.exAmount ?? 0)));
                setState(() {
                  Joint.all[selectedJoint]!
                    ..exDir = force?.direction
                    ..exAmount = force?.intensity;
                  ForceCalculator.calcForces();
                });
              }, Colors.blueGrey),
              if (Joint.hitTestMultiple(j.x, j.y, 0.5)
                      .where((o) => o.id != j.id)
                      .length >
                  0)
                buildStateButton(true, "Merge", Icons.merge_type, () {
                  setState(() {
                    Joint.hitTestMultiple(j.x, j.y, 0.5)
                        .where((o) => o.id != j.id)
                        .toList()
                        .forEach((o) {
                      o.connectedTrusses.forEach((truss) {
                        truss.delete();
                        if (truss.startId == o.id)
                          Truss(j.id, truss.endId);
                        else
                          Truss(truss.startId, j.id);
                      });
                      o.delete();
                    });
                    ForceCalculator.calcForces();
                  });
                }, Colors.blue),
              if (Truss.embeddable(j).length > 0)
                buildStateButton(true, "Embed", Icons.keyboard_tab, () {
                  setState(() {
                    Truss.embed(j);
                    ForceCalculator.calcForces();
                  });
                }, Colors.orangeAccent),
              buildStateButton(true, "Coords", Icons.place, () async {
                Offset? o = await showDialog(
                    context: context,
                    builder: (context) => CoordsDialog(selectedJoint!));
                if (o != null)
                  setState(() {
                    Joint.all[selectedJoint]!.x = o.dx;
                    Joint.all[selectedJoint]!.y = o.dy;
                    ForceCalculator.calcForces();
                  });
              }, Colors.deepOrange),
            ],
          ),
        ),
      );
    }
  }

  Widget buildStateButton(
      bool can, String text, IconData ic, VoidCallback onTap,
      [Color color = Colors.lightGreen]) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: TextButton(
        style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all(
              can ? color : Colors.grey.shade200,
            ),
            padding: WidgetStateProperty.all(
                EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0))),
        child: Row(
          children: <Widget>[
            Icon(
              ic,
              color: can ? Colors.white : Colors.black54,
            ),
            Padding(
              padding: const EdgeInsets.only(left: 4.0),
              child: Text(
                text,
                style: TextStyle(
                  color: can ? Colors.white : Colors.black54,
                ),
              ),
            )
          ],
        ),
        onPressed: onTap,
      ),
    );
  }
}
