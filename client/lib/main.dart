import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'providers/theme_provider.dart';

void main() {
  runApp(const SynapseApp());
}

class SynapseApp extends StatelessWidget {
  const SynapseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          final theme = themeProvider.currentTheme;
          
          return MaterialApp(
            title: 'Synapse',
            debugShowCheckedModeBanner: false,
            theme: theme.toThemeData(),
            home: CupertinoTheme(
              data: CupertinoThemeData(
                brightness: theme.brightness,
                primaryColor: theme.primaryColor,
                barBackgroundColor: theme.brightness == Brightness.dark
                    ? const Color(0xFF1E1E1E)
                    : Colors.white,
                scaffoldBackgroundColor: Colors.transparent,
                textTheme: CupertinoTextThemeData(
                  primaryColor: theme.primaryColor,
                  textStyle: TextStyle(
                    fontFamily: 'SF Pro',
                    fontFamilyFallback: const [
                      'Segoe UI',
                      'Roboto',
                      'Helvetica Neue',
                      'Arial',
                    ],
                    color: theme.brightness == Brightness.dark 
                        ? Colors.white 
                        : Colors.black,
                  ),
                ),
              ),
              child: const HomeScreen(),
            ),
          );
        },
      ),
    );
  }
}