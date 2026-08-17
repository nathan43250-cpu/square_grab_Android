import 'package:flutter/material.dart';
import 'map_screen.dart';

void main() {
  runApp(const SquareGrabApp());
}

class SquareGrabApp extends StatelessWidget {
  const SquareGrabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Square Grab',
      theme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
        useMaterial3: true,
      ),
      home: const MapScreen(),
    );
  }
}
