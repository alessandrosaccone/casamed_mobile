import 'package:flutter/material.dart';
import '../services/api_services.dart'; // Usa i tuoi servizi API per le chiamate

class SpecializationsPage extends StatefulWidget {
  final int userId;
  final String token; // Assicurati di passare il token al costruttore

  const SpecializationsPage({
    Key? key,
    required this.userId,
    required this.token,
  }) : super(key: key);

  @override
  _SpecializationsPageState createState() => _SpecializationsPageState();
}

class _SpecializationsPageState extends State<SpecializationsPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _specializationsController = TextEditingController();
  late ApiService apiService;
  String message = '';
  List<String> specializationsList = []; // Per memorizzare le specializzazioni esistenti
  bool isLoading = false; // Aggiunto per gestire il caricamento

  @override
  void initState() {
    super.initState();
    apiService = ApiService(baseUrl: 'http://10.0.2.2:3000');
    _fetchExistingSpecializations(); // Carica le specializzazioni esistenti
  }

  Future<void> _fetchExistingSpecializations() async {
    setState(() {
      isLoading = true; // Inizia il caricamento
    });
    try {
      // Recupera le specializzazioni esistenti
      specializationsList = await apiService.getDoctorSpecializations(widget.userId, widget.token);
      setState(() {
        // Aggiorna lo stato per riflettere le specializzazioni esistenti
        _specializationsController.text = specializationsList.join(', '); // Popola il TextField
      });
    } catch (e) {
      // Usa SnackBar per mostrare errori all'utente
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Errore nel caricamento delle specializzazioni: $e')));
    } finally {
      setState(() {
        isLoading = false; // Termina il caricamento
      });
    }
  }

  Future<void> _submitSpecializations() async {
    if (_formKey.currentState!.validate()) {
      String specializationsText = _specializationsController.text;
      List<String> updatedSpecializationsList = specializationsText.split(',').map((s) => s.trim()).toList();

      setState(() {
        isLoading = true; // Inizia il caricamento
      });

      try {
        await apiService.updateDoctorSpecializations(widget.userId, updatedSpecializationsList, widget.token);
        setState(() {
          message = 'Specializzazioni aggiornate con successo!';
          // Aggiorna anche l'elenco delle specializzazioni esistenti
          specializationsList = updatedSpecializationsList; // Aggiorna l'elenco locale
        });
        // Mostra un messaggio di successo
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      } catch (e) {
        setState(() {
          message = 'Errore durante l\'aggiornamento delle specializzazioni: $e';
        });
        // Usa SnackBar per mostrare errori all'utente
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      } finally {
        setState(() {
          isLoading = false; // Termina il caricamento
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Modifica Specializzazioni')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Mostra le specializzazioni esistenti su più righe
            const Text(
              'Specializzazioni esistenti:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            // Usa una Column per mostrare ogni specializzazione su una nuova riga
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: specializationsList.map((specialization) => Text(
                specialization,
                style: const TextStyle(fontSize: 16),
              )).toList(),
            ),
            const SizedBox(height: 20),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _specializationsController,
                    decoration: const InputDecoration(
                      labelText: 'Modifica Specializzazioni (separate da virgole)',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Inserisci almeno una specializzazione';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: isLoading ? null : _submitSpecializations, // Disabilita il pulsante se in caricamento
                    child: isLoading
                        ? const CircularProgressIndicator() // Mostra il caricamento
                        : const Text('Salva'),
                  ),
                  const SizedBox(height: 20),
                  if (message.isNotEmpty) Text(message), // Mostra eventuali messaggi
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
