import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:my_first_project/firebase_options.dart';
import 'package:my_first_project/pages/Auth/signup.dart';
import 'package:my_first_project/pages/depricated/homepage.dart';
import 'package:my_first_project/pages/Auth/login.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:io' show Platform;

import 'package:my_first_project/pages/depricated/mapPage.dart';
import 'package:my_first_project/pages/shell.dart';

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

  runApp(const Bayanati());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Builder(builder: (context) => AppShell()),
    );
  }
}

// facing page i guess T_T .......

const thisDumbParameterExpectsConstArguments = SystemUiOverlayStyle(
  statusBarIconBrightness: Brightness.light,
);

class Bayanati extends StatelessWidget {
  const Bayanati({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NeglectMap',
      debugShowCheckedModeBanner: false,

      // Defining the theme pallet im a terrible designer
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: NMColors.bg,

        colorScheme: const ColorScheme.dark(
          primary: NMColors.green,
          secondary: NMColors.greenDim,
          surface: NMColors.surface,
          error: NMColors.red,
          onPrimary: Color(0xFF0A1A0C),
          onSurface: NMColors.text,
        ),

        // AppBar
        appBarTheme: const AppBarTheme(
          backgroundColor: NMColors.bg,
          foregroundColor: NMColors.text,
          elevation: 0,
          scrolledUnderElevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarIconBrightness: Brightness.light,
          ),
          titleTextStyle: TextStyle(
            color: NMColors.text,
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
        ),

        // Bottom nav
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: NMColors.surface,
          selectedItemColor: NMColors.green,
          unselectedItemColor: NMColors.muted,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedLabelStyle: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
          unselectedLabelStyle: TextStyle(fontSize: 11),
        ),

        // Cards
        cardTheme: CardThemeData(
          color: NMColors.card,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: NMColors.border, width: 0.5),
          ),
        ),

        // Elevated buttons (used for submt / primary actions)
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: NMColors.green,
            foregroundColor: const Color(0xFF0A1A0C),
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
            ),
          ),
        ),

        // Text input
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: NMColors.card,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: NMColors.border, width: 0.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: NMColors.border, width: 0.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: NMColors.green, width: 1),
          ),
          hintStyle: const TextStyle(color: NMColors.muted, fontSize: 14),
          labelStyle: const TextStyle(color: NMColors.muted, fontSize: 14),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            color: NMColors.text,
            fontWeight: FontWeight.w700,
          ),
          titleLarge: TextStyle(
            color: NMColors.text,
            fontWeight: FontWeight.w600,
            fontSize: 17,
            letterSpacing: -0.3,
          ),
          titleMedium: TextStyle(
            color: NMColors.text,
            fontWeight: FontWeight.w500,
            fontSize: 15,
          ),
          bodyLarge: TextStyle(color: NMColors.text, fontSize: 15, height: 1.5),
          bodyMedium: TextStyle(
            color: NMColors.text,
            fontSize: 13,
            height: 1.4,
          ),
          bodySmall: TextStyle(color: NMColors.muted, fontSize: 12),
          labelSmall: TextStyle(
            color: NMColors.muted,
            fontSize: 10,
            letterSpacing: 0.5,
          ),
        ),

        dividerTheme: const DividerThemeData(
          color: NMColors.border,
          thickness: 1,
          space: 0,
        ),
      ),

      // ── Entry point: show login, then shell ────────────────────────────────
      home: const LoginPage(),
    );
  }
}
