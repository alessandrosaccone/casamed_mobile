import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/api_services.dart';
import 'accept_booking_page.dart';

class ViewBookingsPage extends StatefulWidget {
  final String token;

  const ViewBookingsPage({Key? key, required this.token}) : super(key: key);

  @override
  _ViewBookingsPageState createState() => _ViewBookingsPageState();
}

class _ViewBookingsPageState extends State<ViewBookingsPage> {
  late ApiService apiService;
  List<Map<String, dynamic>> bookings = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    apiService = ApiService(baseUrl: 'http://10.0.2.2:3000');
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });

      // Chiamata HTTP diretta invece di usare ApiService
      final url = Uri.parse('http://10.0.2.2:3000/doctor/bookings');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true) {
          setState(() {
            bookings = List<Map<String, dynamic>>.from(jsonResponse['bookings']);
            isLoading = false;
          });
        } else {
          throw Exception(jsonResponse['message'] ?? 'Errore nel recupero delle prenotazioni');
        }
      } else {
        throw Exception('Errore HTTP: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Errore nel caricamento delle prenotazioni: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _refreshBookings() async {
    await _fetchBookings();
  }

  Color _getStatusColor(bool? acceptedBooking) {
    if (acceptedBooking == null || acceptedBooking == false) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  String _getStatusText(bool? acceptedBooking) {
    if (acceptedBooking == null || acceptedBooking == false) {
      return 'In attesa';
    } else {
      return 'Accettata';
    }
  }

  IconData _getStatusIcon(bool? acceptedBooking) {
    if (acceptedBooking == null || acceptedBooking == false) {
      return Icons.pending;
    } else {
      return Icons.check_circle;
    }
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    final bool isAccepted = booking['acceptedBooking'] ?? false;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          // Header con stato
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getStatusColor(isAccepted).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getStatusIcon(isAccepted),
                  color: _getStatusColor(isAccepted),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _getStatusText(isAccepted),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(isAccepted),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1976D2).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'ID: ${booking['bookingId']}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF1976D2),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Contenuto della prenotazione
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Informazioni paziente
                _buildInfoRow(
                  Icons.person,
                  'Paziente',
                  '${booking['patientFirstName']} ${booking['patientLastName']}',
                ),

                if (booking['patientAddress'] != null)
                  _buildInfoRow(
                    Icons.location_on,
                    'Indirizzo',
                    booking['patientAddress'],
                  ),

                // Data e orario
                _buildInfoRow(
                  Icons.calendar_today,
                  'Data',
                  _formatDate(booking['bookingDate']),
                ),

                _buildInfoRow(
                  Icons.access_time,
                  'Orario',
                  '${booking['startTime']} - ${booking['endTime']}',
                ),

                // Sintomi
                _buildInfoRow(
                  Icons.description,
                  'Sintomi',
                  booking['symptomDescription'] ?? 'Non specificato',
                ),

                // Trattamento
                if (booking['treatment'] != null)
                  _buildInfoRow(
                    Icons.medical_information,
                    'Trattamento',
                    booking['treatment'],
                  ),

                const SizedBox(height: 16),

                // Bottone accetta (solo se non ancora accettata)
                if (!isAccepted)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        // Naviga alla pagina di accettazione e aspetta il risultato
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AcceptBookingPage(
                              bookingId: booking['bookingId'],
                              token: widget.token,
                            ),
                          ),
                        );

                        // Se la prenotazione è stata accettata, ricarica la lista
                        if (result == true) {
                          _refreshBookings();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check),
                          SizedBox(width: 8),
                          Text('Accetta Prenotazione'),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: const Color(0xFF1976D2),
          ),
          const SizedBox(width: 12),
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
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final months = [
        'Gennaio', 'Febbraio', 'Marzo', 'Aprile', 'Maggio', 'Giugno',
        'Luglio', 'Agosto', 'Settembre', 'Ottobre', 'Novembre', 'Dicembre'
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    // RIMOSSO Scaffold - ora ritorna direttamente il contenuto
    return RefreshIndicator(
      onRefresh: _refreshBookings,
      child: isLoading
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1976D2)),
            ),
            SizedBox(height: 16),
            Text(
              'Caricamento prenotazioni...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      )
          : errorMessage.isNotEmpty
          ? Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
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
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 48,
              ),
              const SizedBox(height: 16),
              const Text(
                'Errore',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                errorMessage,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _refreshBookings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1976D2),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Riprova'),
              ),
            ],
          ),
        ),
      )
          : bookings.isEmpty
          ? Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
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
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.event_note,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'Nessuna prenotazione',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Non hai ancora ricevuto prenotazioni dai pazienti.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.only(top: 20, bottom: 100),
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          return _buildBookingCard(bookings[index]);
        },
      ),
    );
  }
}