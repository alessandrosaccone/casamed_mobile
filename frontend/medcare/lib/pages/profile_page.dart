import 'package:flutter/material.dart';
import '../services/api_services.dart';
import 'calendar_page.dart'; // Import della pagina del calendario
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  final int userId;
  final String token;

  const ProfilePage({
    Key? key,
    required this.userId,
    required this.token,
  }) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late ApiService apiService;
  Map<String, dynamic>? userProfile;
  String message = '';
  bool isDoctor = false; // Variabile per determinare se l'utente è un medico

  @override
  void initState() {
    super.initState();
    apiService = ApiService(baseUrl: 'http://10.0.2.2:3000');
    fetchUserProfile();
  }

  Future<void> fetchUserProfile() async {
    String token = widget.token;
    int userId = widget.userId;

    if (token.isNotEmpty) {
      try {
        final profileData = await apiService.getUserProfile(userId, token);
        setState(() {
          userProfile = profileData;
        });

        // Controlla se l'utente è un medico in un contesto separato
        await checkIfUserIsDoctor(profileData['userData']['id'], token);

      } catch (e) {
        setState(() {
          message = 'Failed to load user profile: $e';
        });
      }
    } else {
      setState(() {
        message = 'No token found, please login again.';
      });
    }
  }

  // Funzione per controllare se l'utente è un medico
  Future<void> checkIfUserIsDoctor(int userId, String token) async {
    try {
      isDoctor = await apiService.isUserDoctor(userId, token);
      setState(() {}); // Notifica Flutter che lo stato è cambiato
    } catch (e) {
      print('Failed to check if user is a doctor: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profilo')),
      body: Center(
        child: userProfile == null
            ? Text(message)
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('User ID: ${userProfile!['userData']['id']}'),
            Text('Email: ${userProfile!['userData']['email']}'),
            Text('Nome: ${userProfile!['userData']['first_name'] ?? 'N/A'}'),
            Text('Cognome: ${userProfile!['userData']['last_name'] ?? 'N/A'}'),

            // Visualizza i dati aggiuntivi se non sono nulli
            ..._buildAdditionalFields(userProfile!['userData']),

            const SizedBox(height: 20), // Spazio tra i contenuti

            // Controlla se l'utente è un medico (ruolo 1) prima di mostrare il bottone
            if (isDoctor) // Verifica se l'utente è un medico
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CalendarPage(
                        userId: widget.userId,   // Pass the userId here
                        token: widget.token,
                      ),
                    ),
                  );
                },
                child: Text('Vai al Calendario'),
              ),
          ],
        ),
      ),
    );
  }

  // Helper method to build additional fields if they are not null
  List<Widget> _buildAdditionalFields(Map<String, dynamic> userData) {
    List<Widget> fields = [];

    if (userData['birth_date'] != null) {
      fields.add(Text('Data di nascita: ${userData['birth_date']}'));
    }

    if (userData['address'] != null) {
      fields.add(Text('Indirizzo: ${userData['address']}'));
    }

    if (userData['vat_number'] != null) {
      fields.add(Text('Partita IVA (VAT numer): ${userData['vat_number']}'));
    }

    if (userData['professional_insurance_number'] != null) {
      fields.add(Text("Numero d'assicurazione professionale: ${userData['professional_insurance_number']}"));
    }

    if (userData['iban'] != null) {
      fields.add(Text('IBAN: ${userData['iban']}'));
    }

    if (userData['professional_association_registration'] != null) {
      fields.add(Text("Identificativo dell'iscrizione all'ordine professionale: ${userData['professional_association_registration']}"));
    }

    return fields; // Returns the list of non-null widgets
  }
}
