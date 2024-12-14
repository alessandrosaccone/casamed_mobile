import 'package:flutter/material.dart';
import '../services/api_services.dart'; // Assicurati di avere il percorso corretto del servizio API
import 'viewBookings_page.dart';

class AcceptBookingPage extends StatelessWidget {
  final int bookingId;
  final String token;

  const AcceptBookingPage({
    Key? key,
    required this.bookingId,
    required this.token,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    TextEditingController controller = TextEditingController();
    final ApiService apiService = ApiService(baseUrl: 'http://10.0.2.2:3000'); // Cambia con la tua baseUrl

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dettagli Prenotazione'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Dettagli per la prenotazione ID: $bookingId',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Inserisci l'orario (es. 10:00-11:00)",
              ),
              maxLines: 1,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                String note = controller.text.trim();

                if (note.isEmpty) {
                  // Show an error message if the field is empty
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Per favore, inserisci un orario.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                try {
                  // Show a loading indicator
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                  );

                  // API call
                  final response = await apiService.acceptBooking(bookingId, note, token);

                  // Close the loading dialog
                  Navigator.pop(context);

                  // Show a success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Prenotazione accettata: ${response['message']}'),
                      backgroundColor: Colors.green,
                    ),
                  );

                  // Navigate to the ViewBookingsPage
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ViewBookingsPage(
                          token: token),
                    ),
                  );
                } catch (e) {
                  // Close the loading dialog
                  Navigator.pop(context);

                  // Show an error message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Errore: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Accetta Prenotazione'),
            ),

            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Torna indietro
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
              ),
              child: const Text('Annulla'),
            ),
          ],
        ),
      ),
    );
  }
}
