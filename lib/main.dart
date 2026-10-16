import 'package:flutter/material.dart';

import 'core/storage/token_storage.dart';
import 'features/owner/presentation/screens/login_screen.dart';
import 'features/owner/presentation/screens/owner_home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SemaApp());
}

class SemaApp extends StatelessWidget {
  const SemaApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seedColor = Color(0xFF2457C5);

    return MaterialApp(
      title: 'SEMA Management',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: seedColor),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          border: OutlineInputBorder(),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      home: const AppStartupScreen(),
    );
  }
}

class AppStartupScreen extends StatelessWidget {
  const AppStartupScreen({super.key});

  Future<bool> _hasSession() async {
    final token = await TokenStorage.readToken();
    return token != null && token.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _hasSession(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return const LoginScreen();
        }

        if (snapshot.data == true) {
          return const OwnerHomeScreen();
        }

        return const LoginScreen();
      },
    );
  }
}
