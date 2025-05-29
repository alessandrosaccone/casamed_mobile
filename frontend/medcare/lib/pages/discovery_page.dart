import 'package:flutter/material.dart';
import '../services/api_services.dart';
import 'booking_page.dart';
import 'dart:convert';

enum FilterType {
  all,
  doctor,
  nurse,
}

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
  late Future<List<Map<String, dynamic>>> _professionals;
  FilterType _currentFilter = FilterType.all;

  @override
  void initState() {
    super.initState();
    // Recupera tutti i professionisti all'inizio
    _loadProfessionals();
  }

  void _loadProfessionals() {
    setState(() {
      switch (_currentFilter) {
        case FilterType.all:
          _professionals = widget.apiService.getDoctors(widget.token);
          break;
        case FilterType.doctor:
          _professionals = widget.apiService.getDoctorsOnly(widget.token);
          break;
        case FilterType.nurse:
          _professionals = widget.apiService.getNursesOnly(widget.token);
          break;
      }
    });
  }

  // Funzione per determinare il ruolo in base ai dati
  bool isProfessionalDoctor(Map<String, dynamic> professional) {
    // Se abbiamo già filtrato, usiamo il filtro corrente
    if (_currentFilter == FilterType.doctor) return true;
    if (_currentFilter == FilterType.nurse) return false;

    // Verifica se il campo 'role' esiste
    if (professional.containsKey('role')) {
      // Valore 2 = medico, valore 1 = infermiere
      return professional['role'] == 2;
    }

    // Se non c'è il campo role, fallback basato sul nome (solo per debug)
    final fullName = '${professional['first_name']} ${professional['last_name']}';
    print('WARNING: Role field missing for $fullName, using fallback logic');

    if (fullName == 'Sara Cavallini') {
      return true; // è un medico
    } else if (fullName == 'Riccardo Camellini') {
      return false; // è un infermiere
    }

    // Default fallback
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('visitaMe programmata'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Filtro per la selezione del tipo di professionista
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.shade300,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(
                    'Filtra per tipo:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildFilterChip(
                      label: 'Tutti',
                      icon: Icons.people,
                      filter: FilterType.all,
                      activeColor: Colors.blue,
                    ),
                    _buildFilterChip(
                      label: 'Medici',
                      icon: Icons.local_hospital,
                      filter: FilterType.doctor,
                      activeColor: Colors.indigo,
                    ),
                    _buildFilterChip(
                      label: 'Infermieri',
                      icon: Icons.health_and_safety,
                      filter: FilterType.nurse,
                      activeColor: Colors.teal,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Lista dei professionisti
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _professionals,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Errore nel caricamento: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _currentFilter == FilterType.doctor
                              ? Icons.local_hospital
                              : _currentFilter == FilterType.nurse
                              ? Icons.health_and_safety
                              : Icons.people,
                          size: 48,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _currentFilter == FilterType.all
                              ? 'Nessun professionista disponibile'
                              : _currentFilter == FilterType.doctor
                              ? 'Nessun medico disponibile'
                              : 'Nessun infermiere disponibile',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                // Se i dati sono stati recuperati correttamente, mostra una lista di schede
                final professionals = snapshot.data!;

                return ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: professionals.length,
                  itemBuilder: (context, index) {
                    final professional = professionals[index];

                    // Debug: stampa i dettagli di ogni professionista
                    final fullName = '${professional['first_name']} ${professional['last_name']}';
                    print('Professional: $fullName, role: ${professional['role']}');

                    // Determina il ruolo corretto
                    final bool isDoctor = isProfessionalDoctor(professional);
                    print('$fullName is ${isDoctor ? "doctor" : "nurse"}');

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12.0),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        leading: CircleAvatar(
                          backgroundColor: isDoctor ? Colors.indigo.shade100 : Colors.teal.shade100,
                          child: Icon(
                            isDoctor ? Icons.local_hospital : Icons.health_and_safety,
                            color: isDoctor ? Colors.indigo : Colors.teal,
                          ),
                        ),
                        title: Text(
                          fullName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Text(
                          isDoctor ? 'Medico' : 'Infermiere',
                          style: TextStyle(
                            color: isDoctor ? Colors.indigo : Colors.teal,
                          ),
                        ),
                        trailing: ElevatedButton(
                          onPressed: () {
                            final professionalId = professional['id'];

                            if (professionalId != null) {
                              // Navigazione alla pagina di prenotazione con i dati del professionista
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BookingPage(
                                    userId: widget.userId,
                                    isDoctor: widget.isDoctor,
                                    doctorId: professionalId,
                                    doctorName: fullName,
                                    token: widget.token,
                                  ),
                                ),
                              );
                            } else {
                              // Gestisci il caso in cui l'ID del professionista sia nullo
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Errore: ID del professionista non disponibile.'),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDoctor ? Colors.indigo : Colors.teal,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Prenota'),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required FilterType filter,
    required Color activeColor,
  }) {
    final isSelected = _currentFilter == filter;

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: isSelected ? Colors.white : Colors.grey.shade700,
          ),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _currentFilter = filter;
            _loadProfessionals();
          });
        }
      },
      backgroundColor: Colors.grey.shade200,
      selectedColor: activeColor,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.grey.shade800,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }
}


