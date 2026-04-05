import 'package:flutter/material.dart';
import 'screens/map_screen.dart';

void main() {
  runApp(const RouteApp());
}

class RouteApp extends StatelessWidget {
  const RouteApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Учебный проект: Карты',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MapScreen(),
    );
  }
}