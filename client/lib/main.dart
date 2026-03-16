import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
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
        
        //УМНОЕ СЕМЕЙСТВО ШРИФТОВ
        fontFamily: 'SF Pro',
        fontFamilyFallback: const [
          'Segoe UI',      // для Windows
          'Roboto',        // для Android
          'Helvetica Neue', // запасной
          'Arial',          // ещё запасной
        ],
        
        //ТЕКСТОВЫЕ СТИЛИ
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
            color: Color.fromARGB(255, 255, 255, 255)
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
      
      //Для Cupertino виджетов используем отдельную тему
      home: CupertinoTheme(  // ← оборачиваем home в CupertinoTheme
        data: CupertinoThemeData(
          brightness: Brightness.dark,
          primaryColor: const Color(0xFF8B7EF6),
          barBackgroundColor: const Color(0xFF1E1E1E),
          scaffoldBackgroundColor: const Color(0xFF121212),
          textTheme: CupertinoTextThemeData(
            primaryColor: const Color(0xFF8B7EF6),
            textStyle: const TextStyle(
              fontFamily: 'SF Pro',
              fontFamilyFallback: [
                'Segoe UI',
                'Roboto',
                'Helvetica Neue',
                'Arial',
              ],
              color: Colors.white,
            ),
          ),
        ),
        child: const HomeScreen(),
      ),
    );
  }
}