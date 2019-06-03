import 'package:flutter/material.dart';

List<ThemeData> THEMES = <ThemeData>[
  ThemeData(
    primaryColor: Colors.deepPurple.shade700,
    brightness: Brightness.dark,
    accentColor: Colors.orange,
  ),
  ThemeData(
    primaryColor: Colors.blue.shade800,
    backgroundColor: Colors.blue.shade900,
    brightness: Brightness.dark,
  ),
  ThemeData(
    primaryColor: Colors.pink.shade300,
    brightness: Brightness.dark,
    backgroundColor: Colors.white,
    accentColor: Colors.lightGreenAccent,
  ),
  ThemeData(
    primaryColor: Colors.grey.shade900,
    backgroundColor: Colors.grey.shade900,
    accentColor: Colors.red.shade600,
    brightness: Brightness.dark,
  ),
  ThemeData(
    primaryColor: Colors.white,
    brightness: Brightness.light,
    backgroundColor: Colors.white,
    accentColor: Colors.orange,
  ),
];

String getBgImage(int i) {
  switch (i) {
    case 0:
      return 'assets/images/bg-purple.jpg';
    case 1:
      return 'assets/images/bg-blue.jpg';
    case 2:
      return 'assets/images/bg-pink.jpg';
    case 3:
      return 'assets/images/bg-black.jpg';
  }
  return null;
}