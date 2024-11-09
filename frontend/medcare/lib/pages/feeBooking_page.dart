import 'package:flutter/material.dart';

class FeeBookingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Prenotazione Urgente'),
      ),
      body: Center(
        child: Text(
          'Questa è la pagina per la prenotazione a pagamento.',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
