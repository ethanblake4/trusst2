import 'package:flutter/material.dart';

import 'app.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trusst',
      theme: ThemeData.from(
          colorScheme: ColorScheme(
              brightness: Brightness.light,
              primary: Colors.lightGreen,
              onPrimary: Colors.black,
              secondary: Colors.orange,
              onSecondary: Colors.white,
              error: Colors.red,
              onError: Colors.white,
              surface: Colors.grey[100]!,
              onSurface: Colors.black)),
      home: TrusstHomePage(title: 'Trusst'),
    );
  }
}
