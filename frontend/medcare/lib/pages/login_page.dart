// lib/pages/login_page.dart
import 'package:flutter/material.dart';
import '../services/api_services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'profile_page.dart';
import 'request_password_reset_page.dart'; // Importa la pagina per richiedere il reset password

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String message = '';

  late ApiService apiService;

  @override
  void initState() {
    super.initState();
    apiService = ApiService(baseUrl: 'http://10.0.2.2:3000'); // Sostituisci con l'URL della tua API
  }

  void login() async {
    try {
      final response = await apiService.loginUser({
        "email": _emailController.text,
        "pass": _passwordController.text,
      });

      // Controlla se il login ha avuto successo
      if (response['success']) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', response['token']);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfilePage(
              userId: response['userId'],
              token: response['token'],
            ),
          ),
        );
      } else {
        setState(() {
          message = 'Login non andato a buon fine: ${response['message']}';
        });
      }
    } catch (e) {
      setState(() {
        message = 'Error: $e';
      });
    }
  }

  // Aggiungi una funzione per navigare alla pagina di richiesta reset password
  void navigateToPasswordResetRequest() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RequestPasswordResetPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            ElevatedButton(
              onPressed: login,
              child: const Text('Login'),
            ),
            Text(
              message,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: navigateToPasswordResetRequest,
              child: const Text('Password dimenticata?'),
            ),
          ],
        ),
      ),
    );
  }
}
