import 'package:flutter/material.dart';
import 'package:my_first_project/firebase_options.dart';
import 'package:my_first_project/pages/Auth/signup.dart';
import 'package:my_first_project/pages/homepage.dart';
import 'package:my_first_project/pages/Auth/login.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:io' show Platform;

import 'package:my_first_project/pages/mapPage.dart';

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
      home: Builder(builder: (context) => Signup()),
    );
  }
}
