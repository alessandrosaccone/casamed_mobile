import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl;

  ApiService({required this.baseUrl});

  Future<Map<String, dynamic>> registerUser(
      Map<String, dynamic> userData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(userData),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
          'Failed to register user: ${response.statusCode} - ${response.body}');
    }
  }

  Future<Map<String, dynamic>> loginUser(Map<String, dynamic> loginData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(loginData),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
          'Failed to login user: ${response.statusCode} - ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getUserProfile(int userId, String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/profile/$userId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
          'Failed to fetch user profile: ${response.statusCode} - ${response
              .body}');
    }
  }

  // Metodo per verificare se l'utente è un medico
  Future<bool> isUserDoctor(int userId, String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/user/$userId/role'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['isDoctor'] ?? false;
    } else {
      throw Exception(
          'Failed to check user role: ${response.statusCode} - ${response
              .body}');
    }
  }

  Future<List<Map<String, dynamic>>> getDoctors(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/discovery'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['doctors']);
    } else {
      throw Exception(
          'Failed to fetch doctors: ${response.statusCode} - ${response.body}');
    }
  }

  Future<List<Map<String, dynamic>>> getDoctorAvailability(int userId,
      String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/calendar/$userId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['availability']);
    } else {
      throw Exception(
          'Failed to fetch availability: ${response.statusCode} - ${response
              .body}');
    }
  }

  Future<void> deleteAvailability(int userId, String token, String date,
      String startTime, String endTime) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/calendar/$userId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'date': date,
        'start_time': startTime,
        'end_time': endTime,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
          'Failed to delete availability: ${response.statusCode} - ${response
              .body}');
    }
  }

  // Funzione per inviare la richiesta di reset della password
  Future<Map<String, dynamic>> requestPasswordReset(String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/requestPasswordReset'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"email": email}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to send password reset request: ${response
          .statusCode} - ${response.body}');
    }
  }

  // Metodo per ottenere la disponibilità urgente
  Future<Map<String, dynamic>> getUrgentBooking(int doctorId,
      String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/urgentbookings'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load urgent booking');
    }
  }
  Future<Map<String, dynamic>> acceptBooking(int bookingId, String note,
      String token) async {
    final response = await http.put(
      Uri.parse('$baseUrl/bookings/accept/$bookingId'),
      // Endpoint conforme al backend
      headers: {
        'Authorization': 'Bearer $token',
        // Autenticazione tramite token
        'Content-Type': 'application/json',
        // Specifica il formato del corpo della richiesta
      },
      body: jsonEncode({
        'note': note, // Campo per la nota fornita dal medico
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(
          response.body); // Decodifica e ritorna la risposta in formato JSON
    } else {
      throw Exception(
          'Failed to accept booking: ${response.statusCode} - ${response
              .body}');
    }
  }
}



