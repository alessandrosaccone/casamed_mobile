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
    apiService = ApiService(
        baseUrl: 'http://10.0.2.2:3000'); // Use 10.0.2.2 for Android Emulator
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
      appBar: AppBar(title: const Text('Home')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildButton('Registrati', Colors.white54, navigateToRegister),
            const SizedBox(height: 16),
            _buildButton('Login', Colors.white54, navigateToLogin),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(String text, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        minimumSize: const Size(200, 50),
      ),
      child: Text(text, style: const TextStyle(color: Colors.black, fontSize: 18)),
    );
  }

}