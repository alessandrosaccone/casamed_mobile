import 'package:flutter/material.dart';
import 'selection_discovery_page.dart';
import '../services/api_services.dart';
import 'calendar_page.dart';
import 'viewBookings_page.dart';
import 'viewBookings_page.dart'; // Modifica il nome del file
import 'viewBookings_patient_page.dart'; // Importa la nuova pagina per il paziente


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
  int _selectedIndex = 0;

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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildPage() {
    print(
        "Selected Index: $_selectedIndex"); // Debug log to check if the index is updating
    switch (_selectedIndex) {
      case 0:
        return _buildProfile(); // Profile page
      case 1:
        return SelectionDiscoveryPage(
          apiService: apiService,
          userId: widget.userId,
          token: widget.token,
          isDoctor: isDoctor,
        );
      case 2:
        return ViewBookingsPatientPage( // Naviga alla nuova pagina
          userId: widget.userId,
          token: widget.token,
        );
      default:
        return _buildProfile(); // Default case, just in case
    }
  }

  Widget _buildProfile() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: userProfile == null
          ? Center(
        child: Text(
          message,
          style: TextStyle(fontSize: 18, color: Colors.red),
        ),
      )
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 5,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    'Profilo Utente',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: Text(
                      'Email: ${userProfile!['userData']['email']}',
                    ),
                  ),
                  ListTile(
                    title: Text(
                      'Nome: ${userProfile!['userData']['first_name'] ?? 'N/A'}',
                    ),
                  ),
                  ListTile(
                    title: Text(
                      'Cognome: ${userProfile!['userData']['last_name'] ?? 'N/A'}',
                    ),
                  ),
                  ..._buildAdditionalFields(userProfile!['userData']),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          if (isDoctor) ...[
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
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
              child: const Text(
                'Vai al Calendario',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ViewBookingsPage(
                      //userId: widget.userId,
                      token: widget.token,
                    ),
                  ),
                );
              },
              child: const Text(
                'Visualizza la lista delle prenotazioni',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedIndex == 0 ? 'Profilo' : (_selectedIndex == 1 ? 'Scopri i Medici' : 'Le tue prenotazioni'),
        ),
      ),
      body: _buildPage(),
      // Modify the bottom navigation bar display based on the `isDoctor` flag
      bottomNavigationBar: isDoctor
          ? null // Hide BottomNavigationBar if the user is a doctor
          : BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profilo',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_fix_high),
            label: 'Discovery',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book_online),
            label: 'Le tue prenotazioni',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }



  List<Widget> _buildAdditionalFields(Map<String, dynamic> userData) {
    List<Widget> fields = [];

    /*if (userData['birth_date'] != null) {
      fields.add(ListTile(
        title: Text('Data di nascita: ${userData['birth_date']}'),
      ));
    }*/

    if (userData['address'] != null) {
      fields.add(ListTile(
        title: Text('Indirizzo: ${userData['address']}'),
      ));
    }

    if (userData['vat_number'] != null) {
      fields.add(ListTile(
        title: Text('Partita IVA (VAT number): ${userData['vat_number']}'),
      ));
    }

    if (userData['professional_insurance_number'] != null) {
      fields.add(ListTile(
        title: Text("Numero d'assicurazione professionale: ${userData['professional_insurance_number']}"),
      ));
    }

    if (userData['iban'] != null) {
      fields.add(ListTile(
        title: Text('IBAN: ${userData['iban']}'),
      ));
    }

    if (userData['professional_association_registration'] != null) {
      fields.add(ListTile(
        title: Text("Identificativo dell'iscrizione all'ordine professionale: ${userData['professional_association_registration']}"),
      ));
    }

    return fields;
  }
}
