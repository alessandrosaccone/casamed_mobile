// selection_discovery_page.dart
import 'package:flutter/material.dart';
import '../services/api_services.dart';
import 'calendar_page.dart'; // Import della pagina del calendario
import 'discovery_page.dart'; // Import della pagina per la scoperta dei medici
import 'urgentBooking_page.dart'; // Import della pagina per prenotazione urgente
import 'feeBooking_page.dart'; // Import della pagina per prenotazione regolare

class SelectionDiscoveryPage extends StatelessWidget {
  final ApiService apiService;
  final int userId;
  final String token;
  final bool isDoctor;

  const SelectionDiscoveryPage({
    Key? key,
    required this.apiService,
    required this.userId,
    required this.token,
    required this.isDoctor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UrgentBookingPage(
                      doctorId: userId,
                      doctorName: 'Nome Medico', // Usa un valore fittizio o modifica in base alle necessità
                      token: token,
                      isDoctor: isDoctor,
                    ),
                  ),
                );
              },
              child: const Text('Prenotazione Urgente'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DiscoveryPage(
                      userId: userId,
                      apiService: apiService,
                      token: token,
                      isDoctor: isDoctor,
                    ),
                  ),
                );
              },
              child: const Text('Prenotazione Regolare'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FeeBookingPage(),
                  ),
                );
              },
              child: const Text('Prenotazione a Pagamento'),
            ),
          ],
        ),
      ),
    );
  }
}
