import 'package:flutter/material.dart';

import 'joint.dart';

class CoordsDialog extends StatefulWidget {
  @override
  _CoordsDialogState createState() => _CoordsDialogState();

  CoordsDialog(this.id);
  final int id;
}

class _CoordsDialogState extends State<CoordsDialog> {
  TextEditingController _xTextfield = TextEditingController();
  TextEditingController _yTextfield = TextEditingController();

  @override
  void initState() {
    super.initState();

    _xTextfield.text = Joint.all[widget.id]!.x.toStringAsFixed(4);
    _yTextfield.text = Joint.all[widget.id]!.y.toStringAsFixed(4);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
        child: ConstrainedBox(
      constraints: BoxConstraints.loose(Size.fromWidth(400)),
      child: Padding(
        padding: const EdgeInsets.all(16.0).copyWith(bottom: 4.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              "Joint Coordinates",
              style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
            ),
            Padding(
              padding: EdgeInsets.only(top: 8.0),
            ),
            Row(
              children: <Widget>[
                Text(
                  "( ",
                  style: TextStyle(fontSize: 26),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: TextField(
                      controller: _xTextfield,
                      keyboardType:
                          TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(hintText: "x"),
                    ),
                  ),
                ),
                Text(
                  ", ",
                  style: TextStyle(fontSize: 26),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: TextField(
                      controller: _yTextfield,
                      keyboardType:
                          TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(hintText: "y"),
                    ),
                  ),
                ),
                Text(
                  " )",
                  style: TextStyle(fontSize: 26),
                ),
              ],
              mainAxisSize: MainAxisSize.min,
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(Offset(
                        double.tryParse(_xTextfield.text) ??
                            Joint.all[widget.id]!.x,
                        double.tryParse(_yTextfield.text) ??
                            Joint.all[widget.id]!.y));
                  },
                  child: Text("OK")),
            )
          ],
        ),
      ),
    ));
  }
}
