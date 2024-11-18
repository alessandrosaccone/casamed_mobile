import 'package:flutter/material.dart';
import 'package:medcare/pages/save_booking.dart';
import '../services/api_services.dart';

class UrgentBookingPage extends StatefulWidget {
  final int userId;
  final String token;
  final bool isDoctor;

  const UrgentBookingPage({
    Key? key,
    required this.userId,
    required this.token,
    required this.isDoctor,
  }) : super(key: key);

  @override
  _UrgentBookingPageState createState() => _UrgentBookingPageState();
}

class _UrgentBookingPageState extends State<UrgentBookingPage> {
  late Future<List<Map<String, dynamic>>> _closestAvailability;

  @override
  void initState() {
    super.initState();
    _closestAvailability = _loadUrgentBooking();
  }

  // Funzione per ottenere la disponibilità urgente più vicina
  Future<List<Map<String, dynamic>>> _loadUrgentBooking() async {
    try {
      final response = await ApiService(baseUrl: 'http://10.0.2.2:3000')
          .getUrgentBooking(widget.userId, widget.token); // Chiamata al nuovo endpoint

      // Controlla che la risposta sia una lista di oggetti validi
      if (response.containsKey('urgentBookings')) {
        return List<Map<String, dynamic>>.from(response['urgentBookings']);
      } else {
        return []; // Nessun dato trovato
      }
    } catch (e) {
      throw Exception('Errore nel recuperare la disponibilità urgente: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("visitaMe il prima possibile"),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>( // FutureBuilder to handle async data
        future: _closestAvailability,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Errore: ${snapshot.error}'));
          }

          // Se non ci sono dati disponibili
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Nessuna disponibilità urgente trovata.'));
          }

          // Ottieni la disponibilità più vicina
          final closestAvailability = snapshot.data!.first;

          // Verifica che i campi essenziali siano presenti
          if (!closestAvailability.containsKey('available_date') ||
              !closestAvailability.containsKey('start_time') ||
              !closestAvailability.containsKey('end_time')) {
            return const Center(child: Text('Dati incompleti: nessuna disponibilità valida trovata.'));
          }

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ListTile(
                  title: const Text('Disponibilità più vicina:'),
                  subtitle: Text(
                    'Data: ${closestAvailability['available_date']}\n'
                        'Orario: ${closestAvailability['start_time']} - ${closestAvailability['end_time']}',
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SaveBookingPage(
                          doctorId: closestAvailability['id'], // Passa il doctorId
                          userId: widget.userId,
                          token: widget.token,
                          date: closestAvailability['available_date'],
                          startTime: closestAvailability['start_time'],
                          endTime: closestAvailability['end_time'],
                        ),
                      ),
                    );
                  },
                  child: const Text('Prenota Visita'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}