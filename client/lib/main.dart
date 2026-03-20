import 'package:flutter/material.dart';
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
          final appTheme = themeProvider.currentTheme;
          final materialThemeData = appTheme.toThemeData();

          return MaterialApp(
            title: 'Synapse',
            debugShowCheckedModeBanner: false,
            theme: materialThemeData,
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}