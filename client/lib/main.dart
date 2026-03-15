import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const SynapseApp());
}

class SynapseApp extends StatelessWidget {
  const SynapseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Synapse',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: false,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8B7EF6),
          brightness: Brightness.dark,
        ).copyWith(
          surface: const Color(0xFF1E1E1E),
          background: const Color(0xFF121212),
        ),
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent, 
        scaffoldBackgroundColor: const Color(0xFF121212),
        fontFamily: 'Segoe UI', // Для Windows
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
          titleLarge: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
          bodyLarge: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.normal,
          ),
          bodyMedium: TextStyle(
            fontSize: 13,
            color: Color(0xFF9E9E9E),
          ),
          labelLarge: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}