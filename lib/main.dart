import 'package:flutter/material.dart';
import 'package:my_first_project/firebase_options.dart';
import 'package:my_first_project/pages/homepage.dart';
import 'package:my_first_project/pages/mapPage.dart';
import 'package:my_first_project/pages/Auth/login.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:io' show Platform;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Initialize Firebase only on supported platforms
  if (!Platform.isLinux) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized on ${Platform.operatingSystem}');
  } else {
    print('Running on Linux - Firebase disabled for UI development');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginPage(),
    ); //MaterialApp
  }
}
