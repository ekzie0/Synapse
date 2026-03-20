import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:synapse/database/database_helper.dart';
import 'package:synapse/providers/auth_provider.dart';
import 'package:synapse/providers/folder_provider.dart';
import 'package:synapse/providers/theme_provider.dart';
import 'package:synapse/screens/auth_screen.dart';
import 'package:synapse/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  DatabaseHelper.init();
  runApp(const SynapseApp());
}

class SynapseApp extends StatelessWidget {
  const SynapseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => FolderProvider()),
      ],
      child: Consumer3<ThemeProvider, AuthProvider, FolderProvider>(
        builder: (context, themeProvider, authProvider, folderProvider, child) {
          final appTheme = themeProvider.currentTheme;
          final materialThemeData = appTheme.toThemeData();

          return MaterialApp(
            title: 'Synapse',
            debugShowCheckedModeBanner: false,
            theme: materialThemeData,
            home: authProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : (authProvider.isAuthenticated
                    ? const HomeScreen()
                    : const AuthScreen()),
          );
        },
      ),
    );
  }
}