import 'package:flutter/material.dart';

import '../services/token_storage.dart';
import 'login_screen.dart';
import 'owner_dashboard_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final TokenStorage _tokenStorage = TokenStorage();

  late final Future<String?> _savedToken;

  @override
  void initState() {
    super.initState();
    _savedToken = _tokenStorage.getToken();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _savedToken,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final token = snapshot.data;

        if (snapshot.hasError || token == null || token.trim().isEmpty) {
          return const LoginScreen();
        }

        return OwnerDashboardScreen(token: token);
      },
    );
  }
}
