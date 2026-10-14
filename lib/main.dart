import 'package:flutter/material.dart';

import 'screens/auth_gate.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SaitringApp());
}

class SaitringApp extends StatelessWidget {
  const SaitringApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SAITRING Employee Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2457C5)),
        scaffoldBackgroundColor: const Color(0xFFF5F7FB),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2457C5),
          foregroundColor: Colors.white,
          centerTitle: false,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
        ),
      ),
      home: const AuthGate(),
    );
  }
}
