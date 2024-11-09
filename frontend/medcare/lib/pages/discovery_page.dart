import 'package:flutter/material.dart';
import '../services/api_services.dart'; // Assicurati di importare il tuo ApiService
import 'booking_page.dart'; // Import della nuova pagina BookingPage
import 'dart:convert'; // Per gestire le decodifiche

class DiscoveryPage extends StatefulWidget {
  final ApiService apiService;
  final int userId;
  final String token;
  final bool isDoctor;

  const DiscoveryPage({
    Key? key,
    required this.userId,
    required this.apiService,
    required this.token,
    required this.isDoctor,
  }) : super(key: key);

  @override
  _DiscoveryPageState createState() => _DiscoveryPageState();
}

class _DiscoveryPageState extends State<DiscoveryPage> {
  late Future<List<Map<String, dynamic>>> _doctors;

  @override
  void initState() {
    super.initState();
    // Recupera i medici quando la pagina viene inizializzata
    _doctors = widget.apiService.getDoctors(widget.token);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Discovery')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _doctors,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Errore nel caricamento: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Nessun dottore trovato.'));
          }

          // Se i dati sono stati recuperati correttamente, mostra una lista di schede
          final doctors = snapshot.data!;

          return ListView.builder(
            itemCount: doctors.length,
            itemBuilder: (context, index) {
              final doctor = doctors[index];
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  title: Text('${doctor['first_name']} ${doctor['last_name']}'),
                  subtitle: const Text('General Doctor'),
                  trailing: ElevatedButton(
                    onPressed: () {
                      final doctorId = doctor['id'];

                      if (doctorId != null) {
                        // Navigazione alla pagina di prenotazione con i dati del medico
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BookingPage(
                              userId: widget.userId,
                              isDoctor: widget.isDoctor, // Passa il parametro isDoctor
                              doctorId: doctorId, // Passa l'id del medico
                              doctorName: '${doctor['first_name']} ${doctor['last_name']}', // Passa il nome del medico
                              token: widget.token,
                            ),
                          ),
                        );
                      } else {
                        // Gestisci il caso in cui l'ID del medico sia nullo
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Errore: ID del medico non disponibile.'),
                          ),
                        );
                      }
                    },
                    child: const Text('Prenota una visita'),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
