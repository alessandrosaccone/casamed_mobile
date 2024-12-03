import 'package:flutter/material.dart';
import 'selection_discovery_page.dart';
import '../services/api_services.dart';
import 'calendar_page.dart';
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
    switch (_selectedIndex) {
      case 0:
        return _buildProfile();
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
          ..._buildAdditionalFields(userProfile!['userData']),
          const SizedBox(height: 20),

          // Bottone per il calendario
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

          // Nuovo bottone per visualizzare la lista delle prenotazioni
          if (isDoctor)
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ViewBookingsPage(
                      userId: widget.userId,
                      token: widget.token,
                    ),
                  ),
                );
              },
              child: const Text('Visualizza la lista delle prenotazioni'),
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
          _selectedIndex == 0 ? 'Profilo' : (_selectedIndex == 1 ? 'Scopri i Medici' : 'Le tue prenotazioni'),
        ),
      ),
      body: _buildPage(),
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
          BottomNavigationBarItem(
            icon: Icon(Icons.book_online),
            label: 'Le tue prenotazioni',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      )
          : null,
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
      fields.add(Text(
          "Numero d'assicurazione professionale: ${userData['professional_insurance_number']}"));
    }

    if (userData['iban'] != null) {
      fields.add(Text('IBAN: ${userData['iban']}'));
    }

    if (userData['professional_association_registration'] != null) {
      fields.add(Text(
          "Identificativo dell'iscrizione all'ordine professionale: ${userData['professional_association_registration']}"));
    }

    return fields;
  }
}









/*import 'package:flutter/material.dart';
import 'selection_discovery_page.dart';
import '../services/api_services.dart';
import 'calendar_page.dart';
import 'viewBookings_page.dart'; // Modifica il nome del file

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
    switch (_selectedIndex) {
      case 0:
        return _buildProfile();
      case 1:
        return SelectionDiscoveryPage(
          apiService: apiService,
          userId: widget.userId,
          token: widget.token,
          isDoctor: isDoctor,
        );
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
          ..._buildAdditionalFields(userProfile!['userData']),
          const SizedBox(height: 20),

          // Bottone per il calendario
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

          // Nuovo bottone per visualizzare la lista delle prenotazioni
          if (isDoctor)
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ViewBookingsPage( // Cambiato da AcceptBookingsPage a ViewBookingsPage
                      userId: widget.userId,
                      token: widget.token,
                    ),
                  ),
                );
              },
              child: const Text('Visualizza la lista delle prenotazioni'),
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
          _selectedIndex == 0 ? 'Profilo' : 'Scopri i Medici',
        ),
      ),
      body: _buildPage(),
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
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      )
          : null,
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
      fields.add(Text(
          "Numero d'assicurazione professionale: ${userData['professional_insurance_number']}"));
    }

    if (userData['iban'] != null) {
      fields.add(Text('IBAN: ${userData['iban']}'));
    }

    if (userData['professional_association_registration'] != null) {
      fields.add(Text(
          "Identificativo dell'iscrizione all'ordine professionale: ${userData['professional_association_registration']}"));
    }

    return fields;
  }
}*/

