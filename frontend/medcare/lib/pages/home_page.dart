// lib/pages/home_page.dart
import 'package:flutter/material.dart';
import '../services/api_services.dart';
import 'register_page.dart'; // Import RegisterPage
import 'login_page.dart';     // Import LoginPage

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String message = 'Waiting for response...';
  late ApiService apiService;

  @override
  void initState() {
    super.initState();
    apiService = ApiService(baseUrl: 'http://10.0.2.2:3000'); // Use 10.0.2.2 for Android Emulator
  }

  void navigateToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegisterPage()),
    );
  }

  void navigateToLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(message, style: const TextStyle(color: Colors.red)),
            ElevatedButton(
              onPressed: navigateToRegister,
              child: const Text('Register'),
            ),
            ElevatedButton(
              onPressed: navigateToLogin,
              child: const Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}
