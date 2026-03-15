import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/auth_screen.dart';
import 'services/auth_service.dart';
import 'models/user.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await authService.init();
  runApp(const Synapse());
}

class Synapse extends StatefulWidget {  // ← StatefulWidget
  const Synapse({super.key});

  @override
  State<Synapse> createState() => _SynapseState();
}

class _SynapseState extends State<Synapse> {
  @override
  void initState() {
    super.initState();
    // Подписываемся на изменения
    authService.addListener((user) {
      setState(() {}); // ← Просто перерисовываем
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Synapse',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'CupertinoSystemText',
        colorScheme: const ColorScheme.dark(
          primary: Color.fromARGB(255, 96, 92, 255),
          surface: Color.fromARGB(255, 18, 18, 18),
          background: Color.fromARGB(255, 10, 10, 10),
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          bodyMedium: TextStyle(fontSize: 14),
          bodySmall: TextStyle(fontSize: 12),
        ),
      ),
      home: authService.currentUser == null 
          ? const AuthScreen() 
          : const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}