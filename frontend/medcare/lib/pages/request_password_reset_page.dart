import 'package:flutter/material.dart';
import '../services/api_services.dart';

class RequestPasswordResetPage extends StatefulWidget {
  const RequestPasswordResetPage({super.key});

  @override
  State<RequestPasswordResetPage> createState() => _RequestPasswordResetPageState();
}

class _RequestPasswordResetPageState extends State<RequestPasswordResetPage> {
  final _emailController = TextEditingController();
  String message = '';
  late ApiService apiService;

  @override
  void initState() {
    super.initState();
    apiService = ApiService(baseUrl: 'http://10.0.2.2:3000');
  }

  void requestPasswordReset() async {
    try {
      // Invia la richiesta di reset della password con la mail
      final response = await apiService.requestPasswordReset(_emailController.text);

      if (response['success'] == true) {
        setState(() {
          message = 'Email per il reset inviata con successo. Controlla la tua posta.';
        });
      } else {
        setState(() {
          message = 'Errore: ${response['message']}';
        });
      }
    } catch (e) {
      setState(() {
        message = 'Errore: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Inserisci la tua email'),
            ),
            ElevatedButton(
              onPressed: requestPasswordReset,
              child: const Text('Invia richiesta di reset'),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              style: TextStyle(color: message.startsWith('Errore') ? Colors.red : Colors.green),
            ),
          ],
        ),
      ),
    );
  }
}


