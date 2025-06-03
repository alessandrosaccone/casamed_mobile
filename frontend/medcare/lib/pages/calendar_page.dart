import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:http/http.dart' as http; // Importa il pacchetto http
import 'dart:convert'; // Import per la codifica in JSON
import '../services/api_services.dart';
import 'booking_page.dart'; // Importa la pagina BookingPage

class CalendarPage extends StatefulWidget {
  final int userId; // Aggiungi il parametro User ID
  final String token; // Aggiungi il parametro Token

  CalendarPage({required this.userId, required this.token});

  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  List<Map<String, dynamic>> _availability = [];
  CalendarFormat _calendarFormat = CalendarFormat.month;
  Map<DateTime, List<dynamic>> _events = {}; // Mappa per i giorni con eventi
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();

  // Variabili per memorizzare la selezione dell'orario
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  // Variabile per il numero massimo di pazienti
  int? _maxPatients;

  // Set per memorizzare i giorni selezionati
  Set<DateTime> _selectedDays = {};

  @override
  void initState() {
    super.initState();
    _fetchAvailability(); // Load existing availability on page load
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  Future<void> _fetchAvailability() async {
    try {
      final apiService = ApiService(baseUrl: 'http://10.0.2.2:3000');
      List<Map<String, dynamic>> availability =
      await apiService.getDoctorAvailability(widget.userId, widget.token);

      setState(() {
        _events.clear();
        for (var slot in availability) {
          DateTime date = _normalizeDate(DateTime.parse(slot['date']));

          if (_events.containsKey(date)) {
            _events[date]?.add(slot); // Aggiungi evento esistente
          } else {
            _events[date] = [slot]; // Crea nuovo giorno con eventi
          }
        }
      });
    } catch (e) {
      print('Error fetching availability: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch availability.')),
      );
    }
  }

  // Funzione per navigare alla pagina di gestione delle disponibilità
  void _navigateToBookingPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingPage(
          doctorId: widget.userId,
          doctorName: 'Not useful',
          isDoctor:  true,
          userId: widget.userId,
          token: widget.token,
        ),
      ),
    );
  }

  // Funzione per selezionare l'orario di inizio
  Future<void> _selectStartTime(BuildContext context) async {
    TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (selectedTime != null) {
      setState(() {
        _startTime = selectedTime;
      });
    }
  }

  // Funzione per selezionare l'orario di fine
  Future<void> _selectEndTime(BuildContext context) async {
    TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (selectedTime != null) {
      setState(() {
        _endTime = selectedTime;
      });
    }
  }

  // Funzione per costruire la parte dell'interfaccia che seleziona orari
  Widget _buildTimeSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            spreadRadius: 2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.access_time, color: Color(0xFF1976D2)),
              const SizedBox(width: 8),
              const Text(
                'Seleziona Orari',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1976D2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Orario di inizio
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Orario di inizio:', style: TextStyle(fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 4),
              InkWell(
                onTap: () => _selectStartTime(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _startTime == null
                              ? 'Seleziona orario di inizio'
                              : '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontSize: 16,
                            color: _startTime == null ? Colors.grey.shade600 : Colors.black87,
                          ),
                        ),
                      ),
                      const Icon(Icons.access_time, color: Color(0xFF1976D2), size: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Orario di fine
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Orario di fine:', style: TextStyle(fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 4),
              InkWell(
                onTap: () => _selectEndTime(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _endTime == null
                              ? 'Seleziona orario di fine'
                              : '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontSize: 16,
                            color: _endTime == null ? Colors.grey.shade600 : Colors.black87,
                          ),
                        ),
                      ),
                      const Icon(Icons.access_time, color: Color(0xFF1976D2), size: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Funzione per costruire la parte dell'interfaccia per inserire il numero massimo di pazienti
  Widget _buildMaxPatientsField() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            spreadRadius: 2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.group, color: Color(0xFF1976D2)),
              const SizedBox(width: 8),
              const Text(
                'Numero massimo di pazienti',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1976D2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Es. 5',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF1976D2)),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            onChanged: (value) {
              setState(() {
                _maxPatients = int.tryParse(value);
              });
            },
          ),
        ],
      ),
    );
  }

  // Funzione per salvare la disponibilità e inviarla al backend
  Future<void> _saveAvailability() async {
    if (_startTime == null || _endTime == null || _maxPatients == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seleziona un orario di inizio, fine e numero massimo di pazienti'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Converti i giorni selezionati e gli orari in una lista
    List<Map<String, dynamic>> availabilityData = _selectedDays.map((day) {
      return {
        'date': day.toIso8601String(),
        'start_time': '${_startTime!.hour}:${_startTime!.minute}',
        'end_time': '${_endTime!.hour}:${_endTime!.minute}',
        'max_patients': _maxPatients, // Aggiungi il numero massimo di pazienti
      };
    }).toList();

    // URL per inviare la richiesta (sostituisci con l'indirizzo del tuo backend)
    final url = Uri.parse('http://10.0.2.2:3000/calendar/${widget.userId}');

    try {
      // Invio della richiesta POST per salvare la disponibilità
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}', // Token per l'autenticazione
        },
        body: jsonEncode({'availability': availabilityData}), // Dati in formato JSON
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Disponibilità salvata con successo!'),
            backgroundColor: Colors.green,
          ),
        );

        // Dopo aver salvato, ricarica la disponibilità aggiornata
        _fetchAvailability(); // Ricarica la disponibilità aggiornata

        // Reset dei campi
        setState(() {
          _selectedDays.clear();
          _startTime = null;
          _endTime = null;
          _maxPatients = null;
        });

      } else {
        // Analizza il corpo della risposta per errori specifici
        final responseBody = jsonDecode(response.body);
        String errorMessage;

        if (responseBody.containsKey('message')) {
          errorMessage = responseBody['message'];
        } else if (responseBody.containsKey('errors')) {
          // Se ci sono errori di validazione, mostralo
          List<dynamic> errors = responseBody['errors'];
          errorMessage = errors.map((e) => e['msg']).join(', ');
        } else {
          errorMessage = 'Errore durante il salvataggio.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Errore nella richiesta: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Si è verificato un errore di rete.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // RIMOSSO Scaffold - ora ritorna direttamente il contenuto
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Calendario
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 8,
                    spreadRadius: 2,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TableCalendar(
                firstDay: DateTime.utc(2020, 10, 16),
                lastDay: DateTime.utc(2030, 10, 16),
                focusedDay: _focusedDay,
                eventLoader: (day) {
                  return _events[_normalizeDate(day)] ?? [];
                },
                selectedDayPredicate: (day) => _selectedDays.contains(day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                    _selectedDays.contains(selectedDay) ? _selectedDays.remove(selectedDay) : _selectedDays.add(selectedDay);
                  });
                },
                calendarFormat: _calendarFormat,
                onFormatChanged: (format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                },
                calendarStyle: CalendarStyle(
                  outsideDaysVisible: false,
                  selectedDecoration: BoxDecoration(
                    color: const Color(0xFF1976D2),
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: const Color(0xFF1976D2).withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: true,
                  titleCentered: true,
                  formatButtonShowsNext: false,
                  formatButtonDecoration: BoxDecoration(
                    color: Color(0xFF1976D2),
                    borderRadius: BorderRadius.all(Radius.circular(12.0)),
                  ),
                  formatButtonTextStyle: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            _buildTimeSelector(),
            _buildMaxPatientsField(),

            const SizedBox(height: 20),

            // Bottoni
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveAvailability,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1976D2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.save),
                        SizedBox(width: 8),
                        Text('Salva Disponibilità'),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _navigateToBookingPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.delete),
                        SizedBox(width: 8),
                        Text('Vai alla pagina per cancellare le disponibilità'),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 100), // Spazio per la bottom nav
          ],
        ),
      ),
    );
  }
}