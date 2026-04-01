import 'package:flutter/material.dart';
import 'package:my_first_project/firebase_options.dart';
import 'package:my_first_project/pages/Auth/signup.dart';
import 'package:my_first_project/pages/homepage.dart';
import 'package:my_first_project/pages/Auth/login.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:io' show Platform;

import 'package:my_first_project/pages/mapPage.dart';

class NMColors {
  static const bg = Color(0xFF0F1A12);
  static const surface = Color(0xFF162019);
  static const card = Color(0xFF1E2D22);
  static const green = Color(0xFF4ADE80);
  static const greenDim = Color(0xFF22C55E);
  static const amber = Color(0xFFFBBF24);
  static const red = Color(0xFFEF4444);
  static const orange = Color(0xFFF97316);
  static const muted = Color(0xFF6B8F71);
  static const text = Color(0xFFE8F5E9);
  static const border = Color(0x1F4ADE80);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Only initialize Firebase on supported platforms
  try {
    if (!Platform.isLinux) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('Firebase initialized on ${Platform.operatingSystem}');
    } else {
      print('Running on Linux - Firebase disabled for UI development');
    }
  } catch (e) {
    print('Firebase initialization skipped: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Builder(builder: (context) => LoginPage()),
    );
  }
}
