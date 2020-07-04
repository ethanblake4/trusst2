import 'package:flutter/material.dart';

class ForceDialog extends StatefulWidget {
  @override
  _ForceDialogState createState() => _ForceDialogState();

  final Force initialForce;

  ForceDialog(this.initialForce);
}

class _ForceDialogState extends State<ForceDialog> {
  int exFdir = 0;
  TextEditingController _textfield = TextEditingController();

  @override
  void initState() {
    super.initState();
    exFdir = widget.initialForce.direction == AxisDirection.down
        ? 0
        : widget.initialForce.direction == AxisDirection.up
            ? 1
            : widget.initialForce.direction == AxisDirection.left ? 2 : 3;
    if (widget.initialForce.intensity != null) _textfield.text = widget.initialForce.intensity.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
        child: Padding(
      padding: const EdgeInsets.all(16.0).copyWith(bottom: 4.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            "External Force",
            style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
          ),
          Padding(
            padding: EdgeInsets.only(top: 8.0),
          ),
          Row(
            children: <Widget>[
              Material(
                borderRadius: BorderRadius.all(Radius.circular(32.0)),
                color: exFdir == 0 ? Colors.lightGreen : Colors.transparent,
                child: InkWell(
                  child: Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: Icon(
                      Icons.arrow_downward,
                      color: exFdir == 0 ? Colors.white : Colors.black,
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      exFdir = 0;
                    });
                  },
                ),
              ),
              Material(
                borderRadius: BorderRadius.all(Radius.circular(32.0)),
                color: exFdir == 1 ? Colors.lightGreen : Colors.transparent,
                child: InkWell(
                  child: Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: Icon(
                      Icons.arrow_upward,
                      color: exFdir == 1 ? Colors.white : Colors.black,
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      exFdir = 1;
                    });
                  },
                ),
              ),
              Material(
                borderRadius: BorderRadius.all(Radius.circular(32.0)),
                color: exFdir == 2 ? Colors.lightGreen : Colors.transparent,
                child: RotatedBox(
                  quarterTurns: 1,
                  child: InkWell(
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Icon(
                        Icons.arrow_downward,
                        color: exFdir == 2 ? Colors.white : Colors.black,
                      ),
                    ),
                    onTap: () {
                      setState(() {
                        exFdir = 2;
                      });
                    },
                  ),
                ),
              ),
              Material(
                borderRadius: BorderRadius.all(Radius.circular(32.0)),
                color: exFdir == 3 ? Colors.lightGreen : Colors.transparent,
                child: RotatedBox(
                    quarterTurns: 1,
                    child: InkWell(
                      child: Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: Icon(
                          Icons.arrow_upward,
                          color: exFdir == 3 ? Colors.white : Colors.black,
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          exFdir = 3;
                        });
                      },
                    )),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: TextField(
              controller: _textfield,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(border: OutlineInputBorder(), hintText: "Value"),
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: FlatButton(
                onPressed: () {
                  Navigator.of(context).pop(Force(
                      exFdir == 0
                          ? AxisDirection.down
                          : exFdir == 1 ? AxisDirection.up : exFdir == 2 ? AxisDirection.left : AxisDirection.right,
                      double.tryParse(_textfield.text)));
                },
                child: Text("OK")),
          )
        ],
      ),
    ));
  }
}

class Force {
  AxisDirection direction;
  double intensity;

  Force(this.direction, this.intensity);

  @override
  String toString() {
    return 'Force{direction: $direction, intensity: $intensity}';
  }
}
