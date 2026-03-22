import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:synapse/database/database_helper.dart';
import 'package:synapse/providers/auth_provider.dart';
import 'package:synapse/providers/folder_provider.dart';
import 'package:synapse/providers/sync_provider.dart';
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
        ChangeNotifierProvider(create: (_) => SyncProvider()),
      ],
      child: Consumer4<ThemeProvider, AuthProvider, FolderProvider, SyncProvider>(
        builder: (context, theme, auth, folder, sync, child) {
          final appTheme = theme.currentTheme;
          if (auth.isAuthenticated && !sync.isAutoSyncRunning) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              sync.startAutoSync(context);
            });
          }
          return MaterialApp(
            title: 'Synapse',
            debugShowCheckedModeBanner: false,
            theme: appTheme.toThemeData(),
            home: auth.isLoading
                ? const Center(child: CircularProgressIndicator())
                : auth.isAuthenticated
                    ? const HomeScreen()
                    : const AuthScreen(),
          );
        },
      ),
    );
  }
}