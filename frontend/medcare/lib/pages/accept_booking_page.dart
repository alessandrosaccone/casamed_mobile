import 'package:flutter/material.dart';
import '../services/api_services.dart';

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
    final ApiService apiService = ApiService(baseUrl: 'http://10.0.2.2:3000');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dettagli Prenotazione'),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE3F2FD),
              Colors.white,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade200,
                      blurRadius: 10,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.event_available,
                      size: 48,
                      color: const Color(0xFF1976D2),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Accetta Prenotazione',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1976D2),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ID Prenotazione: $bookingId',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: controller,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF1976D2)),
                        ),
                        labelText: "Inserisci l'orario (es. 10:00-11:00)",
                        labelStyle: const TextStyle(color: Color(0xFF1976D2)),
                        prefixIcon: const Icon(Icons.access_time, color: Color(0xFF1976D2)),
                      ),
                      maxLines: 1,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          String note = controller.text.trim();

                          if (note.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Per favore, inserisci un orario.'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          try {
                            // Show loading dialog
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => const Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1976D2)),
                                ),
                              ),
                            );

                            // API call
                            final response = await apiService.acceptBooking(bookingId, note, token);

                            // Close loading dialog
                            Navigator.pop(context);

                            // Show success message
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Prenotazione accettata: ${response['message']}'),
                                backgroundColor: Colors.green,
                              ),
                            );

                            // CAMBIATO: Usa Navigator.pop invece di pushReplacement
                            // Questo torna alla pagina precedente (ProfilePage con navbar)
                            Navigator.pop(context, true); // true indica che è stata accettata

                          } catch (e) {
                            // Close loading dialog
                            Navigator.pop(context);

                            // Show error message
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Errore: ${e.toString()}'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check),
                            SizedBox(width: 8),
                            Text(
                              'Accetta Prenotazione',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context); // Torna indietro
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade300,
                          foregroundColor: Colors.grey.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Annulla',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}