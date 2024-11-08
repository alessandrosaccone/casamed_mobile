// profile_page.dart
import 'package:flutter/material.dart';
import 'selection_discovery_page.dart';
import '../services/api_services.dart';
import 'calendar_page.dart'; // Import della pagina del calendario


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
  bool isDoctor = false;
  int _selectedIndex = 0; // Variabile per gestire la pagina selezionata

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

  Future<void> checkIfUserIsDoctor(int userId, String token) async {
    try {
      isDoctor = await apiService.isUserDoctor(userId, token);
      setState(() {});
    } catch (e) {
      print('Failed to check if user is a doctor: $e');
    }
  }

  // Gestione della navigazione in base alla selezione della BottomNavigationBar
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Creiamo un metodo per selezionare quale pagina mostrare
  Widget _buildPage() {
    switch (_selectedIndex) {
      case 0:
        return _buildProfile(); // Mostra il profilo
      case 1:
        return SelectionDiscoveryPage(
          apiService: apiService,
          userId: widget.userId,
          token: widget.token,
          isDoctor: isDoctor,
        ); // Passa apiService e token a DiscoveryPage
    // Mostra la pagina "Prova"
      default:
        return _buildProfile();
    }
  }

  Widget _buildProfile() {
    return Center(
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

          if (isDoctor)
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CalendarPage(
                      userId: widget.userId,
                      token: widget.token,
                    ),
                  ),
                );
              },
              child: const Text('Vai al Calendario'),
            ),

          ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedIndex == 0 ? 'Profilo' : 'Scopri i Medici', // Cambia il titolo in base alla selezione
        ),
      ),
      body: _buildPage(), // Mostra la pagina corretta

      // Mostra la BottomNavigationBar solo se l'utente non è un medico
      bottomNavigationBar: !isDoctor
          ? BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profilo',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_fix_high),
            label: 'Discovery',
          ),
        ],
        currentIndex: _selectedIndex, // Pagina selezionata
        onTap: _onItemTapped, // Cambia pagina al tap
      )
          : null, // Se l'utente è un medico, la barra non viene mostrata
    );
  }

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
      fields.add(
          Text("Numero d'assicurazione professionale: ${userData['professional_insurance_number']}"));
    }

    if (userData['iban'] != null) {
      fields.add(Text('IBAN: ${userData['iban']}'));
    }

    if (userData['professional_association_registration'] != null) {
      fields.add(Text(
          "Identificativo dell'iscrizione all'ordine professionale: ${userData['professional_association_registration']}"));
    }

    return fields; // Returns the list of non-null widgets
  }
}





