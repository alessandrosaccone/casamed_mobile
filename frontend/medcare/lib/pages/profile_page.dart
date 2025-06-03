import 'package:flutter/material.dart';
import 'selection_discovery_page.dart';
import '../services/api_services.dart';
import 'calendar_page.dart';
import 'viewBookings_page.dart';
import 'viewBookings_patient_page.dart';

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

class _ProfilePageState extends State<ProfilePage> with TickerProviderStateMixin {
  late ApiService apiService;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  Map<String, dynamic>? userProfile;
  String message = '';
  bool isDoctor = false;
  int userRole = 0; // 0 = paziente, 1 = infermiere, 2 = medico
  int _selectedIndex = 0;

  // Stati di espansione per le sezioni
  bool _isPersonalInfoExpanded = false;
  bool _isProfessionalInfoExpanded = false;

  @override
  void initState() {
    super.initState();
    apiService = ApiService(baseUrl: 'http://10.0.2.2:3000');

    // Inizializza le animazioni
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    fetchUserProfile();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> fetchUserProfile() async {
    String token = widget.token;
    int userId = widget.userId;

    if (token.isNotEmpty) {
      try {
        final profileData = await apiService.getUserProfile(userId, token);
        setState(() {
          userProfile = profileData;
          // Determina il ruolo dell'utente
          userRole = profileData['userData']['role'] ?? 0;
          isDoctor = userRole == 1 || userRole == 2; // infermiere o medico
        });

        // Avvia l'animazione quando i dati sono caricati
        _animationController.forward();

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

  String _getUserRoleText() {
    switch (userRole) {
      case 1:
        return 'Infermiere';
      case 2:
        return 'Medico';
      default:
        return 'Paziente';
    }
  }

  IconData _getUserRoleIcon() {
    switch (userRole) {
      case 1:
        return Icons.health_and_safety; // Infermiere
      case 2:
        return Icons.local_hospital; // Medico
      default:
        return Icons.person; // Paziente
    }
  }

  Widget _buildPage() {
    print("Selected Index: $_selectedIndex, isDoctor: $isDoctor");

    if (isDoctor) {
      // Navbar per medici: Profilo, Calendario, Prenotazioni
      switch (_selectedIndex) {
        case 0:
          return _buildProfile(); // Profilo
        case 1:
          return CalendarPageContent(
            userId: widget.userId,
            token: widget.token,
          ); // Calendario
        case 2:
          return ViewBookingsPageContent(
            token: widget.token,
          ); // Prenotazioni medico
        default:
          return _buildProfile();
      }
    } else {
      // Navbar per pazienti: Profilo, Discovery, Prenotazioni
      switch (_selectedIndex) {
        case 0:
          return _buildProfile(); // Profilo
        case 1:
          return SelectionDiscoveryPage(
            apiService: apiService,
            userId: widget.userId,
            token: widget.token,
            isDoctor: isDoctor,
          ); // Discovery
        case 2:
          return ViewBookingsPatientPage(
            userId: widget.userId,
            token: widget.token,
          ); // Prenotazioni paziente
        default:
          return _buildProfile();
      }
    }
  }

  Widget _buildProfile() {
    if (userProfile == null) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE3F2FD), // Azzurro chiaro
              Colors.white,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (message.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF1976D2)),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Color(0xFF1976D2),
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Errore nel caricamento',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1976D2),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        message,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF1976D2),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1976D2).withOpacity(0.2),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1976D2)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Caricamento profilo...',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFE3F2FD), // Azzurro chiaro
            Colors.white,
            Color(0xFFF3E5F5), // Azzurro molto chiaro
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // Header con avatar e nome
                  _buildProfileHeader(),

                  const SizedBox(height: 30),

                  // Sezione Informazioni Personali (espandibile solo per professionisti)
                  if (isDoctor) _buildExpandablePersonalInfoCard(),

                  // Per i pazienti mostra sempre le info personali
                  if (!isDoctor) _buildPersonalInfoCard(),

                  const SizedBox(height: 20),

                  // Informazioni professionali (espandibile, solo se presenti)
                  if (_hasProfessionalInfo() && isDoctor)
                    _buildExpandableProfessionalInfoCard(),

                  const SizedBox(height: 100), // Spazio per la bottom nav
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    final userData = userProfile!['userData'];
    final fullName = '${userData['first_name'] ?? 'Nome'} ${userData['last_name'] ?? 'Cognome'}';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1976D2), // Blu
            Color(0xFF42A5F5), // Azzurro
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1976D2).withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 3,
              ),
            ),
            child: Icon(
              _getUserRoleIcon(),
              size: 60,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 16),

          Text(
            fullName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _getUserRoleText(),
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandablePersonalInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isPersonalInfoExpanded = !_isPersonalInfoExpanded;
              });
            },
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: _isPersonalInfoExpanded ? Radius.zero : const Radius.circular(20),
                  bottomRight: _isPersonalInfoExpanded ? Radius.zero : const Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1976D2).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.person_outline,
                      color: Color(0xFF1976D2),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Informazioni Personali',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1976D2),
                      ),
                    ),
                  ),
                  Icon(
                    _isPersonalInfoExpanded ? Icons.expand_less : Icons.expand_more,
                    color: const Color(0xFF1976D2),
                  ),
                ],
              ),
            ),
          ),

          if (_isPersonalInfoExpanded)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: _buildPersonalInfoFields(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFFE3F2FD),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1976D2).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    color: Color(0xFF1976D2),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Informazioni Personali',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1976D2),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: _buildPersonalInfoFields(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableProfessionalInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isProfessionalInfoExpanded = !_isProfessionalInfoExpanded;
              });
            },
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: _isProfessionalInfoExpanded ? Radius.zero : const Radius.circular(20),
                  bottomRight: _isProfessionalInfoExpanded ? Radius.zero : const Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1976D2).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.work_outline,
                      color: Color(0xFF1976D2),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Informazioni Professionali',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1976D2),
                      ),
                    ),
                  ),
                  Icon(
                    _isProfessionalInfoExpanded ? Icons.expand_less : Icons.expand_more,
                    color: const Color(0xFF1976D2),
                  ),
                ],
              ),
            ),
          ),

          if (_isProfessionalInfoExpanded)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: _buildProfessionalFields(userProfile!['userData']),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildPersonalInfoFields() {
    final userData = userProfile!['userData'];
    List<Widget> fields = [];

    fields.add(_buildInfoTile(
      icon: Icons.email_outlined,
      label: 'Email',
      value: userData['email'] ?? 'Non disponibile',
    ));

    if (userData['address'] != null) {
      fields.add(_buildInfoTile(
        icon: Icons.location_on_outlined,
        label: 'Indirizzo',
        value: userData['address'],
      ));
    }

    return fields;
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD).withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF1976D2).withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF1976D2).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF1976D2),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _hasProfessionalInfo() {
    final userData = userProfile!['userData'];
    return userData['vat_number'] != null ||
        userData['professional_insurance_number'] != null ||
        userData['iban'] != null ||
        userData['professional_association_registration'] != null;
  }

  List<Widget> _buildProfessionalFields(Map<String, dynamic> userData) {
    List<Widget> fields = [];

    if (userData['vat_number'] != null) {
      fields.add(_buildInfoTile(
        icon: Icons.business,
        label: 'Partita IVA',
        value: userData['vat_number'],
      ));
    }

    if (userData['professional_insurance_number'] != null) {
      fields.add(_buildInfoTile(
        icon: Icons.security,
        label: 'Numero Assicurazione Professionale',
        value: userData['professional_insurance_number'],
      ));
    }

    if (userData['iban'] != null) {
      fields.add(_buildInfoTile(
        icon: Icons.account_balance,
        label: 'IBAN',
        value: userData['iban'],
      ));
    }

    if (userData['professional_association_registration'] != null) {
      fields.add(_buildInfoTile(
        icon: Icons.verified_user,
        label: 'Iscrizione Ordine Professionale',
        value: userData['professional_association_registration'],
      ));
    }

    return fields;
  }

  // Metodo per ottenere il titolo dell'AppBar in base alla scheda selezionata
  String _getAppBarTitle() {
    if (isDoctor) {
      switch (_selectedIndex) {
        case 0:
          return 'Il Mio Profilo';
        case 1:
          return 'Calendario';
        case 2:
          return 'Prenotazioni';
        default:
          return 'Profilo';
      }
    } else {
      switch (_selectedIndex) {
        case 0:
          return 'Il Mio Profilo';
        case 1:
          return 'Scopri i Medici';
        case 2:
          return 'Le Mie Prenotazioni';
        default:
          return 'Profilo';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          _getAppBarTitle(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _buildPage(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              blurRadius: 10,
              spreadRadius: 2,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF1976D2),
          unselectedItemColor: Colors.grey.shade500,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          items: isDoctor
              ? const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profilo',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today),
              label: 'Calendario',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.book_online),
              label: 'Prenotazioni',
            ),
          ]
              : const <BottomNavigationBarItem>[
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
              label: 'Prenotazioni',
            ),
          ],
          currentIndex: _selectedIndex,
          onTap: _onItemTapped, // Ora usa sempre _onItemTapped per tutti
        ),
      ),
    );
  }
}

// Widget wrapper per CalendarPage che rimuove Scaffold
class CalendarPageContent extends StatelessWidget {
  final int userId;
  final String token;

  const CalendarPageContent({
    Key? key,
    required this.userId,
    required this.token,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Usiamo CalendarPage ma con un wrapper che sostituisce Scaffold con Container
    return CalendarPageWrapper(
      child: CalendarPage(
        userId: userId,
        token: token,
      ),
    );
  }
}

// Widget wrapper per ViewBookingsPage che rimuove Scaffold
class ViewBookingsPageContent extends StatelessWidget {
  final String token;

  const ViewBookingsPageContent({
    Key? key,
    required this.token,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Usiamo ViewBookingsPage ma con un wrapper che sostituisce Scaffold con Container
    return ViewBookingsPageWrapper(
      child: ViewBookingsPage(token: token),
    );
  }
}

// Wrapper che sostituisce Scaffold con Container per CalendarPage
class CalendarPageWrapper extends StatelessWidget {
  final Widget child;

  const CalendarPageWrapper({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: child,
    );
  }
}

// Wrapper che sostituisce Scaffold con Container per ViewBookingsPage
class ViewBookingsPageWrapper extends StatelessWidget {
  final Widget child;

  const ViewBookingsPageWrapper({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: child,
    );
  }
}