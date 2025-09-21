// main.dart

import 'package:bus_seva/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

// Import the necessary pages
import 'language_selection.dart';
import 'home_screen.dart'; // Corrected import
import 'splash_screen.dart'; // New import for the splash screen

// Define a new color palette for a modern look
class AppColors {
  static const Color primary = Color(0xFFFF6B35);
  static const Color onPrimary = Colors.white;
  static const Color text = Color(0xFF1E293B);
  static const Color secondaryText = Color(0xFF6B7280);
  static const Color background = Color(0xFFF5F5F5);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bus Seva',
      theme: ThemeData(
        fontFamily: 'Cera Pro',
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          onPrimary: AppColors.onPrimary,
          secondary: AppColors.primary, // Using the same color for secondary for a cohesive look
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontFamily: 'Cera Pro',
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.text,
          ),
          iconTheme: IconThemeData(
            color: AppColors.text,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            minimumSize: const Size(double.infinity, 55),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            elevation: 0,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          filled: true,
          fillColor: Colors.white,
          hintStyle: const TextStyle(color: AppColors.secondaryText),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.transparent),
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(
              color: AppColors.primary,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      // The app should start with the SplashScreen.
      home: const SplashScreen(),
    );
  }
}